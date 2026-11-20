import 'dart:typed_data';

/// A file to send in a multipart request (CV upload, company logo).
class UploadFile {
  const UploadFile({
    required this.fieldName,
    required this.fileName,
    this.bytes,
    this.path,
    this.contentType,
  });

  final String fieldName;
  final String fileName;
  final Uint8List? bytes;
  final String? path;

  /// e.g. `application/pdf`.
  final String? contentType;
}

/// A successful SharkHire response with its envelope kept: the backend's
/// `message`, the `data`, and `remaining_attempts` when the backend sends
/// it. Used where the message itself matters (e.g. "verification email
/// sent") and `data` is empty.
class ApiEnvelope {
  const ApiEnvelope({this.message, this.data, this.remainingAttempts});

  final String? message;
  final Object? data;
  final int? remainingAttempts;
}

/// Contract for talking to the SharkHire FastAPI backend.
///
/// Feature repositories depend on this interface only. The real
/// implementation is [HttpApiClient] (`http_api_client.dart`); it adds the
/// base URL, `Authorization: Bearer <Supabase access token>`, JSON
/// encoding, timeouts and maps HTTP errors to `ApiException`s.
///
/// Security (guide §3.4): the app never holds the JSearch key or the
/// Supabase service-role key – only the signed-in user's access token.
abstract interface class ApiClient {
  /// Returns the decoded JSON body (a `Map`, a `List`, or null when empty).
  Future<Object?> get(String path, {Map<String, Object?>? query});

  Future<Object?> post(String path, {Object? body});

  /// Like [post], but returns the whole success envelope.
  Future<ApiEnvelope> postEnvelope(String path, {Object? body});

  Future<Object?> put(String path, {Object? body});

  Future<Object?> patch(String path, {Object? body});

  Future<Object?> delete(String path);

  /// Multipart upload (e.g. `POST /api/v1/resumes/upload`).
  Future<Object?> upload(
    String path,
    UploadFile file, {
    Map<String, String> fields = const {},
  });
}
