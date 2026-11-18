import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_config.dart';
import '../../../../core/network/auth_token_provider.dart';
import '../../../../core/network/http_api_client.dart';

import '../../../../shared/models/app_user.dart';
import '../../../../shared/models/domain_enums.dart';
import '../../domain/session.dart';
import 'api_auth_repository.dart';

/// Thrown for sign-in problems the user can fix (wrong password, email in use).
class AuthFailure implements Exception {
  const AuthFailure(this.message);
  final String message;

  @override
  String toString() => message;
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

  Future<void> resendVerificationEmail(String email);

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

  @override
  Future<void> resendVerificationEmail(String email) =>
      Future<void>.delayed(_latency);

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
  final String password;
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
