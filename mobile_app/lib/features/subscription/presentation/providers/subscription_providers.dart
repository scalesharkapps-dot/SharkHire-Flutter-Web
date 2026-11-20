import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/network/api_exception.dart';
import '../../../authentication/domain/session.dart';
import '../../../authentication/presentation/providers/session_provider.dart';
import '../../data/billing_service.dart';
import '../../data/subscription_repository.dart';
import '../../domain/subscription_status.dart';

/// Whether paid access is enforced (the paywall guard and automatic status
/// checks). Overridden in tests.
final subscriptionsEnabledProvider = Provider<bool>(
  (ref) => AppConfig.subscriptionsEnabled,
);

/// The user whose subscription matters: a signed-in, set-up job seeker.
/// Employers and admins are not asked to subscribe.
@immutable
class SubscriberIdentity {
  const SubscriberIdentity({required this.userId, required this.email});

  /// Backend (Supabase) user ID; the RevenueCat App User ID.
  final String userId;
  final String email;

  @override
  bool operator ==(Object other) =>
      other is SubscriberIdentity &&
      other.userId == userId &&
      other.email == email;

  @override
  int get hashCode => Object.hash(userId, email);
}

SubscriberIdentity? subscriberOf(Session s) {
  final user = s.user;
  if (user == null || s.stage != SessionStage.ready) return null;
  if (s.isEmployer || s.isAdmin) return null;
  return SubscriberIdentity(userId: user.id, email: user.email);
}

/// Result of a purchase or restore, for the paywall to show.
@immutable
class SubscriptionFeedback {
  const SubscriptionFeedback(this.message, {this.isError = false});
  final String? message;
  final bool isError;
}

const confirmingPurchaseMessage =
    'Your payment went through. We\'re confirming it with the store, which '
    'can take a minute. Tap "Check again" if access doesn\'t unlock.';

/// App-access status from the backend, for the signed-in job seeker.
///
/// The status is refreshed on sign-in / registration (the session
/// changes), on app resume, and after purchase, restore and sync. It is
/// never computed on the device: only backend answers change it.
class SubscriptionController extends Notifier<SubscriptionStatus> {
  SubscriptionRepository get _repo => ref.read(subscriptionRepositoryProvider);
  BillingService get _billing => ref.read(billingServiceProvider);

  SubscriberIdentity? _subscriber;
  String? _billingUserId;
  int _generation = 0;
  bool _busy = false;

  /// A purchase or restore is running.
  bool get isBusy => _busy;

  @override
  SubscriptionStatus build() {
    final subscriber = ref.watch(sessionProvider.select(subscriberOf));
    _subscriber = subscriber;
    _generation++;
    Future.microtask(() => _identifyBilling(subscriber));
    if (subscriber != null && ref.read(subscriptionsEnabledProvider)) {
      Future.microtask(() => refresh(trigger: 'sign_in'));
    }
    return SubscriptionStatus.loading;
  }

  /// RevenueCat follows the signed-in user (logIn / logOut).
  Future<void> _identifyBilling(SubscriberIdentity? subscriber) async {
    final id = subscriber?.userId;
    if (id == _billingUserId) return;
    try {
      if (id == null || id.isEmpty) {
        if (_billingUserId != null) await _billing.logOut();
        _billingUserId = null;
      } else {
        await _billing.logIn(id);
        _billingUserId = id;
      }
    } catch (e) {
      debugPrint('Billing identify failed: $e');
    }
  }

  /// Loads the status once if it hasn't been loaded (screens call this).
  Future<void> ensureLoaded() async {
    if (state.isLoading || state.state == AccessState.error) await refresh();
  }

  /// Fetches the status from the backend. While refreshing, a known status
  /// stays on screen so resuming the app doesn't flash the paywall.
  Future<void> refresh({String trigger = 'manual'}) async {
    if (_subscriber == null) return;
    final gen = _generation;
    if (state.state == AccessState.error) state = SubscriptionStatus.loading;
    final next = await _load(() => _repo.fetchStatus());
    if (ref.mounted && gen == _generation) state = next;
  }

  Future<SubscriptionStatus> _load(
    Future<SubscriptionStatus> Function() request,
  ) async {
    try {
      return await request();
    } on FeatureUnavailableException catch (e) {
      return SubscriptionStatus.failure(e.message, serviceUnavailable: true);
    } catch (e) {
      return SubscriptionStatus.failure(friendlyErrorMessage(e));
    }
  }

  /// Buys [package] in the store, then asks the backend to verify it.
  /// Access changes only through the backend's answer.
  Future<SubscriptionFeedback> purchase(BillingPackage package) async {
    if (_busy || _subscriber == null) return const SubscriptionFeedback(null);
    _busy = true;
    final gen = _generation;
    try {
      final attempt = await _billing.purchase(package);
      switch (attempt.outcome) {
        case PurchaseOutcome.cancelled:
          return const SubscriptionFeedback(null);
        case PurchaseOutcome.pending:
          return SubscriptionFeedback(attempt.message);
        case PurchaseOutcome.failed:
          return SubscriptionFeedback(attempt.message, isError: true);
        case PurchaseOutcome.success:
          final next = await _load(() => _repo.sync(trigger: 'purchase'));
          if (!ref.mounted || gen != _generation) {
            return const SubscriptionFeedback(null);
          }
          if (next.state != AccessState.error) state = next;
          return next.isPaid
              ? const SubscriptionFeedback('You\'re subscribed. Welcome!')
              : const SubscriptionFeedback(confirmingPurchaseMessage);
      }
    } finally {
      _busy = false;
    }
  }

  /// Restores purchases from the store, then lets the backend decide.
  Future<SubscriptionFeedback> restore() async {
    if (_busy || _subscriber == null) return const SubscriptionFeedback(null);
    _busy = true;
    final gen = _generation;
    try {
      if (_billing.isAvailable) {
        try {
          await _billing.restore();
        } on PlatformException catch (e) {
          debugPrint('Store restore failed: $e');
          return const SubscriptionFeedback(
            'We couldn\'t reach the store. Please try again.',
            isError: true,
          );
        }
      }
      final next = await _load(() => _repo.restore());
      if (!ref.mounted || gen != _generation) {
        return const SubscriptionFeedback(null);
      }
      if (next.state == AccessState.error) {
        return SubscriptionFeedback(next.message, isError: true);
      }
      state = next;
      return next.isPaid
          ? const SubscriptionFeedback('Your subscription has been restored.')
          : const SubscriptionFeedback(
              'No active subscription was found for this account.',
            );
    } finally {
      _busy = false;
    }
  }

  /// Asks the backend to re-check with the store ("Check again").
  Future<void> sync() async {
    if (_subscriber == null) return;
    final gen = _generation;
    final next = await _load(() => _repo.sync(trigger: 'manual'));
    if (ref.mounted && gen == _generation) state = next;
  }
}

final subscriptionProvider =
    NotifierProvider<SubscriptionController, SubscriptionStatus>(
      SubscriptionController.new,
    );

/// Packages of the `default` offering, with store prices.
final billingPackagesProvider =
    FutureProvider.autoDispose<List<BillingPackage>>(
      (ref) => ref.watch(billingServiceProvider).fetchPackages(),
    );

final subscriptionHistoryProvider =
    FutureProvider.autoDispose<List<SubscriptionHistoryEntry>>(
      (ref) => ref.watch(subscriptionRepositoryProvider).fetchHistory(),
    );
