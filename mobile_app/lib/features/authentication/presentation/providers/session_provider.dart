import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/auth_token_provider.dart';
import '../../../../core/network/session_expiry.dart';
import '../../../../shared/models/app_user.dart';
import '../../../../shared/models/domain_enums.dart';
import '../../data/repositories/auth_repository.dart';
import '../../domain/auth_link.dart';
import '../../domain/session.dart';

/// Session the app starts with. Signed out by default; tests and previews
/// override it to start inside the app.
final initialSessionProvider = Provider<Session>((ref) => Session.signedOut);

/// Single source of truth for who is signed in and how far they are through
/// sign-up. The router listens to it to guard routes.
class SessionController extends Notifier<Session> {
  AuthRepository get _repo => ref.read(authRepositoryProvider);

  @override
  Session build() {
    // Any API call answered with 401 means the session is no longer valid.
    ref.listen(sessionExpiryProvider, (_, _) {
      if (state.isSignedIn) signOut();
    });
    return ref.read(initialSessionProvider);
  }

  /// [rememberMe] keeps the session on this device after the app closes;
  /// when false the user signs in again next time.
  Future<void> signIn(
    String email,
    String password, {
    bool rememberMe = true,
  }) async {
    ref.read(sessionTokenManagerProvider).persist = rememberMe;
    state = await _repo.signIn(email: email, password: password);
  }

  Future<void> signUp({
    required String fullName,
    required String email,
    required String password,
    required AppRole role,
  }) async {
    ref.read(sessionTokenManagerProvider).persist = true;
    state = await _repo.signUp(
      fullName: fullName,
      email: email,
      password: password,
      role: role,
    );
  }

  /// Signs in with the session carried by an email confirmation link.
  Future<void> signInWithLink(AuthLink link) async {
    state = await _repo.signInWithLink(link);
  }

  /// Restores the session saved on this device (real API only). Called
  /// once by the splash screen; failures leave the user signed out.
  Future<void> restore() async {
    if (state.isSignedIn) return;
    try {
      final saved = await _repo.restore();
      if (saved != null) state = saved;
    } catch (_) {
      // Offline or server unavailable: start signed out.
    }
  }

  /// Returns true when the email is confirmed.
  Future<bool> refreshVerification() async {
    final email = state.user?.email;
    if (email == null) return false;
    final verified = await _repo.checkEmailVerified(email);
    if (verified) {
      // The real API signs in on confirmation; load the full session.
      final full = await _repo.restore();
      state = full ?? state.copyWith(emailVerified: true);
    }
    return verified;
  }

  Future<void> resendVerification() async {
    final email = state.user?.email;
    if (email != null) await _repo.resendVerificationEmail(email);
  }

  void completeOnboarding() => state = state.copyWith(onboardingComplete: true);

  /// Applies a local change to the signed-in user (profile edits, CV state).
  void updateUser(AppUser Function(AppUser user) update) {
    final user = state.user;
    if (user != null) state = state.copyWith(user: update(user));
  }

  /// Forgets the session on this device without asking the server, for
  /// when the server has already ended it (account deleted, password
  /// reset revoked every session).
  Future<void> signOutLocally() async {
    try {
      // Real API only: mock mode keeps no tokens.
      final tokens = ref.read(authTokenProvider);
      if (tokens is SessionTokenManager) await tokens.clear();
    } finally {
      state = Session.signedOut;
    }
  }

  /// Always clears the local session, even if telling the server fails
  /// (offline, or the session already expired).
  Future<void> signOut() async {
    try {
      await _repo.signOut();
    } catch (_) {
      // Nothing to recover: the user is signed out locally either way.
    } finally {
      state = Session.signedOut;
    }
  }
}

final sessionProvider = NotifierProvider<SessionController, Session>(
  SessionController.new,
);
