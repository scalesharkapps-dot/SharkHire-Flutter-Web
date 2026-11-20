/// REST endpoints of the deployed SharkHire API
/// (`https://backend-job-search.onrender.com/docs`, OpenAPI checked 17 Nov 2026).
///
/// Only endpoints that exist in the live API are listed here. Paths are
/// relative to [ApiConfig.baseUrl]; never hard-code a host.
abstract final class ApiEndpoints {
  static const String _v1 = '/api/v1';

  // Health (public)
  static const String health = '$_v1/health';

  // Auth (Supabase session issued by the backend)
  static const String authSignup = '$_v1/auth/signup';
  static const String authLogin = '$_v1/auth/login';
  static const String authRefresh = '$_v1/auth/refresh';
  static const String authLogout = '$_v1/auth/logout';
  static const String authMe = '$_v1/auth/me';
  static const String authResendVerification = '$_v1/auth/resend-verification';
  static const String authForgotPassword = '$_v1/auth/forgot-password';

  // Profile
  static const String profileMe = '$_v1/profile/me';

  // CVs
  static const String cvUpload = '$_v1/cv/upload';
  static const String cvList = '$_v1/cv';
  static String cv(String id) => '$_v1/cv/$id';
  static String cvExtractedData(String id) => '$_v1/cv/$id/extracted-data';
  static String cvApplyToProfile(String id) => '$_v1/cv/$id/apply-to-profile';
  static String cvPrimary(String id) => '$_v1/cv/$id/primary';

  // Jobs
  static const String jobSearch = '$_v1/jobs/search'; // JSearch – uses quota
  static const String sharkHireJobs = '$_v1/jobs/sharkhire'; // internal jobs
  static String job(String id) => '$_v1/jobs/$id';

  // Recommendations
  static const String recommendationsForMe = '$_v1/recommendations/for-me';
  static String jobMatch(String jobId) =>
      '$_v1/recommendations/jobs/$jobId/match';
  static const String preferences = '$_v1/recommendations/preferences';

  // Saved jobs
  static const String savedJobs = '$_v1/saved-jobs';
  static String savedJob(String jobId) => '$_v1/saved-jobs/$jobId';

  // Applications
  static const String applications = '$_v1/applications';
  static String application(String id) => '$_v1/applications/$id';
  static String applicationStatus(String id) => '$_v1/applications/$id/status';

  // Employer
  static const String employerJobs = '$_v1/employer/jobs';
  static String employerJob(String id) => '$_v1/employer/jobs/$id';
  static const String employerApplications = '$_v1/employer/applications';

  // Subscriptions – INTEGRATION DEPENDENCY: not in the live API yet (404,
  // checked 20 Nov 2026). Expected by SUBSCRIPTIONS.md.
  static const String subscriptionStatus = '$_v1/subscriptions/status';
  static const String subscriptionSync = '$_v1/subscriptions/sync';
  static const String subscriptionHistory = '$_v1/subscriptions/history';
  static const String subscriptionRestore = '$_v1/subscriptions/restore';
  static const String subscriptionPlans = '$_v1/subscriptions/plans';
}
