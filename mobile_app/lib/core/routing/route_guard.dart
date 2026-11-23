import '../../features/authentication/domain/session.dart';
import '../../features/subscription/domain/subscription_status.dart';
import 'app_routes.dart';

/// Decides where a user may go. Returns the path to redirect to, or null to
/// allow [location]. Pure, so it is unit-tested directly.
///
/// Roles only choose *navigation*; the backend still authorises every
/// request (guide §3.4).
///
/// [subscription] is the backend's app-access status; pass null while
/// subscriptions are not enforced. Job seekers without confirmed access
/// (including while it is loading, or after an error) are sent to the
/// paywall, which keeps [fullLocation] to return to afterwards.
String? routeGuard(
  Session session,
  String location, {
  SubscriptionStatus? subscription,
  String? fullLocation,
}) {
  // The splash decides on its own when to leave.
  if (location == AppRoutes.splash) return null;
  // Email confirmation and password-reset links work in every state.
  if (AppRoutes.authLinkRoutes.contains(location)) return null;

  final isPublic = AppRoutes.publicRoutes.contains(location);

  switch (session.stage) {
    case SessionStage.signedOut:
      return isPublic ? null : AppRoutes.welcome;

    case SessionStage.unverified:
      return location == AppRoutes.verifyEmail ? null : AppRoutes.verifyEmail;

    case SessionStage.needsOnboarding:
      return location == AppRoutes.onboardingPreferences
          ? null
          : AppRoutes.onboardingPreferences;

    case SessionStage.ready:
      // Each role has its own app: admin, employer, or job seeker.
      final home = session.isAdmin
          ? AppRoutes.adminOverview
          : session.isEmployer
          ? AppRoutes.employerOverview
          : AppRoutes.home;
      // Signed-in users never see sign-in or setup screens again.
      if (isPublic ||
          location == AppRoutes.verifyEmail ||
          location == AppRoutes.onboardingPreferences) {
        return home;
      }
      final onAdminRoute = AppRoutes.isAdminRoute(location);
      final onEmployerRoute = AppRoutes.isEmployerRoute(location);
      final allowed = session.isAdmin
          ? onAdminRoute
          : session.isEmployer
          ? onEmployerRoute
          : !onAdminRoute && !onEmployerRoute;
      if (!allowed) return home;
      final needsAccess =
          subscription != null &&
          !session.isAdmin &&
          !session.isEmployer &&
          !subscription.hasAccess;
      if (needsAccess && !AppRoutes.subscriptionFreeRoutes.contains(location)) {
        return AppRoutes.paywall(next: fullLocation ?? location);
      }
      return null;
  }
}
