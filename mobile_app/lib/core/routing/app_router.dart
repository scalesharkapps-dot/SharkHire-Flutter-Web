import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../features/admin/presentation/screens/admin_content_screens.dart';
import '../../features/admin/presentation/screens/admin_jobs_screen.dart';
import '../../features/admin/presentation/screens/admin_moderation_screens.dart';
import '../../features/admin/presentation/screens/admin_more_screen.dart';
import '../../features/admin/presentation/screens/admin_overview_screen.dart';
import '../../features/admin/presentation/screens/admin_system_screens.dart';
import '../../features/admin/presentation/screens/admin_users_screen.dart';
import '../../features/applications/presentation/screens/application_details_screen.dart';
import '../../features/applications/presentation/screens/applications_screen.dart';
import '../../features/authentication/presentation/providers/session_provider.dart';
import '../../features/authentication/presentation/screens/forgot_password_screen.dart';
import '../../features/authentication/presentation/screens/login_screen.dart';
import '../../features/authentication/presentation/screens/register_screen.dart';
import '../../features/authentication/presentation/screens/verify_email_screen.dart';
import '../../features/authentication/presentation/screens/welcome_screen.dart';
import '../../features/employers/presentation/screens/employer_applicants_screens.dart';
import '../../features/employers/presentation/screens/employer_company_screen.dart';
import '../../features/employers/presentation/screens/employer_jobs_screen.dart';
import '../../features/employers/presentation/screens/employer_overview_screen.dart';
import '../../features/employers/presentation/screens/job_form_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/job_details/presentation/screens/apply_screen.dart';
import '../../features/job_details/presentation/screens/job_details_screen.dart';
import '../../features/job_search/presentation/screens/explore_screen.dart';
import '../../features/notifications/presentation/screens/job_alerts_screen.dart';
import '../../features/notifications/presentation/screens/notifications_screen.dart';
import '../../features/onboarding/presentation/screens/job_preferences_screen.dart';
import '../../features/onboarding/presentation/screens/splash_screen.dart';
import '../../features/profile/presentation/screens/edit_profile_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/resume/presentation/screens/cv_review_screen.dart';
import '../../features/resume/presentation/screens/cv_upload_screen.dart';
import '../../features/saved_jobs/presentation/screens/saved_jobs_screen.dart';
import '../../features/settings/presentation/screens/settings_screens.dart';
import '../../features/settings/presentation/screens/subscription_screen.dart';
import '../../shared/widgets/main_navigation_shell.dart';
import 'app_routes.dart';
import 'route_guard.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

GoRoute _route(String path, Widget Function(GoRouterState s) build) => GoRoute(
  path: path,
  parentNavigatorKey: _rootNavigatorKey,
  builder: (context, state) => build(state),
);

StatefulShellBranch _branch(String path, Widget screen) => StatefulShellBranch(
  routes: [GoRoute(path: path, builder: (context, state) => screen)],
);

