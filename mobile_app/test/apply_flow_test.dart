import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sharkhire/features/applications/presentation/screens/application_details_screen.dart';
import 'package:sharkhire/features/applications/presentation/screens/applications_screen.dart';
import 'package:sharkhire/features/job_details/presentation/screens/apply_screen.dart';
import 'package:sharkhire/features/job_details/presentation/screens/job_details_screen.dart';
import 'package:sharkhire/features/resume/data/models/resume_models.dart';
import 'package:sharkhire/features/resume/presentation/providers/cv_provider.dart';

import 'helpers.dart';

/// Starts with an uploaded CV so the user can apply.
class _CvUploaded extends CvController {
  @override
  CvState build() => CvState(
    active: Resume(
      id: 'cv-1',
      fileName: 'Ayesha_Khan_CV.pdf',
      sizeBytes: 240000,
      uploadedAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
  );
}

Future<void> tapText(WidgetTester tester, String label) async {
  final f = find.text(label).last;
  await tester.ensureVisible(f);
  await tester.pumpAndSettle();
  await tester.tap(f);
  await tester.pump();
}

void main() {
  testWidgets('Apply to an internal job, track it and withdraw', (
    tester,
  ) async {
    usePhone(tester);
    await launchToSeekerHome(
      tester,
      overrides: [cvProvider.overrideWith(_CvUploaded.new)],
    );

    await scrollTo(tester, find.text('Senior Flutter Developer'));
    await tapText(tester, 'Senior Flutter Developer');
    await pumpUntil(
      tester,
      () => isShown(find.text('Strong fit with your CV')),
    );
    expect(find.text('Apply now'), findsOneWidget);
    expect(find.textContaining('Your Flutter and Dart skills'), findsOneWidget);

    await tapText(tester, 'Apply now');
    await tester.pumpAndSettle();
    expect(find.text('Apply to Indus Ledger'), findsOneWidget);
    expect(find.text('Ayesha_Khan_CV.pdf'), findsOneWidget);

    await tester.enterText(
      find.byType(EditableText).last,
      'I build Flutter apps used by thousands.',
    );
    await tapText(tester, 'Submit application');
    await pumpUntil(tester, () => isShown(find.text('Application sent')));

    await tapText(tester, 'Track application');
    await pumpUntil(tester, () => isShown(find.text('My applications')));
    await tester.pumpAndSettle();
    expect(find.text('Senior Flutter Developer'), findsOneWidget);
    expect(find.text('Submitted'), findsWidgets);

    await tapText(tester, 'Senior Flutter Developer');
    await tester.pumpAndSettle();
    expect(
      find.text('I build Flutter apps used by thousands.'),
      findsOneWidget,
    );

    await tapText(tester, 'Withdraw application');
    await tester.pumpAndSettle();
    expect(find.text('Withdraw this application?'), findsOneWidget);
    await tapText(tester, 'Withdraw application');
    await pumpUntil(
      tester,
      () => isShown(find.text('You withdrew this application.')),
    );
  });

  testWidgets('External job sends the user to the employer site', (
    tester,
  ) async {
    usePhone(tester);
    await launchToSeekerHome(tester);
    await scrollTo(tester, find.text('Python Backend Developer'));
    await tapText(tester, 'Python Backend Developer');
    await pumpUntil(tester, () => isShown(find.text('Apply on employer site')));
    // The match hero makes the header taller: scroll to the notice.
    await tester.scrollUntilVisible(
      find.textContaining('SharkHire only records'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(
      find.textContaining(
        'SharkHire only records that you opened the application',
      ),
      findsOneWidget,
    );
    expect(find.text('Apply now'), findsNothing);
  });

  testWidgets('Apply without a CV asks for one first', (tester) async {
    usePhone(tester);
    await launchToSeekerHome(tester);
    await scrollTo(tester, find.text('Senior Flutter Developer'));
    await tapText(tester, 'Senior Flutter Developer');
    await pumpUntil(tester, () => isShown(find.text('Apply now')));
    await tapText(tester, 'Apply now');
    await tester.pumpAndSettle();
    expect(find.text('Upload a CV to apply'), findsOneWidget);
  });

  group('Job and application screens fit a 320px phone', () {
    final cv = [cvProvider.overrideWith(_CvUploaded.new)];
    testWidgets(
      'internal details',
      (t) => expectNoOverflowOnSmallPhone(
        t,
        const JobDetailsScreen(jobId: 'job-01'),
      ),
    );
    testWidgets(
      'external details',
      (t) => expectNoOverflowOnSmallPhone(
        t,
        const JobDetailsScreen(jobId: 'job-02'),
      ),
    );
    testWidgets(
      'apply',
      (t) => expectNoOverflowOnSmallPhone(
        t,
        const ApplyScreen(jobId: 'job-01'),
        overrides: cv,
      ),
    );
    testWidgets(
      'applications',
      (t) => expectNoOverflowOnSmallPhone(t, const ApplicationsScreen()),
    );
    testWidgets(
      'application details',
      (t) => expectNoOverflowOnSmallPhone(
        t,
        const ApplicationDetailsScreen(applicationId: 'app-4'),
      ),
    );
    testWidgets(
      'application sent',
      (t) => expectNoOverflowOnSmallPhone(
        t,
        const ApplicationSentScreen(applicationId: 'app-4'),
      ),
    );
  });
}
