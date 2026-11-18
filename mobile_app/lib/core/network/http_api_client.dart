import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart' show MediaType;

import 'api_client.dart';
import 'api_config.dart';
import 'api_exception.dart';
import 'auth_token_provider.dart';
import 'session_expiry.dart';

/// Real [ApiClient] over HTTPS using `package:http` (Android, iOS and web).
///
/// * Adds `Authorization: Bearer <access token>` when signed in.
/// * Unwraps the SharkHire envelope `{success, message, data, error}` and
///   returns `data`.
/// * Maps errors to typed [ApiException]s with the backend's message.
/// * On 401 for a signed-in request, refreshes the token once and retries;
///   if that fails, reports [onUnauthorized] so the app signs out.
class HttpApiClient implements ApiClient {
  HttpApiClient({
    required this.baseUrl,
    required AuthTokenProvider tokens,
    http.Client? client,
    this.onUnauthorized,
  }) : _tokens = tokens,
       _http = client ?? http.Client();

  final String baseUrl;
  final AuthTokenProvider _tokens;
  final http.Client _http;

  /// Called when a signed-in request is rejected and the session can't be
  /// renewed, so the app can sign the user out.
  final void Function()? onUnauthorized;

  Uri _uri(String path, [Map<String, Object?>? query]) {
    final q = <String, Object>{};
    for (final e in (query ?? const <String, Object?>{}).entries) {
      final v = e.value;
      if (v == null) continue;
      // Lists become repeated parameters: ?a=1&a=2
      q[e.key] = v is Iterable ? [for (final x in v) '$x'] : '$v';
    }
    return Uri.parse(
      '$baseUrl$path',
    ).replace(queryParameters: q.isEmpty ? null : q);
  }

  Map<String, String> _headers(String? token, {bool json = true}) => {
    'Accept': 'application/json',
    if (json) 'Content-Type': 'application/json',
    if (token != null) ApiConfig.authHeader: ApiConfig.bearer(token),
  };

  Future<Object?> _send(
    Future<http.Response> Function(String? token) request, {
    Duration timeout = ApiConfig.receiveTimeout,
  }) async {
    var token = await _tokens.accessToken();
    var res = await _guard(() => request(token), timeout);
    if (res.statusCode == 401 && token != null) {
      // Expired access token: renew once and retry.
      if (await _tokens.refresh()) {
        token = await _tokens.accessToken();
        res = await _guard(() => request(token), timeout);
      }
      if (res.statusCode == 401) onUnauthorized?.call();
    }
    return decodeResponse(res.statusCode, res.body, res.headers);
  }

  Future<http.Response> _guard(
    Future<http.Response> Function() call,
    Duration timeout,
  ) async {
    try {
      return await call().timeout(timeout);
    } on TimeoutException {
      throw const RequestTimeoutException();
    } on http.ClientException {
      // package:http reports socket/DNS/TLS failures (and browser network
      // errors on web) as ClientException.
      throw const NetworkException();
    }
  }

