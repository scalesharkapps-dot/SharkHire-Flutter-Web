import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/api_config.dart';
import '../../../../core/network/auth_token_provider.dart';
import '../../../../core/network/http_api_client.dart';
import '../../../../shared/models/app_user.dart';
import '../../../../shared/models/backend_json.dart';
import '../../../../shared/models/domain_enums.dart';
import '../../domain/auth_link.dart';
import '../../domain/session.dart';
import 'auth_repository.dart';

/// REAL – sign-in through the SharkHire API, which issues Supabase sessions
/// (`/api/v1/auth/*`). Tokens are kept by [SessionTokenManager] in secure
/// storage; passwords are never stored.
class ApiAuthRepository implements AuthRepository {
  ApiAuthRepository(
    this._api,
    this._tokens, {
    ApiClient Function(String? bearer)? clientWithToken,
  }) : _clientWithToken = clientWithToken ?? _defaultClientWithToken;

  final ApiClient _api;
  final SessionTokenManager _tokens;

  /// A client that sends one given token (the recovery link's), or none,
  /// instead of the stored session. Used for email-link requests so a 401
  /// for a bad link never signs out whoever is using this device.
  final ApiClient Function(String? bearer) _clientWithToken;

  static ApiClient _defaultClientWithToken(String? bearer) => HttpApiClient(
    baseUrl: ApiConfig.baseUrl,
    tokens: bearer == null
        ? const NoTokenProvider()
        : FixedTokenProvider(bearer),
  );

  /// Kept in memory only, between sign-up and "I've confirmed my email",
  /// so the app can sign in once the address is confirmed.
  ({String email, String password})? _pending;

  @override
  Future<Session> signIn({
    required String email,
    required String password,
  }) async {
    final Map<String, Object?> session;
    try {
      session =
          await _api.post(
                ApiEndpoints.authLogin,
                body: {'email': email.trim(), 'password': password},
              )
              as Map<String, Object?>;
    } on ApiException catch (e) {
      if (e is NetworkException || e is RequestTimeoutException) rethrow;
      if (e is ServerException) rethrow;
      // invalid_credentials, unconfirmed email, validation… – show the
      // backend's own message.
      throw AuthFailure(e.message);
    }
    await _tokens.save(SessionTokens.fromSessionJson(session));
    _pending = null;
    return _loadSession();
  }

  @override
  Future<Session> signUp({
    required String fullName,
    required String email,
    required String password,
    required AppRole role,
  }) async {
    final Map<String, Object?> out;
    try {
      out =
          await _api.post(
                ApiEndpoints.authSignup,
                body: {
                  'email': email.trim(),
                  'password': password,
                  'full_name': fullName.trim(),
                },
              )
              as Map<String, Object?>;
    } on ValidationException catch (e) {
      throw AuthFailure(e.fieldErrors.values.firstOrNull ?? e.message);
    }
    final session = out['session'];
    if (session is Map<String, Object?>) {
      await _tokens.save(SessionTokens.fromSessionJson(session));
      return _loadSession();
    }
    // Email confirmation required: no session until the link is opened.
    _pending = (email: email.trim(), password: password);
    final user = out['user'] as Map<String, Object?>?;
    return Session(
      user: AppUser(
        fullName: (user?['full_name'] as String?) ?? fullName.trim(),
        email: email.trim(),
        roles: {appRoleFromApi(user?['role'])},
      ),
    );
  }

  @override
  Future<void> sendPasswordReset(String email) =>
      _api.post(ApiEndpoints.authForgotPassword, body: {'email': email.trim()});

  /// Confirmation link: keep its session (implicit flow) like a sign-in, or
  /// exchange its `token_hash` with `POST /auth/verify-email`, then load
  /// the account.
  @override
  Future<Session> signInWithLink(AuthLink link) async {
    const expired = AuthFailure(
      'This link has expired or was already used. Log in instead.',
    );
    final Map<String, Object?> sessionJson;
    if (link.hasSession) {
      sessionJson = link.sessionJson;
    } else if (link.canVerifyEmail) {
      try {
        sessionJson =
            await _clientWithToken(null).post(
                  ApiEndpoints.authVerifyEmail,
                  body: {
                    'token_hash': link.tokenHash,
                    'type': link.type == 'signup' ? 'signup' : 'email',
                  },
                )
                as Map<String, Object?>;
      } on UnauthorizedException {
        throw expired;
      } on ValidationException {
        throw expired;
      }
    } else {
      throw const AuthFailure('This link has no sign-in. Log in instead.');
    }
    _tokens.persist = true;
    await _tokens.save(SessionTokens.fromSessionJson(sessionJson));
    try {
      final session = await _loadSession();
      _pending = null;
      return session;
    } on UnauthorizedException {
      await _tokens.clear();
      throw expired;
    }
  }

