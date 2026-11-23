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
    ApiClient Function(String bearer)? clientWithToken,
  }) : _clientWithToken = clientWithToken ?? _defaultClientWithToken;

  final ApiClient _api;
  final SessionTokenManager _tokens;

  /// A client that sends one given token (the recovery link's) instead of
  /// the stored session.
  final ApiClient Function(String bearer) _clientWithToken;

  static ApiClient _defaultClientWithToken(String bearer) => HttpApiClient(
    baseUrl: ApiConfig.baseUrl,
    tokens: FixedTokenProvider(bearer),
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

  /// Confirmation link with a session (implicit flow): keep it like a
  /// sign-in, then load the account.
  @override
  Future<Session> signInWithLink(AuthLink link) async {
    if (!link.hasSession) {
      throw const AuthFailure('This link has no sign-in. Log in instead.');
    }
    _tokens.persist = true;
    await _tokens.save(SessionTokens.fromSessionJson(link.sessionJson));
    try {
      final session = await _loadSession();
      _pending = null;
      return session;
    } on UnauthorizedException {
      await _tokens.clear();
      throw const AuthFailure(
        'This link has expired or was already used. Log in instead.',
      );
    }
  }

  /// `POST /api/v1/auth/reset-password`.
  @override
  Future<void> resetPassword({
    required String newPassword,
    String? tokenHash,
    String? recoveryToken,
  }) async {
    if (tokenHash != null) {
      await _api.post(
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
  }

  /// Checks [currentPassword] with `POST /auth/login` (which also renews
  /// this device's session), then sets the new one with
  /// `POST /auth/reset-password` authorised by that session. Only the
  /// signed-in user's own password can change.
  @override
  Future<void> changePassword({
    required String email,
    required String currentPassword,
    required String newPassword,
  }) async {
    final Map<String, Object?> session;
    try {
      session =
          await _api.post(
                ApiEndpoints.authLogin,
                body: {'email': email.trim(), 'password': currentPassword},
              )
              as Map<String, Object?>;
    } on ApiException catch (e) {
      if (e is NetworkException ||
          e is RequestTimeoutException ||
          e is ServerException ||
          e is RateLimitedException) {
        rethrow;
      }
      throw const AuthFailure('Your current password is incorrect.');
    }
    await _tokens.save(SessionTokens.fromSessionJson(session));
    await _api.post(
      ApiEndpoints.authResetPassword,
      body: {'new_password': newPassword},
    );
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
