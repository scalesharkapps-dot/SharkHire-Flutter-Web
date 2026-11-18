import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';

/// Mirrors `subscriptions.status` (guide §3.8).
enum SubscriptionStatus { none, trial, active, expired, cancelled }

@immutable
class SubscriptionState {
  const SubscriptionState({
    this.status = SubscriptionStatus.none,
    this.renewsOrEndsAt,
  });

  final SubscriptionStatus status;
  final DateTime? renewsOrEndsAt;

  bool get hasPremium =>
      status == SubscriptionStatus.trial || status == SubscriptionStatus.active;
}

class RestoreResult {
  const RestoreResult(this.restored);
  final bool restored;
}

/// Subscription state as reported by the backend.
///
/// Purchases go through Google Play Billing / Apple In-App Purchase and the
/// backend verifies them before granting premium (guide §3.8). The app never
/// decides `isPremium` on its own – it shows what the server confirms.
/// This mock simulates that round trip.
class SubscriptionController extends Notifier<SubscriptionState> {
  @override
  SubscriptionState build() => const SubscriptionState();

  Future<void> startTrial() async {
    await Future<void>.delayed(const Duration(milliseconds: 900));
    state = SubscriptionState(
      status: SubscriptionStatus.trial,
      renewsOrEndsAt: DateTime.now().add(
        const Duration(days: AppConstants.freeTrialDays),
      ),
    );
  }

  Future<RestoreResult> restorePurchases() async {
    await Future<void>.delayed(const Duration(milliseconds: 900));
    return const RestoreResult(false);
  }
}

final subscriptionProvider =
    NotifierProvider<SubscriptionController, SubscriptionState>(
      SubscriptionController.new,
    );
