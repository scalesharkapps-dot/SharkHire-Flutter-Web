/// Route paths in one place. Navigate with `context.go(AppRoutes.home)`;
/// never hard-code path strings in widgets.
abstract final class AppRoutes {
  static const String splash = '/';

  // Authentication (signed out)
  static const String welcome = '/welcome';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';

  // Account setup
  static const String verifyEmail = '/verify-email';
  static const String onboardingPreferences = '/onboarding/preferences';

  // Job seeker tabs: Home | Explore | Saved | Profile
  static const String home = '/home';
  static const String explore = '/explore';
  static const String saved = '/saved';
  static const String profile = '/profile';

  // Job seeker full-screen routes
  static const String applications = '/applications';
  static const String jobPreferences = '/preferences';
  static const String cvUpload = '/cv/upload';
  static const String cvReview = '/cv/review';
  static const String notifications = '/notifications';
  static const String jobAlerts = '/job-alerts';
  static const String subscription = '/subscription';
  static const String settings = '/settings';
  static const String privacy = '/settings/privacy';
  static const String help = '/help';
  static const String editProfile = '/profile/edit';

  static String jobDetails(String id) => '/jobs/$id';
  static String applyToJob(String id) => '/jobs/$id/apply';
  static String applicationDetails(String id) => '/applications/$id';
  static String applicationSent(String id) => '/applications/$id/sent';

  /// CV upload as the second onboarding step.
  static const String cvUploadOnboarding = '/cv/upload?from=onboarding';

  // Employer tabs: Overview | Jobs | Applicants | Company
  static const String employerOverview = '/employer';
  static const String employerJobs = '/employer/jobs';
  static const String employerApplicants = '/employer/applicants';
  static const String employerCompany = '/employer/company';
  static const String employerNewJob = '/employer/jobs/new';
  static String employerEditJob(String id) => '/employer/jobs/$id/edit';
  static String employerCandidate(String id) => '/employer/applicants/$id';

  // Admin tabs: Overview | Jobs | Users | More (guide §3.7, on mobile)
  static const String adminOverview = '/admin';
  static const String adminJobs = '/admin/jobs';
  static const String adminUsers = '/admin/users';
  static const String adminMore = '/admin/more';
  static const String adminEmployers = '/admin/employers';
  static const String adminApplications = '/admin/applications';
  static const String adminExternalJobs = '/admin/external-jobs';
  static const String adminCvReports = '/admin/cv-reports';
  static const String adminCategories = '/admin/categories';
  static const String adminAnnouncements = '/admin/announcements';
  static const String adminApiMonitoring = '/admin/api-monitoring';
  static const String adminAnalytics = '/admin/analytics';
  static const String adminAuditLogs = '/admin/audit-logs';
  static const String adminSettings = '/admin/settings';

  /// Reachable while signed out.
  static const Set<String> publicRoutes = {
    splash,
    welcome,
    login,
    register,
    forgotPassword,
  };

  static bool isAdminRoute(String location) =>
      location == adminOverview || location.startsWith('$adminOverview/');

  static bool isEmployerRoute(String location) =>
      location.startsWith(employerOverview);
}
