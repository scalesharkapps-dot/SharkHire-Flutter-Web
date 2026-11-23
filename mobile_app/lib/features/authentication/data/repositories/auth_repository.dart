import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_config.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/auth_token_provider.dart';
import '../../../../core/network/http_api_client.dart';

import '../../../../shared/models/app_user.dart';
import '../../../../shared/models/domain_enums.dart';
import '../../domain/auth_link.dart';
import '../../domain/session.dart';
import 'api_auth_repository.dart';

/// Thrown for sign-in problems the user can fix (wrong password, email in use).
class AuthFailure implements Exception {
  const AuthFailure(this.message);
  final String message;

  @override
  String toString() => message;
}

/// The backend's answer to a resend-verification request.
class ResendVerificationResult {
  const ResendVerificationResult({
    required this.message,
    this.remainingAttempts,
  });

  /// The backend's confirmation message.
  final String message;

  /// Resends left, from the backend's `remaining_attempts`. Null when the
  /// backend doesn't report it.
  final int? remainingAttempts;
}

/// Authentication contract. The production implementation
/// ([ApiAuthRepository]) signs in through the SharkHire API, which issues
/// Supabase sessions; roles are read from the backend, never chosen by the
/// client.
abstract interface class AuthRepository {
  Future<Session> signIn({required String email, required String password});

  Future<Session> signUp({
    required String fullName,
    required String email,
    required String password,
    required AppRole role,
  });

  Future<void> sendPasswordReset(String email);

  /// Signs in with the session carried by a confirmation link.
  Future<Session> signInWithLink(AuthLink link);

  /// Sets a new password from a recovery link: with its [tokenHash], or
  /// with its [recoveryToken] (access token). The user signs in afterwards.
  Future<void> resetPassword({
    required String newPassword,
    String? tokenHash,
    String? recoveryToken,
  });

  /// Changes the signed-in user's password. [currentPassword] is checked
  /// first; a wrong one throws [AuthFailure].
  Future<void> changePassword({
    required String email,
    required String currentPassword,
    required String newPassword,
  });

  /// Asks the backend to send the confirmation email again. The backend
  /// enforces the resend limit: when it is reached this throws a
  /// [RateLimitedException] (HTTP 429).
  Future<ResendVerificationResult> resendVerificationEmail(String email);

  /// Re-checks whether the user has confirmed their email.
  Future<bool> checkEmailVerified(String email);

  /// The saved session from a previous launch, or null when signed out.
  Future<Session?> restore();

  Future<void> signOut();
}

/// In-memory implementation for development and demos.
///
/// Demo accounts (password `sharkhire123`):
/// * `seeker@sharkhire.app` – job seeker
/// * `employer@sharkhire.app` – employer
/// * `admin@sharkhire.app` – admin (admin accounts are never created in-app)
class MockAuthRepository implements AuthRepository {
  MockAuthRepository();

  static const demoPassword = 'sharkhire123';
  static const demoSeekerEmail = 'seeker@sharkhire.app';
  static const demoEmployerEmail = 'employer@sharkhire.app';
  static const demoAdminEmail = 'admin@sharkhire.app';
  static const _latency = Duration(milliseconds: 700);

  final Map<String, _Account> _accounts = {
    demoSeekerEmail: _Account(
      user: const AppUser(
        fullName: 'Ayesha Khan',
        email: demoSeekerEmail,
        headline: 'Flutter Developer',
        location: 'Lahore, Pakistan',
        profileCompletion: 0.45,
      ),
      password: demoPassword,
      verified: true,
      onboarded: true,
    ),
    demoAdminEmail: _Account(
      user: const AppUser(
        fullName: 'Sana Iqbal',
        email: demoAdminEmail,
        roles: {AppRole.admin},
        headline: 'Platform admin, Scale Shark',
        profileCompletion: 1,
      ),
      password: demoPassword,
      verified: true,
      onboarded: true,
    ),
    demoEmployerEmail: _Account(
      user: const AppUser(
        fullName: 'Bilal Ahmed',
        email: demoEmployerEmail,
        roles: {AppRole.employer},
        headline: 'Talent Lead, Indus Ledger',
        location: 'Lahore, Pakistan',
        profileCompletion: 1,
      ),
      password: demoPassword,
      verified: true,
      onboarded: true,
    ),
  };

