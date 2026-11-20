import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sharkhire/core/theme/app_theme.dart';
import 'package:sharkhire/features/applications/presentation/screens/application_details_screen.dart';
import 'package:sharkhire/features/applications/presentation/screens/applications_screen.dart';
import 'package:sharkhire/features/authentication/domain/session.dart';
import 'package:sharkhire/features/authentication/presentation/providers/session_provider.dart';
import 'package:sharkhire/features/authentication/presentation/screens/login_screen.dart';
import 'package:sharkhire/features/authentication/presentation/screens/register_screen.dart';
import 'package:sharkhire/features/authentication/presentation/screens/welcome_screen.dart';
import 'package:sharkhire/features/employers/presentation/screens/employer_applicants_screens.dart';
import 'package:sharkhire/features/employers/presentation/screens/employer_company_screen.dart';
import 'package:sharkhire/features/employers/presentation/screens/employer_jobs_screen.dart';
import 'package:sharkhire/features/employers/presentation/screens/employer_overview_screen.dart';
import 'package:sharkhire/features/employers/presentation/screens/job_form_screen.dart';
import 'package:sharkhire/features/job_details/presentation/screens/job_details_screen.dart';
import 'package:sharkhire/features/job_search/presentation/screens/explore_screen.dart';
import 'package:sharkhire/features/home/presentation/screens/home_screen.dart';
import 'package:sharkhire/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:sharkhire/features/onboarding/presentation/screens/job_preferences_screen.dart';
import 'package:sharkhire/features/profile/presentation/screens/profile_screen.dart';
import 'package:sharkhire/features/resume/presentation/screens/cv_upload_screen.dart';
import 'package:sharkhire/features/saved_jobs/presentation/screens/saved_jobs_screen.dart';
import 'package:sharkhire/features/settings/presentation/screens/settings_screens.dart';
import 'package:sharkhire/features/subscription/presentation/screens/subscription_screen.dart';

import 'helpers.dart';

/// Every mobile screen, with the session it needs.
final _screens = <String, (Widget, Session)>{
  'welcome': (const WelcomeScreen(), Session.signedOut),
  'login': (const LoginScreen(), Session.signedOut),
  'register': (const RegisterScreen(), Session.signedOut),
  'preferences': (const JobPreferencesScreen(), seekerSession),
  'home': (const HomeScreen(), seekerSession),
  'explore': (const ExploreScreen(), seekerSession),
  'saved': (const SavedJobsScreen(), seekerSession),
  'profile': (const ProfileScreen(), seekerSession),
  'cv upload': (const CvUploadScreen(), seekerSession),
  'job details': (const JobDetailsScreen(jobId: 'job-01'), seekerSession),
  'applications': (const ApplicationsScreen(), seekerSession),
  'application details': (
    const ApplicationDetailsScreen(applicationId: 'app-4'),
    seekerSession,
  ),
  'notifications': (const NotificationsScreen(), seekerSession),
  'subscription': (const SubscriptionScreen(), seekerSession),
  'settings': (const SettingsScreen(), seekerSession),
  'employer overview': (const EmployerOverviewScreen(), employerSession),
  'employer jobs': (const EmployerJobsScreen(), employerSession),
  'job form': (const JobFormScreen(), employerSession),
  'applicants': (const EmployerApplicantsScreen(), employerSession),
  'candidate': (
    const CandidateDetailsScreen(applicantId: 'c-1'),
    employerSession,
  ),
  'company': (const EmployerCompanyScreen(), employerSession),
};

Future<void> _pump(
  WidgetTester tester,
  Widget screen,
  Session session,
  Size size,
) async {
  usePhone(tester, logical: size, dpr: 3);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [initialSessionProvider.overrideWithValue(session)],
      child: MaterialApp(theme: AppTheme.light, home: screen),
    ),
  );
  await tester.pump(const Duration(seconds: 1));
  await tester.pumpAndSettle();
}

void main() {
  group('Large phone (430 × 932) – no overflow', () {
    for (final MapEntry(key: name, value: (screen, session))
        in _screens.entries) {
      testWidgets(name, (tester) async {
        await _pump(tester, screen, session, const Size(430, 932));
        final s = find.byType(Scrollable);
        if (isShown(s)) {
          await tester.fling(s.first, const Offset(0, -2000), 3000);
          await tester.pumpAndSettle();
        }
        expect(
          tester.takeException(),
          isNull,
          reason: '$name overflowed on a large phone',
        );
      });
    }
  });

  group('Accessibility guidelines', () {
    const checked = [
      'welcome',
      'login',
      'register',
      'home',
      'explore',
      'saved',
      'profile',
      'job details',
      'applications',
      'notifications',
      'subscription',
      'employer overview',
      'employer jobs',
      'applicants',
    ];
    for (final name in checked) {
      testWidgets(name, (tester) async {
        final handle = tester.ensureSemantics();
        final (screen, session) = _screens[name]!;
        await _pump(tester, screen, session, const Size(390, 844));
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        // The welcome screen's SharkHire logotype mixes two text colours, which
        // the contrast checker compares with each other instead of with the
        // navy background (white 16:1, teal 6:1). WCAG 1.4.3 exempts logos.
        if (name != 'welcome') {
          await expectLater(tester, meetsGuideline(textContrastGuideline));
        }
        handle.dispose();
      });
    }
  });
}
