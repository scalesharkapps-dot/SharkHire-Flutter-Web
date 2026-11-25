import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../applications/presentation/providers/applications_provider.dart';
import '../../domain/subscription_status.dart';
import 'subscription_providers.dart';

/// Applications included in the free trial and in each Premium purchase.
const applicationsPerPlan = 5;

/// How many in-app applications are left on the current plan.
@immutable
class ApplicationQuota {
  const ApplicationQuota({required this.used, required this.isPremium});

  final int used;
  final bool isPremium;

  int get limit => applicationsPerPlan;
  int get left => (limit - used).clamp(0, limit);
  bool get isUsedUp => left == 0;
}

/// History events that start a fresh set of Premium applications.
const _purchaseEvents = {'initial_purchase', 'renewal', 'purchase'};

/// The user's application allowance, or `null` when it doesn't apply
/// (status unknown, no plan, or the Premium purchase date isn't known).
///
/// Counted in the app from the user's own applications: every in-app
/// application during the trial, and those since the latest purchase on
/// Premium. Withdrawn applications still count.
final applicationQuotaProvider = Provider.autoDispose<ApplicationQuota?>((ref) {
  final status = ref.watch(subscriptionProvider);
  final apps = ref.watch(applicationsProvider);

  if (status.state == AccessState.trialActive) {
    return ApplicationQuota(used: apps.length, isPremium: false);
  }
  if (!status.isPaid) return null;

  final history = ref.watch(subscriptionHistoryProvider).value;
  final since = history
      ?.where((e) => _purchaseEvents.contains(e.event) && e.occurredAt != null)
      .map((e) => e.occurredAt!)
      .fold<DateTime?>(
        null,
        (latest, at) => latest == null || at.isAfter(latest) ? at : latest,
      );
  // Without a purchase date we can't count fairly, so we don't limit.
  if (since == null) return null;
  final used = apps.where((a) => !a.submittedAt.isBefore(since)).length;
  return ApplicationQuota(used: used, isPremium: true);
});