  /// `POST /api/v1/auth/reset-password` with the recovery link's access
  /// token (Bearer) or `token_hash`. The backend then revokes every session
  /// of the account, so any session stored here is cleared too.
  @override
  Future<void> resetPassword({
    required String newPassword,
    String? tokenHash,
    String? recoveryToken,
  }) async {
    if (tokenHash != null) {
      await _clientWithToken(null).post(
        ApiEndpoints.authResetPassword,
        body: {'new_password': newPassword, 'token_hash': tokenHash},
      );
    } else if (recoveryToken != null) {
      await _clientWithToken(recoveryToken).post(
        ApiEndpoints.authResetPassword,
        body: {'new_password': newPassword},
      );
    } else {
      throw const UnauthorizedException(
        'This reset link is invalid or has expired.',
        'invalid_token',
      );
    }
    _pending = null;
    await _tokens.clear();
  }

  /// `POST /api/v1/auth/change-password` (signed in). The backend checks the
  /// current password for the token's owner only; a wrong one is `403
  /// invalid_password`. When Supabase needs a fresh sign-in the backend
  /// returns a new session, which replaces the stored one.
  @override
  Future<void> changePassword({
    required String email,
    required String currentPassword,
    required String newPassword,
  }) async {
    final Object? out;
    try {
      out = await _api.post(
        ApiEndpoints.authChangePassword,
        body: {
          'current_password': currentPassword,
          'new_password': newPassword,
        },
      );
    } on ForbiddenException catch (e) {
      if (e.code == 'invalid_password') {
        throw const AuthFailure('Your current password is incorrect.');
      }
      rethrow;
    } on ValidationException catch (e) {
      if (e.code == 'same_password' || e.code == 'PASSWORD_UNCHANGED') {
        throw const AuthFailure(
          'Choose a password different from your current one.',
        );
      }
      rethrow;
    }
    final session = out is Map ? out['session'] : null;
    if (session is Map<String, Object?> && session['access_token'] != null) {
      await _tokens.save(SessionTokens.fromSessionJson(session));
    }
  }

  /// `POST /api/v1/auth/resend-verification`. Returns the backend's own
  /// message and, when it sends one, `remaining_attempts`. The backend
  /// enforces the limit (429).
  @override
  Future<ResendVerificationResult> resendVerificationEmail(String email) async {
    final res = await _api.postEnvelope(
      ApiEndpoints.authResendVerification,
      body: {'email': email.trim()},
    );
    return ResendVerificationResult(
      message: res.message ?? 'Verification email sent.',
      remainingAttempts: res.remainingAttempts,
    );
  }

  /// Signs in with the sign-up details; succeeds once the email is confirmed.
  @override
  Future<bool> checkEmailVerified(String email) async {
    final pending = _pending;
    if (pending == null) return false;
    try {
      await signIn(email: pending.email, password: pending.password);
      return true;
    } on AuthFailure {
      return false;
    }
  }

  @override
  Future<Session?> restore() async {
    if (await _tokens.current() == null) return null;
    try {
      return await _loadSession();
    } on UnauthorizedException {
      await _tokens.clear();
      return null;
    }
  }

  @override
  Future<void> signOut() async {
    try {
      if (await _tokens.current() != null) {
        await _api.post(ApiEndpoints.authLogout);
      }
    } finally {
      _pending = null;
      await _tokens.clear();
    }
  }

  /// `/auth/me` + `/profile/me` + CV list + saved preferences → [Session].
  Future<Session> _loadSession() async {
    final me = await _api.get(ApiEndpoints.authMe) as Map<String, Object?>;
    final results = await Future.wait<Object?>([
      _api.get(ApiEndpoints.profileMe).catchError((_) => null),
      _api.get(ApiEndpoints.cvList).catchError((_) => null),
      _api.get(ApiEndpoints.preferences).catchError((_) => null),
    ]);
    final profile = results[0] as Map<String, Object?>?;
    final cvs = results[1] is List ? results[1]! as List : const [];
    final prefs = results[2] as Map<String, Object?>?;
    final hasCv = cvs.any(
      (c) => c is Map && c['processing_status'] == 'completed',
    );
    final user = appUserFromApi(me, profile, hasCv: hasCv);
    final hasPreferences =
        prefs?['updated_at'] != null ||
        apiStrings(profile?['preferred_job_titles']).isNotEmpty;
    return Session(
      user: user,
      emailVerified: me['email_verified'] != false,
      onboardingComplete: hasPreferences,
    );
  }
}
