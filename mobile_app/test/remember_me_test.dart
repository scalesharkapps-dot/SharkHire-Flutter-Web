// "Remember me" on the login screen.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sharkhire/core/network/auth_token_provider.dart';
import 'package:sharkhire/core/theme/app_theme.dart';
import 'package:sharkhire/features/authentication/data/login_preferences.dart';
import 'package:sharkhire/features/authentication/data/repositories/auth_repository.dart';
import 'package:sharkhire/features/authentication/domain/session.dart';
import 'package:sharkhire/features/authentication/presentation/providers/session_provider.dart';
import 'package:sharkhire/features/authentication/presentation/screens/login_screen.dart';

import 'helpers.dart';

class _Prefs implements LoginPreferencesStore {
  _Prefs([this.saved = const LoginPreferences()]);
  LoginPreferences saved;
  @override
  Future<LoginPreferences> read() async => saved;
  @override
  Future<void> write(LoginPreferences prefs) async => saved = prefs;
}

void main() {
  group('Session tokens', () {
    const tokens = SessionTokens(accessToken: 'a', refreshToken: 'r');

    test('remembered: kept on the device', () async {
      final store = MemoryTokenStore();
      final m = SessionTokenManager(store: store, baseUrl: 'https://x.test');
      await m.save(tokens);
      expect(await store.read(), isNotNull);
    });

    test('not remembered: memory only, nothing left on the device', () async {
      final store = MemoryTokenStore();
      await store.write(tokens); // left over from an earlier session
      final m = SessionTokenManager(store: store, baseUrl: 'https://x.test')
        ..persist = false;
      await m.save(tokens);
      expect(await store.read(), isNull);
      expect(await m.accessToken(), 'a'); // still signed in for now
    });
  });

  group('Login screen', () {
    Future<(_Prefs, ProviderContainer)> pump(
      WidgetTester tester,
      _Prefs prefs,
    ) async {
      usePhone(tester);
      final container = ProviderContainer(
        overrides: [loginPreferencesStoreProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(theme: AppTheme.light, home: const LoginScreen()),
        ),
      );
      await tester.pumpAndSettle();
      return (prefs, container);
    }

    Checkbox box(WidgetTester t) => t.widget<Checkbox>(find.byType(Checkbox));

    testWidgets('Remember me is on by default and fills the saved email', (
      tester,
    ) async {
      await pump(
        tester,
        _Prefs(const LoginPreferences(email: 'sara@example.com')),
      );
      expect(find.text('Remember me'), findsOneWidget);
      expect(box(tester).value, isTrue);
      expect(find.text('sara@example.com'), findsOneWidget);
    });

    testWidgets('signing in remembers the email and keeps the session', (
      tester,
    ) async {
      final (prefs, c) = await pump(tester, _Prefs());
      await tester.enterText(
        find.byType(TextFormField).first,
        MockAuthRepository.demoSeekerEmail,
      );
      await tester.enterText(
        find.byType(TextFormField).last,
        MockAuthRepository.demoPassword,
      );
      await tester.tap(find.text('Log in'));
      await pumpUntil(tester, () => c.read(sessionProvider).isSignedIn);
      expect(prefs.saved.rememberMe, isTrue);
      expect(prefs.saved.email, MockAuthRepository.demoSeekerEmail);
      expect(c.read(sessionTokenManagerProvider).persist, isTrue);
    });

    testWidgets('unticked: nothing is remembered', (tester) async {
      final (prefs, c) = await pump(
        tester,
        _Prefs(const LoginPreferences(email: 'old@example.com')),
      );
      await tester.tap(find.text('Remember me'));
      await tester.pump();
      expect(box(tester).value, isFalse);
      await tester.enterText(
        find.byType(TextFormField).first,
        MockAuthRepository.demoSeekerEmail,
      );
      await tester.enterText(
        find.byType(TextFormField).last,
        MockAuthRepository.demoPassword,
      );
      await tester.tap(find.text('Log in'));
      await pumpUntil(tester, () => c.read(sessionProvider).isSignedIn);
      expect(prefs.saved.rememberMe, isFalse);
      expect(c.read(sessionTokenManagerProvider).persist, isFalse);
    });

    testWidgets('fits a small phone', (tester) async {
      await expectNoOverflowOnSmallPhone(
        tester,
        const LoginScreen(),
        session: const Session(),
        overrides: [loginPreferencesStoreProvider.overrideWithValue(_Prefs())],
      );
    });
  });
}