/// The app's single [GoRouter]. It re-runs [routeGuard] whenever the
/// session changes (sign-in, verification, onboarding, sign-out).
final appRouterProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref.listen(sessionProvider, (_, _) => refresh.value++);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.splash,
    refreshListenable: refresh,
    redirect: (context, state) =>
        routeGuard(ref.read(sessionProvider), state.matchedLocation),
    routes: [
      _route(AppRoutes.splash, (_) => const SplashScreen()),

      // Sign-in and account setup
      _route(AppRoutes.welcome, (_) => const WelcomeScreen()),
      _route(AppRoutes.login, (_) => const LoginScreen()),
      _route(AppRoutes.register, (_) => const RegisterScreen()),
      _route(AppRoutes.forgotPassword, (_) => const ForgotPasswordScreen()),
      _route(AppRoutes.verifyEmail, (_) => const VerifyEmailScreen()),
      _route(
        AppRoutes.onboardingPreferences,
        (_) => const JobPreferencesScreen(),
      ),

      // Job seeker app
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) =>
            MainNavigationShell(navigationShell: shell),
        branches: [
          _branch(AppRoutes.home, const HomeScreen()),
          _branch(AppRoutes.explore, const ExploreScreen()),
          _branch(AppRoutes.saved, const SavedJobsScreen()),
          _branch(AppRoutes.profile, const ProfileScreen()),
        ],
      ),
      _route(AppRoutes.applications, (_) => const ApplicationsScreen()),
      _route(
        AppRoutes.jobPreferences,
        (_) => const JobPreferencesScreen(isOnboarding: false),
      ),
      _route(
        AppRoutes.cvUpload,
        (s) => CvUploadScreen(
          fromOnboarding: s.uri.queryParameters['from'] == 'onboarding',
        ),
      ),
      _route(AppRoutes.cvReview, (_) => const CvReviewScreen()),
      _route(AppRoutes.notifications, (_) => const NotificationsScreen()),
      _route(AppRoutes.jobAlerts, (_) => const JobAlertsScreen()),
      _route(AppRoutes.subscription, (_) => const SubscriptionScreen()),
      _route(AppRoutes.settings, (_) => const SettingsScreen()),
      _route(AppRoutes.privacy, (_) => const PrivacyScreen()),
      _route(AppRoutes.help, (_) => const HelpScreen()),
      _route(AppRoutes.editProfile, (_) => const EditProfileScreen()),
      _route(
        '/jobs/:id',
        (s) => JobDetailsScreen(jobId: s.pathParameters['id']!),
      ),
      _route(
        '/jobs/:id/apply',
        (s) => ApplyScreen(jobId: s.pathParameters['id']!),
      ),
      _route(
        '/applications/:id',
        (s) => ApplicationDetailsScreen(applicationId: s.pathParameters['id']!),
      ),
      _route(
        '/applications/:id/sent',
        (s) => ApplicationSentScreen(applicationId: s.pathParameters['id']!),
      ),

      // Employer app
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) =>
            MainNavigationShell(navigationShell: shell, tabs: employerTabs),
        branches: [
          _branch(AppRoutes.employerOverview, const EmployerOverviewScreen()),
          _branch(AppRoutes.employerJobs, const EmployerJobsScreen()),
          _branch(
            AppRoutes.employerApplicants,
            const EmployerApplicantsScreen(),
          ),
          _branch(AppRoutes.employerCompany, const EmployerCompanyScreen()),
        ],
      ),
      // Admin app (guide §3.7, on mobile)
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) =>
            MainNavigationShell(navigationShell: shell, tabs: adminTabs),
        branches: [
          _branch(AppRoutes.adminOverview, const AdminOverviewScreen()),
          _branch(AppRoutes.adminJobs, const AdminJobsScreen()),
          _branch(AppRoutes.adminUsers, const AdminUsersScreen()),
          _branch(AppRoutes.adminMore, const AdminMoreScreen()),
        ],
      ),
      _route(AppRoutes.adminEmployers, (_) => const AdminEmployersScreen()),
      _route(
        AppRoutes.adminApplications,
        (_) => const AdminApplicationsScreen(),
      ),
      _route(
        AppRoutes.adminExternalJobs,
        (_) => const AdminExternalJobsScreen(),
      ),
      _route(AppRoutes.adminCvReports, (_) => const AdminCvReportsScreen()),
      _route(AppRoutes.adminCategories, (_) => const AdminCategoriesScreen()),
      _route(
        AppRoutes.adminAnnouncements,
        (_) => const AdminAnnouncementsScreen(),
      ),
      _route(
        AppRoutes.adminApiMonitoring,
        (_) => const AdminApiMonitoringScreen(),
      ),
      _route(AppRoutes.adminAnalytics, (_) => const AdminAnalyticsScreen()),
      _route(AppRoutes.adminAuditLogs, (_) => const AdminAuditLogsScreen()),
      _route(AppRoutes.adminSettings, (_) => const AdminSettingsScreen()),

      _route(AppRoutes.employerNewJob, (_) => const JobFormScreen()),
      _route(
        '/employer/jobs/:id/edit',
        (s) => JobFormScreen(jobId: s.pathParameters['id']),
      ),
      _route(
        '/employer/applicants/:id',
        (s) => CandidateDetailsScreen(applicantId: s.pathParameters['id']!),
      ),
    ],
  );
});
