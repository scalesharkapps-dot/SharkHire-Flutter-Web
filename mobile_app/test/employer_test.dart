import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sharkhire/features/employers/presentation/screens/employer_applicants_screens.dart';
import 'package:sharkhire/features/employers/presentation/screens/employer_company_screen.dart';
import 'package:sharkhire/features/employers/presentation/screens/employer_jobs_screen.dart';
import 'package:sharkhire/features/employers/presentation/screens/employer_overview_screen.dart';
import 'package:sharkhire/features/employers/presentation/screens/job_form_screen.dart';

import 'helpers.dart';

Future<void> tapText(WidgetTester tester, String label) async {
  final f = find.text(label).last;
  await tester.ensureVisible(f);
  await tester.pumpAndSettle();
  await tester.tap(f);
  await tester.pump();
}

Future<void> launchEmployer(WidgetTester tester) async {
  usePhone(tester);
  await launchApp(tester, session: employerSession);
  await pumpUntil(tester, () => isShown(find.text('Hello, Bilal')));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Post a job: it is submitted as Pending', (tester) async {
    await launchEmployer(tester);
    expect(find.text('EMPLOYER DASHBOARD'), findsOneWidget);

    await tapText(tester, 'Post a job');
    await tester.pumpAndSettle();
    expect(find.text('Create job'), findsOneWidget);

    // Submitting empty shows field errors and does not save.
    await tapText(tester, 'Submit for approval');
    await tester.pumpAndSettle();
    expect(find.text('Job title is required'), findsOneWidget);
    expect(find.text('Add at least one required skill'), findsOneWidget);

    await tester.enterText(
      find.byType(TextFormField).at(0),
      'Mobile Product Designer',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Add a skill, e.g. Python'),
      'Figma',
    );
    await tapText(tester, 'Add');
    await tester.pumpAndSettle();
    final location = find.ancestor(
      of: find.text('City, Country'),
      matching: find.byType(TextFormField),
    );
    await tester.ensureVisible(location);
    await tester.enterText(location, 'Karachi, Pakistan');
    final description = find.ancestor(
      of: find.text('What the role involves and who you\'re looking for'),
      matching: find.byType(TextFormField),
    );
    await tester.ensureVisible(description);
    await tester.enterText(
      description,
      'Design mobile experiences for our payments app with the product team.',
    );
    await tapText(tester, 'Submit for approval');

    await pumpUntil(tester, () => isShown(find.text('Manage jobs')));
    await tester.pumpAndSettle();
    expect(find.text('Mobile Product Designer'), findsOneWidget);
    await tester.pump(const Duration(seconds: 4)); // snackbar
  });

  testWidgets('Filter jobs by status shows the rejection reason', (
    tester,
  ) async {
    await launchEmployer(tester);
    await tester.tap(find.text('Jobs').last);
    await tester.pumpAndSettle();
    await tapText(tester, 'Rejected (1)');
    await tester.pumpAndSettle();
    expect(find.text('QA Engineer'), findsOneWidget);
    expect(
      find.text('Please add a salary range and clearer requirements.'),
      findsOneWidget,
    );
    expect(find.text('Fix & resubmit'), findsOneWidget);
  });

  testWidgets('Review a candidate and change their status', (tester) async {
    await launchEmployer(tester);
    await tester.tap(find.text('Applicants').last);
    await tester.pumpAndSettle();
    await tapText(tester, 'Ali Raza');
    await tester.pumpAndSettle();
    await scrollTo(tester, find.text('Ali_Raza_CV.pdf'));
    expect(find.text('Ali_Raza_CV.pdf'), findsOneWidget);

    await tapText(tester, 'Shortlisted');
    await tester.pumpAndSettle();
    await tapText(tester, 'Update status to Shortlisted');
    await pumpUntil(
      tester,
      () => isShown(find.textContaining('candidate has been notified')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Shortlisted'), findsWidgets);
    await tester.pump(const Duration(seconds: 4));
  });

  group('Employer screens fit a 320px phone', () {
    final screens = <String, Widget>{
      'overview': const EmployerOverviewScreen(),
      'jobs': const EmployerJobsScreen(),
      'create job': const JobFormScreen(),
      'edit rejected job': const JobFormScreen(jobId: 'ej-4'),
      'applicants': const EmployerApplicantsScreen(),
      'candidate': const CandidateDetailsScreen(applicantId: 'c-1'),
      'company': const EmployerCompanyScreen(),
    };
    for (final MapEntry(key: name, value: screen) in screens.entries) {
      testWidgets(
        name,
        (t) =>
            expectNoOverflowOnSmallPhone(t, screen, session: employerSession),
      );
    }
  });
}
