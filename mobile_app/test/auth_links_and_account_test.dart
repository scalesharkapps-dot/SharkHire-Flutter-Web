// Email confirmation and password-recovery links, Change password and
// Delete account.

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sharkhire/core/network/api_client.dart';
import 'package:sharkhire/core/network/api_endpoints.dart';
import 'package:sharkhire/core/network/api_exception.dart';
import 'package:sharkhire/core/network/auth_token_provider.dart';
import 'package:sharkhire/core/routing/app_routes.dart';
import 'package:sharkhire/core/utils/validators.dart';
import 'package:sharkhire/features/authentication/data/repositories/api_auth_repository.dart';
import 'package:sharkhire/features/authentication/data/repositories/auth_repository.dart';
import 'package:sharkhire/features/authentication/domain/auth_link.dart';
import 'package:sharkhire/features/authentication/domain/session.dart';
import 'package:sharkhire/features/authentication/presentation/providers/auth_link_provider.dart';
import 'package:sharkhire/features/authentication/presentation/screens/auth_link_screens.dart';
import 'package:sharkhire/features/authentication/presentation/screens/welcome_screen.dart';
import 'package:sharkhire/features/settings/data/repositories/account_repository.dart';
import 'package:sharkhire/features/settings/presentation/screens/account_screens.dart';

import 'helpers.dart';

/// Delivers a deep link the way Android/iOS do (app running or resumed).
Future<void> openLink(WidgetTester tester, String location) async {
  await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
    'flutter/navigation',
    const JSONMethodCodec().encodeMethodCall(
      MethodCall('pushRouteInformation', {'location': location, 'state': null}),
    ),
    (_) {},
  );
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
  await tester.pumpAndSettle();
}

/// Sign-in from a confirmation link succeeds and opens a ready account.
class _LinkSignIn extends MockAuthRepository {
  @override
  Future<Session> signInWithLink(AuthLink link) async => seekerSession;
}

class _Account implements AccountRepository {
  _Account(this.onDelete);
  final Future<AccountDeletionResult> Function() onDelete;
  int calls = 0;
  String? password;

  @override
  Future<AccountDeletionResult> requestDeletion({required String password}) {
    calls++;
    this.password = password;
    return onDelete();
  }

  @override
  Future<void> requestDataExport() async {}
}

/// Records requests; answers like the live API.
class _RecordingApi implements ApiClient {
  _RecordingApi({this.wrongPassword = false, this.freshSession = false});
  final bool wrongPassword;
  final bool freshSession;
  final posts = <(String, Object?)>[];

  @override
  Future<Object?> post(String path, {Object? body}) async {
    posts.add((path, body));
    if (path == ApiEndpoints.authChangePassword ||
        path == ApiEndpoints.authDeleteAccount) {
      if (wrongPassword) {
        throw const ForbiddenException(
          'The current password is incorrect.',
          'invalid_password',
        );
      }
      if (path == ApiEndpoints.authDeleteAccount) {
        return {'deleted': true, 'active_store_subscription': true};
      }
      return {
        'password_changed': true,
        'session': freshSession
            ? {
                'access_token': 'fresh',
                'refresh_token': 'r',
                'expires_in': 3600,
              }
            : null,
      };
    }
    return null;
  }

  @override
  Future<Object?> get(String path, {Map<String, Object?>? query}) async => null;
  @override
  Future<ApiEnvelope> postEnvelope(String path, {Object? body}) async =>
      const ApiEnvelope();
  @override
  Future<Object?> put(String path, {Object? body}) async => null;
  @override
  Future<Object?> patch(String path, {Object? body}) async => null;
  @override
  Future<Object?> delete(String path) async => null;
  @override
  Future<Object?> upload(
    String path,
    UploadFile file, {
    Map<String, String> fields = const {},
  }) async => null;
}

