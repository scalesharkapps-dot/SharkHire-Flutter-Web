import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sharkhire/app.dart';
import 'package:sharkhire/core/theme/app_theme.dart';
import 'package:sharkhire/features/authentication/domain/session.dart';
import 'package:sharkhire/features/authentication/presentation/providers/session_provider.dart';
import 'package:sharkhire/features/job_search/data/mock_jobs.dart';
import 'package:sharkhire/shared/models/app_user.dart';
import 'package:sharkhire/shared/models/domain_enums.dart';

const seekerSession = Session(
  user: AppUser(
    fullName: 'Ayesha Khan',
    email: 'seeker@sharkhire.app',
    headline: 'Flutter Developer',
    location: 'Lahore, Pakistan',
    profileCompletion: 0.45,
  ),
  emailVerified: true,
  onboardingComplete: true,
);

const employerSession = Session(
  user: AppUser(
    fullName: 'Bilal Ahmed',
    email: 'employer@sharkhire.app',
    roles: {AppRole.employer},
  ),
  emailVerified: true,
  onboardingComplete: true,
);

/// Sets a phone-sized test view. Default: 390 x 844 @3x.
void usePhone(
  WidgetTester tester, {
  Size logical = const Size(390, 844),
  double dpr = 3,
}) {
  tester.view.physicalSize = logical * dpr;
  tester.view.devicePixelRatio = dpr;
  addTearDown(tester.view.reset);
}

/// Advances fake time in small steps until [condition] holds (max 10s).
Future<void> pumpUntil(
  WidgetTester tester,
  bool Function() condition, {
  String? reason,
}) async {
  for (var i = 0; i < 100 && !condition(); i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  expect(condition(), isTrue, reason: reason ?? 'Timed out waiting for the UI');
}

bool isShown(Finder f) => f.evaluate().isNotEmpty;

/// Starts the full app. Pass [session] to start signed in.
Future<void> launchApp(
  WidgetTester tester, {
  Session session = Session.signedOut,
  List<Override> overrides = const [],
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        initialSessionProvider.overrideWithValue(session),
        ...overrides,
      ],
      child: const SharkHireApp(),
    ),
  );
  await tester.pump();
}

/// Launches signed in as a job seeker and waits for Home's data.
Future<void> launchToSeekerHome(
  WidgetTester tester, {
  List<Override> overrides = const [],
}) async {
  await launchApp(tester, session: seekerSession, overrides: overrides);
  await pumpUntil(tester, () => isShown(find.byType(NavigationBar)));
  await tester.pump(MockJobs.latency + const Duration(milliseconds: 200));
  await tester.pumpAndSettle();
}

/// Scrolls the first scrollable until [finder] is built and visible.
/// (Slivers below the fold are built lazily, like on a real device.)
Future<void> scrollTo(
  WidgetTester tester,
  Finder finder, {
  double step = 300,
}) async {
  await tester.scrollUntilVisible(
    finder,
    step,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
}

/// Renders [screen] alone at 320 px wide, scrolls it, and fails on any
/// layout overflow. For screens that don't need the router to build.
Future<void> expectNoOverflowOnSmallPhone(
  WidgetTester tester,
  Widget screen, {
  Session session = seekerSession,
  List<Override> overrides = const [],
}) async {
  usePhone(tester, logical: const Size(320, 568), dpr: 2);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        initialSessionProvider.overrideWithValue(session),
        ...overrides,
      ],
      child: MaterialApp(theme: AppTheme.light, home: screen),
    ),
  );
  await tester.pump(const Duration(seconds: 1));
  await tester.pumpAndSettle();
  final scrollables = find.byType(Scrollable);
  if (isShown(scrollables)) {
    await tester.fling(scrollables.first, const Offset(0, -1500), 3000);
    await tester.pumpAndSettle();
  }
  expect(
    tester.takeException(),
    isNull,
    reason: '${screen.runtimeType} overflowed at 320px',
  );
}
