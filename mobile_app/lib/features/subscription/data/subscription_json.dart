// =========================================================================
// PROPOSED RESPONSE SHAPES – INTEGRATION DEPENDENCY
// -------------------------------------------------------------------------
// The live backend has no `/api/v1/subscriptions/*` endpoints yet (all
// return 404, OpenAPI checked 20 Nov 2026). The field names below are the
// frontend's PROPOSAL, documented in SUBSCRIPTIONS.md. When the backend
// publishes its real schema, change ONLY this file to match it.
//
// Safety rules kept here on purpose:
// * An unknown or missing `status` maps to AccessState.error, which never
//   grants access.
// * Nothing here invents a successful response; it only reads one.
// =========================================================================

import '../domain/subscription_status.dart';

/// Proposed `status` values → [AccessState].
const _states = <String, AccessState>{
  'trial_active': AccessState.trialActive,
  'subscription_active': AccessState.subscriptionActive,
  'payment_required': AccessState.paymentRequired,
  'subscription_expired': AccessState.subscriptionExpired,
  'subscription_cancelled_but_active':
      AccessState.subscriptionCancelledButActive,
  'billing_issue': AccessState.billingIssue,
};

DateTime? _date(Object? v) => v is String ? DateTime.tryParse(v) : null;
String? _str(Object? v) => v is String && v.isNotEmpty ? v : null;

/// Proposed `data` of GET /status, POST /sync and POST /restore:
/// ```json
/// {
///   "status": "trial_active",
///   "has_access": true,
///   "trial_ends_at": "2026-11-23T10:00:00Z",
///   "current_period_ends_at": null,
///   "will_renew": null,
///   "product_id": null,
///   "store": null,
///   "management_url": null
/// }
/// ```
SubscriptionStatus subscriptionStatusFromJson(Object? json) {
  if (json is! Map) {
    return SubscriptionStatus.failure(
      'We couldn\'t read your subscription status. Please try again.',
    );
  }
  final state = _states[json['status']];
  if (state == null) {
    return SubscriptionStatus.failure(
      'We couldn\'t read your subscription status. Please try again.',
    );
  }
  final hasAccess = json['has_access'];
  return SubscriptionStatus(
    state: state,
    hasAccessFromBackend: hasAccess is bool ? hasAccess : null,
    trialEndsAt: _date(json['trial_ends_at']),
    currentPeriodEndsAt: _date(json['current_period_ends_at']),
    willRenew: json['will_renew'] is bool ? json['will_renew'] as bool : null,
    productId: _str(json['product_id']),
    store: _str(json['store']),
    managementUrl: _str(json['management_url']),
  );
}

/// Proposed `data` of GET /history: a list, or `{"items": [...]}`.
/// Each item: `id`, `event`, `product_id`, `store`, `price`,
/// `occurred_at`, `expires_at`.
List<SubscriptionHistoryEntry> subscriptionHistoryFromJson(Object? json) {
  final items = json is Map ? json['items'] : json;
  if (items is! List) return const [];
  return [
    for (final (i, item) in items.indexed)
      if (item is Map)
        SubscriptionHistoryEntry(
          id: '${item['id'] ?? i}',
          event: _str(item['event']) ?? 'unknown',
          productId: _str(item['product_id']),
          store: _str(item['store']),
          price: _str(item['price']),
          occurredAt: _date(item['occurred_at']),
          expiresAt: _date(item['expires_at']),
        ),
  ];
}

/// Proposed `data` of GET /plans: a list, or `{"items": [...]}`.
/// Each item: `id`, `title`, `description`, `product_id`. Prices are not
/// read from here: the store's localized price is the only one shown.
List<SubscriptionPlan> subscriptionPlansFromJson(Object? json) {
  final items = json is Map ? json['items'] : json;
  if (items is! List) return const [];
  return [
    for (final item in items)
      if (item is Map && item['id'] != null)
        SubscriptionPlan(
          id: '${item['id']}',
          title: _str(item['title']),
          description: _str(item['description']),
          productId: _str(item['product_id']),
        ),
  ];
}

/// Proposed POST /sync body. `trigger` tells the backend why the app asks
/// (`purchase`, `restore`, `app_resume`, …); the backend re-reads the
/// subscription from RevenueCat server-side and never trusts the app.
Map<String, Object?> subscriptionSyncBody(String trigger) => {
  'trigger': trigger,
};
