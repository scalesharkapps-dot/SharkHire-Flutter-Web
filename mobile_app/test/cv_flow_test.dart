import 'package:flutter_test/flutter_test.dart';
import 'package:sharkhire/features/resume/data/models/resume_models.dart';
import 'package:sharkhire/features/resume/data/repositories/resume_repository.dart';
import 'package:sharkhire/features/resume/presentation/providers/cv_provider.dart';
import 'package:sharkhire/features/resume/presentation/screens/cv_review_screen.dart';
import 'package:sharkhire/features/resume/presentation/screens/cv_upload_screen.dart';

import 'helpers.dart';

Future<void> tapLabel(WidgetTester tester, String label) async {
  final f = find.text(label).last;
  await tester.ensureVisible(f);
  await tester.pumpAndSettle();
  await tester.tap(f);
  await tester.pump();
}

void main() {
  group('CvRules', () {
    test('accepts PDF and DOCX within the size limit', () {
      expect(
        CvRules.validate(const PickedCvFile(name: 'cv.pdf', sizeBytes: 200000)),
        isNull,
      );
      expect(
        CvRules.validate(
          const PickedCvFile(name: 'CV.DOCX', sizeBytes: 900000),
        ),
        isNull,
      );
    });

    test('rejects other types, empty and oversized files', () {
      expect(
        CvRules.validate(
          const PickedCvFile(name: 'photo.png', sizeBytes: 1000),
        ),
        contains('PDF or DOCX'),
      );
      expect(
        CvRules.validate(const PickedCvFile(name: 'cv.doc', sizeBytes: 1000)),
        isNotNull,
      );
      expect(
        CvRules.validate(const PickedCvFile(name: 'cv.pdf', sizeBytes: 0)),
        contains('empty'),
      );
      expect(
        CvRules.validate(
          const PickedCvFile(name: 'cv.pdf', sizeBytes: 6 * 1024 * 1024),
        ),
        contains('5 MB'),
      );
    });
  });

  testWidgets('Upload a CV, review the extracted profile and confirm', (
    tester,
  ) async {
    usePhone(tester);
    final files = [
      const PickedCvFile(name: 'portfolio.png', sizeBytes: 50000),
      const PickedCvFile(name: 'Ayesha_Khan_CV.pdf', sizeBytes: 240000),
    ];
    var pick = 0;
    await launchToSeekerHome(
      tester,
      overrides: [
        cvPickerProvider.overrideWithValue(() async => files[pick++]),
        resumeRepositoryProvider.overrideWithValue(
          const MockResumeRepository(stepDelay: Duration(milliseconds: 50)),
        ),
      ],
    );

    // Home's CV prompt opens the upload screen.
    await tapLabel(tester, 'Upload CV');
    await tester.pumpAndSettle();
    expect(find.text('Upload your CV'), findsWidgets);

    // A wrong file type is rejected with a clear message.
    await tapLabel(tester, 'Choose a file');
    await tester.pumpAndSettle();
    expect(find.textContaining('isn\'t a PDF or DOCX'), findsOneWidget);

    // Choosing a valid PDF clears the error and enables upload.
    await tapLabel(tester, 'portfolio.png');
    await tester.pumpAndSettle();
    expect(find.text('Ayesha_Khan_CV.pdf'), findsOneWidget);
    expect(find.textContaining('isn\'t a PDF or DOCX'), findsNothing);

    await tapLabel(tester, 'Upload and analyse');
    await pumpUntil(tester, () => isShown(find.text('Review your profile')));
    await pumpUntil(tester, () => isShown(find.text('Flutter')));

    // Remove a skill, then confirm.
    await tester.tap(find.byTooltip('Remove SQL'));
    await tester.pumpAndSettle();
    expect(find.text('SQL'), findsNothing);

    await tapLabel(tester, 'Confirm and see my matches');
    await pumpUntil(
      tester,
      () => isShown(find.text('Senior Flutter Developer')),
    );
    await tester.pumpAndSettle();

    // The CV prompt is gone and Profile shows the active CV.
    expect(find.text('Upload your CV for sharper matches'), findsNothing);
    await tester.tap(find.text('Profile').last);
    await tester.pumpAndSettle();
    expect(find.text('Ayesha_Khan_CV.pdf'), findsOneWidget);
    expect(find.text('Review extracted profile'), findsOneWidget);
  });

  group('CV screens fit a 320px phone', () {
    testWidgets(
      'upload',
      (t) => expectNoOverflowOnSmallPhone(
        t,
        const CvUploadScreen(fromOnboarding: true),
      ),
    );
    testWidgets(
      'review',
      (t) => expectNoOverflowOnSmallPhone(t, const CvReviewScreen()),
    );
  });
}
