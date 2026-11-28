import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import 'subscription_providers.dart';

/// Backend error code for a Pro-only feature used without Pro.
const proFeatureRequiredCode = 'PRO_FEATURE_REQUIRED';

/// Whether the signed-in user may use Pro-only features (e.g. Remote jobs).
///
/// Comes from the backend-verified subscription status (RevenueCat via the
/// SharkHire API), so it updates when a subscription starts, ends or
/// expires. When paid features are switched off for a build
/// (`SUBSCRIPTIONS_ENABLED=false`) nothing is locked in the app, like the
/// paywall itself; the backend still has the final say and can answer 403
/// [proFeatureRequiredCode], which the app turns into the upgrade prompt.
final proAccessProvider = Provider<bool>((ref) {
  if (!ref.watch(subscriptionsEnabledProvider)) return true;
  return ref.watch(subscriptionProvider).isPaid;
});

/// Whether [error] is the backend refusing a Pro-only feature.
bool isProFeatureRequired(Object? error) =>
    error is ForbiddenException &&
    error.code?.toUpperCase() == proFeatureRequiredCode;
