import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sharkhire/features/job_search/data/repositories/jobs_repository.dart';
import 'package:sharkhire/features/job_search/data/mock_jobs.dart';
import 'package:sharkhire/shared/models/job_summary.dart';
import 'package:sharkhire/shared/widgets/match_score_badge.dart';
import 'package:sharkhire/shared/widgets/state_views.dart';

import 'helpers.dart';

class _FailingRepo implements JobsRepository {
  @override
  Future<List<JobSummary>> fetchJobs() async => throw Exception('offline');

  @override
  Future<List<JobSummary>> search(String query, {String? city}) async =>
      throw Exception('offline');
}

void main() {
  testWidgets(
    'Splash → Home shows recommendations, saving works, tabs switch',
    (tester) async {
      usePhone(tester);
      await launchToSeekerHome(tester);

      expect(find.text('Recommended for you'), findsOneWidget);
      await scrollTo(tester, find.text('Senior Flutter Developer'));
      expect(find.text('Senior Flutter Developer'), findsOneWidget);
      expect(find.byType(FitScoreBlock), findsWidgets);
      expect(find.byType(NavigationBar), findsOneWidget);

      // Save a job → Riverpod state flips the bookmark.
      final save = find.byTooltip('Save job').first;
      await tester.ensureVisible(save);
      await tester.pumpAndSettle();
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect(find.byTooltip('Remove from saved'), findsOneWidget);

      // Saved tab lists it.
      await tester.tap(find.text('Saved').last);
      await tester.pumpAndSettle();
      expect(find.text('1 job saved'), findsOneWidget);

      // Profile tab.
      await tester.tap(find.text('Profile').last);
      await tester.pumpAndSettle();
      expect(find.text('Ayesha Khan'), findsOneWidget);
    },
  );

  testWidgets('Explore filters narrow results and show empty state', (
    tester,
  ) async {
    usePhone(tester);
    await launchToSeekerHome(tester);

    await tester.tap(find.text('Explore'));
    await tester.pumpAndSettle();
    expect(find.text('${MockJobs.all().length} jobs found'), findsOneWidget);

    final internship = find.widgetWithText(FilterChip, 'Internship');
    await tester.scrollUntilVisible(
      internship,
      120,
      scrollable: find.descendant(
        of: find.ancestor(
          of: find.byType(FilterChip).first,
          matching: find.byType(ListView),
        ),
        matching: find.byType(Scrollable),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(internship);
    await tester.pumpAndSettle();
    expect(find.text('1 job found'), findsOneWidget);
    expect(find.text('Growth Marketing Intern'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'zzz-no-match');
    await tester.pumpAndSettle();
    expect(find.text('No jobs match'), findsOneWidget);
  });

  testWidgets('Home shows an error state when jobs fail to load', (
    tester,
  ) async {
    usePhone(tester);
    await launchToSeekerHome(
      tester,
      overrides: [jobsRepositoryProvider.overrideWithValue(_FailingRepo())],
    );
    // Error views render in both Home job sections; scroll them into the build area.
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -400));
    await tester.pumpAndSettle();
    expect(find.byType(ErrorStateView), findsWidgets);
    expect(find.text('Try again'), findsWidgets);
  });

  testWidgets('Every tab lays out without overflow on a small 320px phone', (
    tester,
  ) async {
    usePhone(tester, logical: const Size(320, 568), dpr: 2);
    await launchToSeekerHome(tester);

    for (final tab in ['Explore', 'Saved', 'Profile', 'Home']) {
      await tester.tap(find.text(tab).last);
      await tester.pumpAndSettle();
      // Scroll through the tab so lazily built content is laid out too.
      await tester.fling(
        find.byType(Scrollable).first,
        const Offset(0, -2000),
        3000,
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: '$tab overflowed');
    }
  });
}
