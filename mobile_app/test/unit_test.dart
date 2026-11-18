import 'package:flutter_test/flutter_test.dart';
import 'package:sharkhire/core/routing/app_routes.dart';
import 'package:sharkhire/core/routing/route_guard.dart';
import 'package:sharkhire/core/utils/date_formatters.dart';
import 'package:sharkhire/core/utils/validators.dart';
import 'package:sharkhire/features/authentication/domain/session.dart';
import 'package:sharkhire/shared/models/app_user.dart';
import 'package:sharkhire/shared/models/domain_enums.dart';
import 'package:sharkhire/shared/widgets/match_score_badge.dart';

import 'helpers.dart';

void main() {
  group('routeGuard', () {
    test('signed-out users only see public screens', () {
      expect(routeGuard(Session.signedOut, AppRoutes.home), AppRoutes.welcome);
      expect(
        routeGuard(Session.signedOut, AppRoutes.employerOverview),
        AppRoutes.welcome,
      );
      expect(routeGuard(Session.signedOut, AppRoutes.login), isNull);
      expect(routeGuard(Session.signedOut, AppRoutes.splash), isNull);
    });

    test('unverified users are held on verify-email', () {
      const s = Session(
        user: AppUser(fullName: 'Sara', email: 's@x.io'),
      );
      expect(routeGuard(s, AppRoutes.home), AppRoutes.verifyEmail);
      expect(routeGuard(s, AppRoutes.verifyEmail), isNull);
    });

    test('job seekers finish preferences before entering the app', () {
      const s = Session(
        user: AppUser(fullName: 'Sara', email: 's@x.io'),
        emailVerified: true,
      );
      expect(routeGuard(s, AppRoutes.home), AppRoutes.onboardingPreferences);
      expect(routeGuard(s, AppRoutes.onboardingPreferences), isNull);
    });

    test('each role stays in its own app', () {
      expect(routeGuard(seekerSession, AppRoutes.employerJobs), AppRoutes.home);
      expect(routeGuard(seekerSession, AppRoutes.explore), isNull);
      expect(
        routeGuard(employerSession, AppRoutes.home),
        AppRoutes.employerOverview,
      );
      expect(routeGuard(employerSession, AppRoutes.employerJobs), isNull);
    });

    test('signed-in users skip sign-in screens', () {
      expect(routeGuard(seekerSession, AppRoutes.login), AppRoutes.home);
      expect(
        routeGuard(employerSession, AppRoutes.welcome),
        AppRoutes.employerOverview,
      );
    });
  });

  group('Validators', () {
    test('email', () {
      expect(Validators.email(''), isNotNull);
      expect(Validators.email('name@'), isNotNull);
      expect(Validators.email('name@example.com'), isNull);
    });

    test('password and strength', () {
      expect(Validators.password('short'), isNotNull);
      expect(Validators.password('longenough'), isNull);
      expect(Validators.passwordStrength('abc'), 0);
      expect(Validators.passwordStrength('Abcdefgh1!'), 3);
    });
  });

  test('ApiEnum.parse maps API values and falls back safely', () {
    expect(
      ApiEnum.parse(ApplicationStatus.values, 'under_review'),
      ApplicationStatus.underReview,
    );
    expect(ApiEnum.parse(WorkMode.values, 'onsite'), WorkMode.onsite);
    expect(
      ApiEnum.parse(JobStatus.values, 'unknown', fallback: JobStatus.pending),
      JobStatus.pending,
    );
    expect(ApiEnum.parse(AppRole.values, null), isNull);
  });

  test('AppUser initials and first name', () {
    const u = AppUser(fullName: '  ayesha   khan ', email: 'a@x.io');
    expect(u.initials, 'AK');
    expect(u.firstName, 'ayesha');
    expect(const AppUser(fullName: '', email: '').initials, '?');
  });

  test('relativeAge formats compact ages', () {
    final now = DateTime(2026, 1, 15, 12);
    String age(Duration d) =>
        DateFormatters.relativeAge(now.subtract(d), now: now);
    expect(age(const Duration(minutes: 5)), 'Just now');
    expect(age(const Duration(hours: 3)), '3h');
    expect(age(const Duration(days: 3)), '3d');
    expect(age(const Duration(days: 14)), '2w');
  });

  test('MatchTier thresholds', () {
    expect(MatchTier.of(92), MatchTier.strong);
    expect(MatchTier.of(70), MatchTier.good);
    expect(MatchTier.of(50), MatchTier.fair);
  });
}
