import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_config.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/http_api_client.dart';
import '../domain/subscription_status.dart';
import 'subscription_json.dart';

/// Backend subscription API. The backend is the only source of truth for
/// app access: it verifies purchases with RevenueCat server-side.
abstract interface class SubscriptionRepository {
  Future<SubscriptionStatus> fetchStatus();

  /// Asks the backend to re-read the subscription from RevenueCat (after a
  /// purchase, restore, or app resume) and returns the result.
  Future<SubscriptionStatus> sync({required String trigger});

  Future<SubscriptionStatus> restore();
  Future<List<SubscriptionHistoryEntry>> fetchHistory();
  Future<List<SubscriptionPlan>> fetchPlans();
}

/// Message when the backend has not shipped the subscription API yet.
const subscriptionServiceUnavailableMessage =
    'Subscriptions aren\'t available yet. Please check again soon.';

class ApiSubscriptionRepository implements SubscriptionRepository {
  ApiSubscriptionRepository(this._api);
  final ApiClient _api;

  /// 404 means the endpoint doesn't exist on this backend yet: an
  /// integration dependency, never "no subscription".
  Future<Object?> _call(Future<Object?> Function() request) async {
    try {
      return await request();
    } on NotFoundException {
      throw const FeatureUnavailableException(
        subscriptionServiceUnavailableMessage,
      );
    }
  }

  @override
  Future<SubscriptionStatus> fetchStatus() async => subscriptionStatusFromJson(
    await _call(() => _api.get(ApiEndpoints.subscriptionStatus)),
  );

  @override
  Future<SubscriptionStatus> sync({required String trigger}) async =>
      subscriptionStatusFromJson(
        await _call(
          () => _api.post(
            ApiEndpoints.subscriptionSync,
            body: subscriptionSyncBody(trigger),
          ),
        ),
      );

  @override
  Future<SubscriptionStatus> restore() async => subscriptionStatusFromJson(
    await _call(() => _api.post(ApiEndpoints.subscriptionRestore)),
  );

  @override
  Future<List<SubscriptionHistoryEntry>> fetchHistory() async =>
      subscriptionHistoryFromJson(
        await _call(() => _api.get(ApiEndpoints.subscriptionHistory)),
      );

  @override
  Future<List<SubscriptionPlan>> fetchPlans() async =>
      subscriptionPlansFromJson(
        await _call(() => _api.get(ApiEndpoints.subscriptionPlans)),
      );
}

/// Development-only stand-in for the backend (`USE_MOCK_DATA`, never in
/// production: the startup config check refuses mock data there). It acts
/// like the proposed backend: a 3-day trial from the first check, and
/// access after a purchase made with the demo billing service.
class MockSubscriptionRepository implements SubscriptionRepository {
  MockSubscriptionRepository({DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final DateTime Function() _clock;
  DateTime? _trialEndsAt;
  final List<SubscriptionHistoryEntry> _history = [];

  /// Set by the demo billing service when a demo purchase completes.
  bool demoPurchaseMade = false;

  @override
  Future<SubscriptionStatus> fetchStatus() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return _status();
  }

  SubscriptionStatus _status() {
    final now = _clock();
    if (_trialEndsAt == null) {
      _trialEndsAt = now.add(const Duration(days: AppConstants.freeTrialDays));
      _history.add(
        SubscriptionHistoryEntry(
          id: 'trial',
          event: 'trial_started',
          occurredAt: now,
          expiresAt: _trialEndsAt,
        ),
      );
    }
    if (demoPurchaseMade) {
      return SubscriptionStatus(
        state: AccessState.subscriptionActive,
        currentPeriodEndsAt: now.add(const Duration(days: 30)),
        willRenew: true,
        productId: 'demo_monthly',
        store: 'demo',
      );
    }
    return _trialEndsAt!.isAfter(now)
        ? SubscriptionStatus(
            state: AccessState.trialActive,
            trialEndsAt: _trialEndsAt,
          )
        : const SubscriptionStatus(state: AccessState.paymentRequired);
  }

  @override
  Future<SubscriptionStatus> sync({required String trigger}) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (trigger == 'purchase' &&
        demoPurchaseMade &&
        !_history.any((e) => e.event == 'initial_purchase')) {
      _history.add(
        SubscriptionHistoryEntry(
          id: 'p1',
          event: 'initial_purchase',
          productId: 'demo_monthly',
          store: 'demo',
          occurredAt: _clock(),
          expiresAt: _clock().add(const Duration(days: 30)),
        ),
      );
    }
    return _status();
  }

  @override
  Future<SubscriptionStatus> restore() => sync(trigger: 'restore');

  @override
  Future<List<SubscriptionHistoryEntry>> fetchHistory() async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return _history.reversed.toList();
  }

  @override
  Future<List<SubscriptionPlan>> fetchPlans() async => const [
    SubscriptionPlan(id: 'monthly', title: 'SharkHire monthly'),
  ];
}

final subscriptionRepositoryProvider = Provider<SubscriptionRepository>(
  (ref) => ApiConfig.isConfigured
      ? ApiSubscriptionRepository(ref.watch(apiClientProvider))
      : MockSubscriptionRepository(),
);
