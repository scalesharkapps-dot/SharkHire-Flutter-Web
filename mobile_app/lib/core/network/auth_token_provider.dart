import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import 'api_config.dart';
import 'api_endpoints.dart';

/// Tokens returned by `POST /api/v1/auth/login`, `/signup` and `/refresh`
/// (Supabase session issued by the SharkHire backend).
class SessionTokens {
  const SessionTokens({
    required this.accessToken,
    this.refreshToken,
    this.expiresAt,
  });

  final String accessToken;
  final String? refreshToken;

  /// When [accessToken] expires (from `expires_at`, seconds since epoch).
  final DateTime? expiresAt;

  /// Parses the backend's `SessionOut`.
  factory SessionTokens.fromSessionJson(Map<String, Object?> j) {
    final at = (j['expires_at'] as num?)?.toInt();
    final inSec = (j['expires_in'] as num?)?.toInt();
    return SessionTokens(
      accessToken: j['access_token'] as String,
      refreshToken: j['refresh_token'] as String?,
      expiresAt: at != null
          ? DateTime.fromMillisecondsSinceEpoch(at * 1000, isUtc: true)
          : inSec != null
          ? DateTime.now().toUtc().add(Duration(seconds: inSec))
          : null,
    );
  }

  bool expiresSoon([Duration margin = const Duration(seconds: 60)]) =>
      expiresAt != null &&
      DateTime.now().toUtc().isAfter(expiresAt!.subtract(margin));

  Map<String, Object?> toJson() => {
    'access_token': accessToken,
    'refresh_token': refreshToken,
    'expires_at': expiresAt == null
        ? null
        : expiresAt!.millisecondsSinceEpoch ~/ 1000,
  };
}

/// Where tokens are kept between app launches.
abstract interface class TokenStore {
  Future<SessionTokens?> read();
  Future<void> write(SessionTokens tokens);
  Future<void> clear();
}

/// Keychain (iOS), Android Keystore-encrypted storage (Android) or the
/// browser's encrypted storage (web). Tokens are never logged.
class SecureTokenStore implements TokenStore {
  SecureTokenStore([FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage();

  static const _key = 'sharkhire.session';
  final FlutterSecureStorage _storage;

  @override
  Future<SessionTokens?> read() async {
    try {
      final raw = await _storage.read(key: _key);
      if (raw == null) return null;
      return SessionTokens.fromSessionJson(
        jsonDecode(raw) as Map<String, Object?>,
      );
    } catch (_) {
      // Corrupt or unreadable storage: behave as signed out.
      return null;
    }
  }

  @override
  Future<void> write(SessionTokens tokens) =>
      _storage.write(key: _key, value: jsonEncode(tokens.toJson()));

  @override
  Future<void> clear() => _storage.delete(key: _key);
}

/// For tests and mock mode.
class MemoryTokenStore implements TokenStore {
  SessionTokens? _tokens;

  @override
  Future<SessionTokens?> read() async => _tokens;

  @override
  Future<void> write(SessionTokens tokens) async => _tokens = tokens;

  @override
  Future<void> clear() async => _tokens = null;
}

/// Supplies the signed-in user's access token for API requests and renews it
/// with the refresh token when it expires.
abstract interface class AuthTokenProvider {
  Future<String?> accessToken();

  /// Renews the access token. Returns false when the user must sign in again.
  Future<bool> refresh();
}

class NoTokenProvider implements AuthTokenProvider {
  const NoTokenProvider();

  @override
  Future<String?> accessToken() async => null;

  @override
  Future<bool> refresh() async => false;
}

/// One fixed token for a single request, e.g. the access token from a
/// password-recovery link. Never refreshed, never stored.
class FixedTokenProvider implements AuthTokenProvider {
  const FixedTokenProvider(this._token);
  final String _token;

  @override
  Future<String?> accessToken() async => _token;

  @override
  Future<bool> refresh() async => false;
}

/// Real token handling for the SharkHire API.
class SessionTokenManager implements AuthTokenProvider {
  SessionTokenManager({
    required this.store,
    required this.baseUrl,
    http.Client? client,
  }) : _http = client ?? http.Client();

  final TokenStore store;
  final String baseUrl;
  final http.Client _http;

  SessionTokens? _tokens;
  bool _loaded = false;
  Future<bool>? _refreshing;

  Future<SessionTokens?> current() async {
    if (!_loaded) {
      _tokens = await store.read();
      _loaded = true;
    }
    return _tokens;
  }

  /// "Remember me": keep the session on the device between app launches.
  /// When false, tokens live only in memory and the user signs in again
  /// after closing the app.
  bool persist = true;

  Future<void> save(SessionTokens tokens) async {
    _tokens = tokens;
    _loaded = true;
    if (persist) {
      await store.write(tokens);
    } else {
      await store.clear();
    }
  }

  Future<void> clear() async {
    _tokens = null;
    _loaded = true;
    await store.clear();
  }

  @override
  Future<String?> accessToken() async {
    final t = await current();
    if (t == null) return null;
    if (t.expiresSoon() && t.refreshToken != null) {
      await refresh();
      return _tokens?.accessToken;
    }
    return t.accessToken;
  }

  /// One refresh at a time, even if several requests hit 401 together.
  @override
  Future<bool> refresh() =>
      _refreshing ??= _doRefresh().whenComplete(() => _refreshing = null);

  Future<bool> _doRefresh() async {
    final refreshToken = (await current())?.refreshToken;
    if (refreshToken == null) return false;
    try {
      final res = await _http
          .post(
            Uri.parse('$baseUrl${ApiEndpoints.authRefresh}'),
            headers: const {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({'refresh_token': refreshToken}),
          )
          .timeout(ApiConfig.receiveTimeout);
      if (res.statusCode < 200 || res.statusCode >= 300) {
        // 4xx: the refresh token is no longer valid.
        if (res.statusCode < 500) await clear();
        return false;
      }
      final body = jsonDecode(res.body) as Map<String, Object?>;
      final data = (body['data'] ?? body) as Map<String, Object?>;
      await save(SessionTokens.fromSessionJson(data));
      return true;
    } catch (_) {
      // Offline or timeout: keep the tokens and let the caller report it.
      return false;
    }
  }
}

final tokenStoreProvider = Provider<TokenStore>((ref) => SecureTokenStore());

final sessionTokenManagerProvider = Provider<SessionTokenManager>(
  (ref) => SessionTokenManager(
    store: ref.watch(tokenStoreProvider),
    baseUrl: ApiConfig.baseUrl,
  ),
);

final authTokenProvider = Provider<AuthTokenProvider>(
  (ref) => ApiConfig.isConfigured
      ? ref.watch(sessionTokenManagerProvider)
      : const NoTokenProvider(),
);
