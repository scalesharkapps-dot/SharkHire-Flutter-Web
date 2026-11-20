import 'package:flutter/foundation.dart';

/// App-access states shown by the app. The backend decides which one
/// applies; the app never works it out from local or store data.
enum AccessState {
  /// Status not known yet (first load, or a refresh after sign-in).
  loading,

  /// Inside the 3-day trial the backend started at registration.
  trialActive,

  /// Paid subscription, renewing.
  subscriptionActive,

  /// No trial left and nothing paid: show the paywall.
  paymentRequired,

  /// A paid subscription ended.
  subscriptionExpired,

  /// Cancelled in the store, but paid until the end of the period.
  subscriptionCancelledButActive,

  /// The store couldn't take the renewal payment (grace / retry period).
  billingIssue,

  /// The status couldn't be loaded (network, server, or the subscription
  /// API is not available yet).
  error,
}

/// Subscription status for the signed-in user, as reported by
/// `GET /api/v1/subscriptions/status`.
@immutable
class SubscriptionStatus {
  const SubscriptionStatus({
    required this.state,
    this.trialEndsAt,
    this.currentPeriodEndsAt,
    this.willRenew,
    this.productId,
    this.store,
    this.managementUrl,
    this.hasAccessFromBackend,
    this.message,
    this.serviceUnavailable = false,
  });

  static const loading = SubscriptionStatus(state: AccessState.loading);

  factory SubscriptionStatus.failure(
    String message, {
    bool serviceUnavailable = false,
  }) => SubscriptionStatus(
    state: AccessState.error,
    message: message,
    serviceUnavailable: serviceUnavailable,
  );

  final AccessState state;
  final DateTime? trialEndsAt;

  /// End of the paid period (renewal date, or when access ends after a
  /// cancellation / billing problem).
  final DateTime? currentPeriodEndsAt;
  final bool? willRenew;
  final String? productId;

  /// `play_store`, `app_store`, … as the backend reports it.
  final String? store;
  final String? managementUrl;

  /// The backend's own access decision, when it sends one. It always wins
  /// over [state].
  final bool? hasAccessFromBackend;

  /// Error text (for [AccessState.error]).
  final String? message;

  /// The subscription API answered 404: the backend has not shipped it yet.
  final bool serviceUnavailable;

  bool get isLoading => state == AccessState.loading;

  /// A paid subscription is in place (renewing or not). A billing problem
  /// is not: the user may need to subscribe again.
  bool get isPaid =>
      state == AccessState.subscriptionActive ||
      state == AccessState.subscriptionCancelledButActive;

  /// Whether the backend has granted app access. Fails closed: loading and
  /// errors never grant access.
  bool get hasAccess {
    if (state == AccessState.loading || state == AccessState.error) {
      return false;
    }
    if (hasAccessFromBackend != null) return hasAccessFromBackend!;
    return switch (state) {
      AccessState.trialActive ||
      AccessState.subscriptionActive ||
      AccessState.subscriptionCancelledButActive => true,
      // Stores keep access during a grace period; only while it lasts.
      AccessState.billingIssue =>
        currentPeriodEndsAt != null &&
            currentPeriodEndsAt!.isAfter(DateTime.now()),
      _ => false,
    };
  }

  /// Days left in the trial, counted from the backend's end date (so it
  /// never restarts on sign-out / sign-in).
  int? trialDaysLeft([DateTime? now]) {
    final end = trialEndsAt;
    if (state != AccessState.trialActive || end == null) return null;
    final left = end.difference(now ?? DateTime.now());
    if (left.isNegative) return 0;
    // Round up: 2 days 3 hours left reads as "3 days left".
    return (left.inHours / 24).ceil();
  }
}

/// One entry of `GET /api/v1/subscriptions/history`.
@immutable
class SubscriptionHistoryEntry {
  const SubscriptionHistoryEntry({
    required this.id,
    required this.event,
    this.productId,
    this.store,
    this.price,
    this.occurredAt,
    this.expiresAt,
  });

  final String id;

  /// e.g. `trial_started`, `initial_purchase`, `renewal`, `cancellation`,
  /// `expiration`, `billing_issue` – shown with a readable label.
  final String event;
  final String? productId;
  final String? store;

  /// Price text exactly as the backend sends it (already localized).
  final String? price;
  final DateTime? occurredAt;
  final DateTime? expiresAt;
}

/// One entry of `GET /api/v1/subscriptions/plans` (descriptive only; the
/// price always comes from the store).
@immutable
class SubscriptionPlan {
  const SubscriptionPlan({
    required this.id,
    this.title,
    this.description,
    this.productId,
  });

  final String id;
  final String? title;
  final String? description;
  final String? productId;
}
