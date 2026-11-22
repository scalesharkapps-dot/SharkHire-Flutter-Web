// Bold concept screens: welcome, employer welcome and the roles picker.

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sharkhire/features/authentication/domain/session.dart';
import 'package:sharkhire/features/authentication/presentation/screens/employer_welcome_screen.dart';
import 'package:sharkhire/features/authentication/presentation/screens/register_screen.dart';
import 'package:sharkhire/features/authentication/presentation/screens/welcome_screen.dart';
import 'package:sharkhire/features/job_search/presentation/screens/explore_screen.dart';
import 'package:sharkhire/features/job_search/presentation/screens/roles_screen.dart';

import 'helpers.dart';

void main() {
  group('Fit a 320px phone', () {
    testWidgets(
      'welcome',
      (t) => expectNoOverflowOnSmallPhone(
        t,
        const WelcomeScreen(),
        session: Session.signedOut,
      ),
    );
    testWidgets(
      'employer welcome',
      (t) => expectNoOverflowOnSmallPhone(
        t,
        const EmployerWelcomeScreen(),
        session: Session.signedOut,
      ),
    );
    testWidgets(
      'roles',
      (t) => expectNoOverflowOnSmallPhone(t, const RolesScreen()),
    );
  });

  testWidgets('Hiring? opens the employer welcome, then employer sign-up', (
    tester,
  ) async {
    usePhone(tester);
    await launchApp(tester);
    await pumpUntil(
      tester,
      () => isShown(find.bySemanticsLabel('Find work that fits you.')),
    );
    await tester.tap(find.text('Hiring? Create an employer account'));
    await tester.pumpAndSettle();
    expect(find.byType(EmployerWelcomeScreen), findsOneWidget);

    await tester.tap(find.text('Create employer account'));
    await tester.pumpAndSettle();
    expect(find.byType(RegisterScreen), findsOneWidget);
    final register = tester.widget<RegisterScreen>(find.byType(RegisterScreen));
    expect(register.initialRole.name, 'employer');
  });

  testWidgets('Roles picker opens Explore for the chosen role', (tester) async {
    usePhone(tester);
    await launchToSeekerHome(tester);
    await tester.tap(find.text('Explore').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('By role'));
    await tester.pumpAndSettle();
    expect(find.byType(RolesScreen), findsOneWidget);

    // The button names how many loaded jobs match, e.g. "Show 2 jobs".
    await tester.tap(find.textContaining(RegExp(r'^Show \d+ jobs?$')));
    await tester.pumpAndSettle();
    expect(find.byType(ExploreScreen), findsOneWidget);
    final field = tester.widget<TextField>(find.byType(TextField).first);
    expect(field.controller!.text, isNotEmpty);
  });
}