  String _key(String email) => email.trim().toLowerCase();

  Session _sessionOf(_Account a) => Session(
    user: a.user,
    emailVerified: a.verified,
    onboardingComplete: a.onboarded,
  );

  @override
  Future<Session> signIn({
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(_latency);
    final account = _accounts[_key(email)];
    if (account == null || account.password != password) {
      throw const AuthFailure(
        'That email and password don\'t match. Check them and try again.',
      );
    }
    return _sessionOf(account);
  }

  @override
  Future<Session> signUp({
    required String fullName,
    required String email,
    required String password,
    required AppRole role,
  }) async {
    await Future<void>.delayed(_latency);
    final key = _key(email);
    if (_accounts.containsKey(key)) {
      throw const AuthFailure(
        'An account with this email already exists. Log in instead.',
      );
    }
    final account = _Account(
      user: AppUser(fullName: fullName.trim(), email: key, roles: {role}),
      password: password,
    );
    _accounts[key] = account;
    return _sessionOf(account);
  }

  @override
  Future<void> sendPasswordReset(String email) =>
      Future<void>.delayed(_latency);

  /// Development: email links only exist with the live server.
  @override
  Future<Session> signInWithLink(AuthLink link) async {
    await Future<void>.delayed(_latency);
    throw const AuthFailure(
      'Email links only work with the SharkHire server. Log in instead.',
    );
  }

  @override
  Future<void> resetPassword({
    required String newPassword,
    String? tokenHash,
    String? recoveryToken,
  }) async {
    await Future<void>.delayed(_latency);
    if (tokenHash == null && recoveryToken == null) {
      throw const UnauthorizedException(
        'This reset link is invalid or has expired.',
        'invalid_token',
      );
    }
  }

  @override
  Future<void> changePassword({
    required String email,
    required String currentPassword,
    required String newPassword,
  }) async {
    await Future<void>.delayed(_latency);
    final account = _accounts[_key(email)];
    if (account == null || account.password != currentPassword) {
      throw const AuthFailure('Your current password is incorrect.');
    }
    account.password = newPassword;
  }

  /// Mirrors the backend contract for development: 2 resends, then 429.
  final Map<String, int> _resends = {};
  static const maxResends = 2;

  @override
  Future<ResendVerificationResult> resendVerificationEmail(String email) async {
    await Future<void>.delayed(_latency);
    final key = _key(email);
    final used = _resends[key] ?? 0;
    if (used >= maxResends) {
      throw const RateLimitedException(
        message:
            "You've reached the maximum resend limit. Please try again later.",
        code: 'resend_limit_reached',
        remainingAttempts: 0,
      );
    }
    _resends[key] = used + 1;
    return ResendVerificationResult(
      message: 'Verification email sent. Check your inbox.',
      remainingAttempts: maxResends - used - 1,
    );
  }

  @override
  Future<bool> checkEmailVerified(String email) async {
    await Future<void>.delayed(_latency);
    // In the mock, opening the "link" is simulated by this check.
    final account = _accounts[_key(email)];
    if (account == null) return false;
    account.verified = true;
    return true;
  }

  @override
  Future<Session?> restore() async => null;

  @override
  Future<void> signOut() async {}
}

class _Account {
  _Account({
    required this.user,
    required this.password,
    this.verified = false,
    this.onboarded = false,
  });

  final AppUser user;
  String password;
  bool verified;
  bool onboarded;
}

/// Real API when configured (`ApiConfig.isConfigured`), otherwise demo
/// accounts for development.
final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => ApiConfig.isConfigured
      ? ApiAuthRepository(
          ref.watch(apiClientProvider),
          ref.watch(sessionTokenManagerProvider),
        )
      : MockAuthRepository(),
);
