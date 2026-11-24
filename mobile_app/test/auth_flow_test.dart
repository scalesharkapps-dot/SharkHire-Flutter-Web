import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sharkhire/features/authentication/presentation/screens/forgot_password_screen.dart';
import 'package:sharkhire/features/authentication/presentation/screens/login_screen.dart';
import 'package:sharkhire/features/authentication/presentation/screens/register_screen.dart';
import 'package:sharkhire/features/authentication/presentation/screens/verify_email_screen.dart';
import 'package:sharkhire/features/authentication/presentation/screens/welcome_screen.dart';
import 'package:sharkhire/features/onboarding/presentation/screens/job_preferences_screen.dart';
import 'package:sharkhire/features/authentication/domain/session.dart';
import 'package:sharkhire/shared/models/app_user.dart';

import 'helpers.dart';

Future<void> _waitForWelcome(WidgetTester tester) => pumpUntil(
  tester,
  () => isShown(find.bySemanticsLabel('Find work that fits you.')),
);

Future<void> _tapButton(WidgetTester tester, String label) async {
  final button = find
      .ancestor(
        of: find.text(label),
        matching: find.byWidgetPredicate((w) => w is ButtonStyleButton),
      )
      .last;
  await tester.ensureVisible(button);
  await tester.pumpAndSettle();
  await tester.tap(button);
  await tester.pump();
}

void main() {
  testWidgets(
    'Job seeker signs up, verifies, sets preferences and lands on Home',
    (tester) async {
      usePhone(tester);
      await launchApp(tester);
      await _waitForWelcome(tester);

      await _tapButton(tester, 'Create account');
      await tester.pumpAndSettle();
      expect(find.text('Create your account'), findsOneWidget);

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'Sara Malik');
      await tester.enterText(fields.at(1), 'sara@example.com');
      await tester.enterText(fields.at(2), 'Str0ng!pass');
      await _tapButton(tester, 'Create account');

      await pumpUntil(tester, () => isShown(find.text('Confirm your email')));
      expect(find.text('sara@example.com', findRichText: true), findsOneWidget);

      await _tapButton(tester, 'I\'ve confirmed my email');
      await pumpUntil(
        tester,
        () => isShown(find.text('What are you looking for, Sara?')),
      );

      await _tapButton(tester, 'Continue');
      // Step 2: CV upload, which can be skipped.
      await pumpUntil(tester, () => isShown(find.text('Step 2 of 2')));
      await _tapButton(tester, 'Skip for now');
      await pumpUntil(tester, () => isShown(find.byType(NavigationBar)));
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      expect(find.text('Recommended for you'), findsOneWidget);
      expect(find.textContaining('Sara'), findsWidgets);
    },
  );

  testWidgets('Employer demo account logs in to the employer app', (
    tester,
  ) async {
    usePhone(tester);
    await launchApp(tester);
    await _waitForWelcome(tester);

    await _tapButton(tester, 'Log in');
    await tester.pumpAndSettle();
    final demo = find.widgetWithText(ActionChip, 'Employer');
    await tester.ensureVisible(demo);
    await tester.pumpAndSettle();
    await tester.tap(demo);
    await _tapButton(tester, 'Log in');

    await pumpUntil(tester, () => isShown(find.text('Applicants')));
    expect(find.text('Overview'), findsOneWidget);
    expect(find.text('Explore'), findsNothing);
  });

  testWidgets('Wrong password shows a clear error', (tester) async {
    usePhone(tester);
    await launchApp(tester);
    await _waitForWelcome(tester);
    await _tapButton(tester, 'Log in');
    await tester.pumpAndSettle();

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'seeker@sharkhire.app');
    await tester.enterText(fields.at(1), 'wrong-password');
    await _tapButton(tester, 'Log in');
    await pumpUntil(tester, () => isShown(find.textContaining('don\'t match')));
  });

  testWidgets('Login form validates before submitting', (tester) async {
    usePhone(tester);
    await launchApp(tester);
    await _waitForWelcome(tester);
    await _tapButton(tester, 'Log in');
    await tester.pumpAndSettle();
    await _tapButton(tester, 'Log in');
    await tester.pumpAndSettle();
    expect(find.text('Enter your email address'), findsOneWidget);
    expect(find.text('Enter your password'), findsOneWidget);
  });

  group('Auth screens fit a 320px phone', () {
    const unverified = Session(
      user: AppUser(fullName: 'Sara Malik', email: 'sara@example.com'),
    );
    final screens = <String, (Widget, Session)>{
      'welcome': (const WelcomeScreen(), Session.signedOut),
      'login': (const LoginScreen(), Session.signedOut),
      'register': (const RegisterScreen(), Session.signedOut),
      'forgot': (const ForgotPasswordScreen(), Session.signedOut),
      'verify': (const VerifyEmailScreen(), unverified),
      'preferences': (const JobPreferencesScreen(), seekerSession),
    };
    for (final MapEntry(key: name, value: (screen, session))
        in screens.entries) {
      testWidgets(
        name,
        (tester) =>
            expectNoOverflowOnSmallPhone(tester, screen, session: session),
      );
    }
  });
}