void main() {
  group('AuthLink', () {
    test('implicit sign-up confirmation (fragment)', () {
      final l = AuthLink.fromUri(
        Uri.parse(
          'https://sharkhire.vercel.app/auth/callback#access_token=a.b.c'
          '&refresh_token=rt&expires_in=3600&token_type=bearer&type=signup',
        ),
      )!;
      expect(l.kind, AuthLinkKind.confirmEmail);
      expect(l.hasSession, isTrue);
      expect(l.sessionJson['refresh_token'], 'rt');
      expect(l.hasError, isFalse);
    });

    test('recovery by token hash, and custom-scheme path', () {
      final l = AuthLink.fromUri(
        Uri.parse('/reset-password?token_hash=abcdef123&type=recovery'),
      )!;
      expect(l.kind, AuthLinkKind.recovery);
      expect(l.canResetPassword, isTrue);
      expect(l.tokenHash, 'abcdef123');
    });

    test('expired link', () {
      final l = AuthLink.fromUri(
        Uri.parse(
          '/auth/callback#error=access_denied&error_code=otp_expired'
          '&error_description=Email+link+is+invalid+or+has+expired',
        ),
      )!;
      expect(l.hasError, isTrue);
      expect(l.isExpired, isTrue);
      expect(l.canResetPassword, isFalse);
    });

    test('tokens never show up in logs', () {
      final l = AuthLink.fromUri(
        Uri.parse('/auth/callback#access_token=SECRET&refresh_token=ALSO'),
      )!;
      expect(l.toString(), isNot(contains('SECRET')));
      expect(l.toString(), isNot(contains('ALSO')));
      expect(l.fingerprint, isNot(contains('SECRET')));
    });

    test('other paths are not links', () {
      expect(AuthLink.fromUri(Uri.parse('/home?type=signup')), isNull);
    });
  });

  group('AuthLinkController', () {
    test('web: reads the page URL once, returns a clean path', () {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      final ctl = c.read(authLinkProvider.notifier)
        ..browserUrl = () => Uri.parse(
          'https://sharkhire.vercel.app/auth/reset-password'
          '#access_token=x&type=recovery',
        );
      // Hash routing turns the fragment into a junk route.
      expect(
        ctl.capture(Uri.parse('/access_token=x&type=recovery')),
        AppRoutes.resetPassword,
      );
      expect(c.read(authLinkProvider)?.kind, AuthLinkKind.recovery);
      expect(ctl.take()?.accessToken, 'x');
      expect(c.read(authLinkProvider), isNull);
      // Only the first navigation looks at the page URL.
      expect(ctl.capture(Uri.parse('/home')), isNull);
    });

    test('the same link delivered twice is stored once', () {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      final ctl = c.read(authLinkProvider.notifier);
      const raw = '/auth/callback#access_token=x&type=signup';
      expect(ctl.capture(Uri.parse(raw)), AppRoutes.authCallback);
      ctl.take();
      expect(ctl.capture(Uri.parse(raw)), AppRoutes.authCallback);
      expect(c.read(authLinkProvider), isNull);
    });

    test('clean in-app paths pass through', () {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      expect(
        c.read(authLinkProvider.notifier).capture(Uri.parse('/auth/callback')),
        isNull,
      );
    });
  });

  group('Links that land on the home page (Site URL fallback)', () {
    test('recovery link on / is a recovery link', () {
      final l = AuthLink.fromUri(
        Uri.parse(
          'https://sharkhire.vercel.app/#access_token=rec&expires_in=3600'
          '&refresh_token=r&token_type=bearer&type=recovery',
        ),
      )!;
      expect(l.kind, AuthLinkKind.recovery);
      expect(l.canResetPassword, isTrue);
    });

    test('expired link on / is still recognised', () {
      final l = AuthLink.fromUri(
        Uri.parse(
          'https://sharkhire.vercel.app/#error=access_denied'
          '&error_code=otp_expired&error_description=Email+link+is+invalid',
        ),
      )!;
      expect(l.isExpired, isTrue);
    });

    test('ordinary pages are not links', () {
      for (final u in [
        '/register?role=employer',
        '/cv/upload?from=onboarding',
        '/subscription?next=%2Fhome',
        'https://sharkhire.vercel.app/',
        'https://sharkhire.vercel.app/#/login',
      ]) {
        expect(AuthLink.fromUri(Uri.parse(u)), isNull, reason: u);
      }
    });

    test('web: home-page recovery link opens the reset screen', () {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      final ctl = c.read(authLinkProvider.notifier)
        ..browserUrl = () => Uri.parse(
          'https://sharkhire.vercel.app/#access_token=rec&type=recovery',
        );
      expect(
        ctl.capture(Uri.parse('/access_token=rec&type=recovery')),
        AppRoutes.resetPassword,
      );
      expect(ctl.take()?.accessToken, 'rec');
    });

    testWidgets('mobile: recovery link to / opens Set a new password', (
      tester,
    ) async {
      usePhone(tester);
      await launchApp(tester);
      await openLink(
        tester,
        '/#access_token=rec&expires_in=3600&type=recovery',
      );
      expect(find.text('Set a new password'), findsOneWidget);
    });
  });

  group('Validators.newPassword', () {
    test('follows the backend policy', () {
      expect(Validators.newPassword('short1A'), 'Use at least 8 characters');
      expect(Validators.newPassword('alllower1'), 'Add an uppercase letter');
      expect(Validators.newPassword('ALLUPPER1'), 'Add a lowercase letter');
      expect(Validators.newPassword('NoNumbers'), 'Add a number');
      expect(Validators.newPassword('Password1'), contains('too common'));
      expect(Validators.newPassword('Shark2026x'), isNull);
      expect(
        Validators.matches(() => 'Password1')('Password2'),
        "Passwords don't match",
      );
    });
  });

  group('ApiAuthRepository', () {
    SessionTokenManager tokens() =>
        SessionTokenManager(store: MemoryTokenStore(), baseUrl: 'http://x');

    test(
      'reset with token hash: no session token, stored session cleared',
      () async {
        final main = _RecordingApi();
        final public = _RecordingApi();
        final t = tokens();
        await t.save(const SessionTokens(accessToken: 'old'));
        String? bearer = 'unset';
        await ApiAuthRepository(
          main,
          t,
          clientWithToken: (b) {
            bearer = b;
            return public;
          },
        ).resetPassword(newPassword: 'Password1', tokenHash: 'hash12345');
        expect(bearer, isNull);
        expect(main.posts, isEmpty);
        expect(await t.current(), isNull);
        final api = public;
        expect(api.posts.single.$1, ApiEndpoints.authResetPassword);
        expect(api.posts.single.$2, {
          'new_password': 'Password1',
          'token_hash': 'hash12345',
        });
      },
    );

    test(
      'reset with the link token uses that token, not the session',
      () async {
        final main = _RecordingApi();
        final withToken = _RecordingApi();
        String? usedToken;
        await ApiAuthRepository(
          main,
          tokens(),
          clientWithToken: (t) {
            usedToken = t;
            return withToken;
          },
        ).resetPassword(
          newPassword: 'Password1',
          recoveryToken: 'recovery-jwt',
        );
        expect(usedToken, 'recovery-jwt');
        expect(main.posts, isEmpty);
        expect(withToken.posts.single.$2, {'new_password': 'Password1'});
      },
    );

    test('change password uses /auth/change-password', () async {
      final api = _RecordingApi();
      final t = tokens();
      await t.save(const SessionTokens(accessToken: 'current'));
      await ApiAuthRepository(api, t).changePassword(
        email: 'a@b.co',
        currentPassword: 'Old1pass',
        newPassword: 'New1pass',
      );
      expect(api.posts.single.$1, ApiEndpoints.authChangePassword);
      expect(api.posts.single.$2, {
        'current_password': 'Old1pass',
        'new_password': 'New1pass',
      });
      expect((await t.current())?.accessToken, 'current');
    });

    test('a fresh session from change password is stored', () async {
      final t = tokens();
      await ApiAuthRepository(
        _RecordingApi(freshSession: true),
        t,
      ).changePassword(
        email: 'a@b.co',
        currentPassword: 'Old1pass',
        newPassword: 'New1pass',
      );
      expect((await t.current())?.accessToken, 'fresh');
    });

    test('verify-email link exchanges the token hash', () async {
      final public = _RecordingApi();
      final link = AuthLink.fromUri(
        Uri.parse('/auth/callback?token_hash=abcdef123&type=signup'),
      )!;
      expect(link.canVerifyEmail, isTrue);
      // The fake answers null, so loading the session fails after the call.
      await expectLater(
        ApiAuthRepository(
          _RecordingApi(),
          tokens(),
          clientWithToken: (_) => public,
        ).signInWithLink(link),
        throwsA(anything),
      );
      expect(public.posts.single.$1, ApiEndpoints.authVerifyEmail);
      expect(public.posts.single.$2, {
        'token_hash': 'abcdef123',
        'type': 'signup',
      });
    });

    test('delete account sends the password and DELETE', () async {
      final api = _RecordingApi();
      final r = await ApiAccountRepository(
        api,
      ).requestDeletion(password: 'Secret1x');
      expect(api.posts.single.$1, ApiEndpoints.authDeleteAccount);
      expect(api.posts.single.$2, {
        'password': 'Secret1x',
        'confirmation': 'DELETE',
      });
      expect(r.activeStoreSubscription, isTrue);
    });

    test('delete account with a wrong password', () async {
      await expectLater(
        ApiAccountRepository(
          _RecordingApi(wrongPassword: true),
        ).requestDeletion(password: 'nope'),
        throwsA(isA<WrongPasswordException>()),
      );
    });

    test('wrong current password changes nothing', () async {
      final api = _RecordingApi(wrongPassword: true);
      await expectLater(
        ApiAuthRepository(api, tokens()).changePassword(
          email: 'a@b.co',
          currentPassword: 'wrong',
          newPassword: 'New1pass',
        ),
        throwsA(isA<AuthFailure>()),
      );
      expect(api.posts.length, 1);
    });
  });

  group('Email links in the app', () {
    testWidgets('confirmation link signs the user in', (tester) async {
      usePhone(tester);
      await launchApp(
        tester,
        overrides: [authRepositoryProvider.overrideWithValue(_LinkSignIn())],
      );
      await openLink(
        tester,
        '/auth/callback#access_token=a&refresh_token=b&expires_in=3600&type=signup',
      );
      await pumpUntil(tester, () => isShown(find.text('Email confirmed')));
      await tester.tap(find.text('Continue'));
      await pumpUntil(tester, () => isShown(find.byType(NavigationBar)));
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
    });

    testWidgets('expired confirmation link explains what to do', (
      tester,
    ) async {
      usePhone(tester);
      await launchApp(tester);
      await openLink(
        tester,
        '/callback#error=access_denied&error_code=otp_expired'
        '&error_description=Email+link+is+invalid+or+has+expired',
      );
      expect(find.text('This link has expired'), findsOneWidget);
      await tester.tap(find.text('Log in'));
      await tester.pumpAndSettle();
      expect(find.text('Forgot password?'), findsOneWidget);
    });

    testWidgets('recovery link: mismatch, then a new password', (tester) async {
      usePhone(tester);
      await launchApp(tester);
      await openLink(
        tester,
        '/auth/reset-password#access_token=rec&expires_in=3600&type=recovery',
      );
      expect(find.text('Set a new password'), findsOneWidget);

      await tester.enterText(find.byType(EditableText).at(0), 'Shark2026x');
      await tester.enterText(find.byType(EditableText).at(1), 'Shark2026y');
      await tester.tap(find.text('Update password'));
      await tester.pumpAndSettle();
      expect(find.text("Passwords don't match"), findsOneWidget);

      await tester.enterText(find.byType(EditableText).at(1), 'Shark2026x');
      await tester.tap(find.text('Update password'));
      await pumpUntil(tester, () => isShown(find.text('Password updated')));
      await tester.tap(find.text('Log in'));
      await tester.pumpAndSettle();
      expect(find.text('Forgot password?'), findsOneWidget);
    });

    testWidgets('expired recovery link offers a new one', (tester) async {
      usePhone(tester);
      await launchApp(tester);
      await openLink(
        tester,
        '/auth/reset-password?error=access_denied&error_code=otp_expired',
      );
      expect(find.text('This reset link has expired'), findsOneWidget);
      await tester.tap(find.text('Send a new link'));
      await tester.pumpAndSettle();
      expect(find.text('Send reset link'), findsOneWidget);
    });
  });

  group('Change password', () {
    Future<void> open(WidgetTester tester) async {
      usePhone(tester);
      await launchToSeekerHome(tester);
      final router = tester
          .widget<MaterialApp>(find.byType(MaterialApp))
          .routerConfig!;
      (router as dynamic).push(AppRoutes.changePassword);
      await tester.pumpAndSettle();
      expect(find.byType(ChangePasswordScreen), findsOneWidget);
    }

    testWidgets('wrong current password is reported', (tester) async {
      await open(tester);
      await tester.enterText(find.byType(EditableText).at(0), 'wrong-pass');
      await tester.enterText(find.byType(EditableText).at(1), 'NewPass123');
      await tester.enterText(find.byType(EditableText).at(2), 'NewPass123');
      await tester.tap(find.widgetWithText(FilledButton, 'Change password'));
      await pumpUntil(
        tester,
        () => isShown(find.text('Your current password is incorrect.')),
      );
    });

    testWidgets('mismatch, then success', (tester) async {
      await open(tester);
      await tester.enterText(
        find.byType(EditableText).at(0),
        MockAuthRepository.demoPassword,
      );
      await tester.enterText(find.byType(EditableText).at(1), 'NewPass123');
      await tester.enterText(find.byType(EditableText).at(2), 'NewPass124');
      await tester.tap(find.widgetWithText(FilledButton, 'Change password'));
      await tester.pumpAndSettle();
      expect(find.text("Passwords don't match"), findsOneWidget);

      await tester.enterText(find.byType(EditableText).at(2), 'NewPass123');
      await tester.tap(find.widgetWithText(FilledButton, 'Change password'));
      await pumpUntil(tester, () => isShown(find.text('Password changed')));
      await tester.pumpAndSettle();
      expect(find.byType(ChangePasswordScreen), findsNothing);
    });
  });

  group('Delete account', () {
    Future<void> open(WidgetTester tester, _Account account) async {
      usePhone(tester);
      await launchToSeekerHome(
        tester,
        overrides: [accountRepositoryProvider.overrideWithValue(account)],
      );
      final router = tester
          .widget<MaterialApp>(find.byType(MaterialApp))
          .routerConfig!;
      (router as dynamic).push(AppRoutes.privacy);
      await tester.pumpAndSettle();
      await scrollTo(tester, find.text('Delete account'));
      await tester.tap(find.text('Delete account'));
      await tester.pumpAndSettle();
      expect(find.byType(DeleteAccountScreen), findsOneWidget);
    }

    Future<void> confirm(WidgetTester tester) async {
      await tester.tap(find.byType(Checkbox));
      await tester.enterText(find.byType(EditableText).at(0), 'Secret1x');
      await tester.enterText(find.byType(EditableText).at(1), 'delete');
      await tester.pump();
      final button = find.widgetWithText(FilledButton, 'Delete my account');
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pump();
    }

    testWidgets('needs the checkbox and DELETE, then signs out', (
      tester,
    ) async {
      final account = _Account(
        () => Future<AccountDeletionResult>.delayed(
          const Duration(milliseconds: 300),
          () => const AccountDeletionResult(),
        ),
      );
      await open(tester, account);
      // Not confirmed yet: nothing happens.
      final button = find.widgetWithText(FilledButton, 'Delete my account');
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pump();
      expect(account.calls, 0);

      await confirm(tester);
      // A second tap while deleting is ignored.
      await tester.tap(button, warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 400));
      expect(account.calls, 1);
      expect(account.password, 'Secret1x');
      await pumpUntil(tester, () => isShown(find.byType(WelcomeScreen)));
      expect(find.text('Your SharkHire account was deleted'), findsOneWidget);
    });

    testWidgets('wrong password keeps the user signed in', (tester) async {
      final account = _Account(
        () async => throw const WrongPasswordException(),
      );
      await open(tester, account);
      await confirm(tester);
      await tester.pumpAndSettle();
      expect(
        find.text('That password is incorrect. Nothing was deleted.'),
        findsOneWidget,
      );
      expect(find.byType(DeleteAccountScreen), findsOneWidget);
    });

    testWidgets('a failed request shows an error', (tester) async {
      final account = _Account(() async => throw const NetworkException());
      await open(tester, account);
      await confirm(tester);
      await tester.pumpAndSettle();
      expect(find.text("Couldn't delete"), findsOneWidget);
      expect(find.byType(DeleteAccountScreen), findsOneWidget);
    });
  });

  group('Fit a 320px phone', () {
    testWidgets(
      'change password',
      (t) => expectNoOverflowOnSmallPhone(t, const ChangePasswordScreen()),
    );
    testWidgets(
      'delete account',
      (t) => expectNoOverflowOnSmallPhone(t, const DeleteAccountScreen()),
    );
    testWidgets(
      'reset password',
      (t) => expectNoOverflowOnSmallPhone(t, const ResetPasswordScreen()),
    );
    testWidgets(
      'confirm email',
      (t) => expectNoOverflowOnSmallPhone(t, const AuthCallbackScreen()),
    );
  });
}