  /// Maps an HTTP response to the envelope's `data` or a typed
  /// [ApiException]. Public for unit tests.
  static Object? decodeResponse(
    int status,
    String body,
    Map<String, String> headers,
  ) {
    Object? json;
    if (body.isNotEmpty) {
      try {
        json = jsonDecode(body);
      } on FormatException {
        json = null;
      }
    }
    if (status >= 200 && status < 300) {
      if (json is Map &&
          json.containsKey('success') &&
          json.containsKey('data')) {
        return json['data'];
      }
      return json;
    }

    // SharkHire envelope: {"message": ..., "error": {"code", "message", "details"}}
    final error = json is Map ? json['error'] : null;
    final code = error is Map ? error['code'] as String? : null;
    String? message;
    if (error is Map && error['message'] is String) {
      message = error['message'] as String;
    } else if (json is Map && json['message'] is String) {
      message = json['message'] as String;
    } else if (json is Map && json['detail'] is String) {
      message = json['detail'] as String;
    }

    final fields = <String, String>{};
    final details = error is Map
        ? error['details']
        : (json is Map ? json['detail'] : null);
    if (details is List) {
      for (final e in details) {
        if (e is! Map) continue;
        final field =
            e['field'] ??
            (e['loc'] is List && (e['loc'] as List).isNotEmpty
                ? (e['loc'] as List).last
                : null);
        if (field != null) {
          fields['$field'] = '${e['message'] ?? e['msg'] ?? 'Invalid value'}';
        }
      }
    }

    switch (status) {
      case 400:
      case 409:
      case 422:
        throw ValidationException(
          message ?? 'Please check the highlighted details.',
          fieldErrors: fields,
          code: code,
        );
      case 401:
        throw message == null
            ? const UnauthorizedException()
            : UnauthorizedException(message, code);
      case 403:
        throw message == null
            ? const ForbiddenException()
            : ForbiddenException(message, code);
      case 404:
        throw message == null
            ? const NotFoundException()
            : NotFoundException(message, code);
      case 429:
        final seconds = int.tryParse(headers['retry-after'] ?? '');
        throw RateLimitedException(
          retryAfter: seconds == null ? null : Duration(seconds: seconds),
          code: code,
        );
      case 503:
        throw ServerException(switch (code) {
          'storage_not_configured' =>
            "File uploads aren't available right now because the server's "
                "file storage isn't set up. Please try again later.",
          _ =>
            'SharkHire is temporarily unavailable. Please try again in a '
                'few minutes.',
        }, code);
      default:
        // Server errors keep our friendly wording; the code helps support.
        throw ServerException(
          'Something went wrong on our side. Please try again.',
          code,
        );
    }
  }

  @override
  Future<Object?> get(String path, {Map<String, Object?>? query}) =>
      _send((t) => _http.get(_uri(path, query), headers: _headers(t)));

  @override
  Future<Object?> post(String path, {Object? body}) => _send(
    (t) => _http.post(
      _uri(path),
      headers: _headers(t),
      body: body == null ? null : jsonEncode(body),
    ),
  );

  @override
  Future<Object?> put(String path, {Object? body}) => _send(
    (t) => _http.put(
      _uri(path),
      headers: _headers(t),
      body: body == null ? null : jsonEncode(body),
    ),
  );

  @override
  Future<Object?> patch(String path, {Object? body}) => _send(
    (t) => _http.patch(
      _uri(path),
      headers: _headers(t),
      body: body == null ? null : jsonEncode(body),
    ),
  );

  @override
  Future<Object?> delete(String path) =>
      _send((t) => _http.delete(_uri(path), headers: _headers(t)));

  @override
  Future<Object?> upload(
    String path,
    UploadFile file, {
    Map<String, String> fields = const {},
  }) async {
    if (file.bytes == null && file.path == null) {
      throw const ValidationException('No file was selected.');
    }
    // The backend checks the MIME type (PDF/DOCX), so send it explicitly
    // instead of the default application/octet-stream.
    final type = file.contentType == null
        ? null
        : MediaType.parse(file.contentType!);
    // A multipart request can only be sent once, so build it per attempt.
    Future<http.Response> send(String? token) async {
      final req = http.MultipartRequest('POST', _uri(path))
        ..headers.addAll(_headers(token, json: false))
        ..fields.addAll(fields);
      req.files.add(
        file.bytes != null
            ? http.MultipartFile.fromBytes(
                file.fieldName,
                file.bytes!,
                filename: file.fileName,
                contentType: type,
              )
            : await http.MultipartFile.fromPath(
                file.fieldName,
                file.path!,
                filename: file.fileName,
                contentType: type,
              ),
      );
      return http.Response.fromStream(await _http.send(req));
    }

    return _send(send, timeout: ApiConfig.uploadTimeout);
  }
}

/// The app's API client. Repositories only use it when
/// [ApiConfig.isConfigured] is true; otherwise their mock versions are used.
final apiClientProvider = Provider<ApiClient>(
  (ref) => HttpApiClient(
    baseUrl: ApiConfig.baseUrl,
    tokens: ref.watch(authTokenProvider),
    onUnauthorized: () => ref.read(sessionExpiryProvider.notifier).expired(),
  ),
);
