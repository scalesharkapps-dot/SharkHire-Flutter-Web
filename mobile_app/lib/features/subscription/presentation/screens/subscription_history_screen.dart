import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_surface.dart';
import '../../../../shared/widgets/state_views.dart';
import '../../domain/subscription_status.dart';
import '../providers/subscription_providers.dart';

/// Billing history from `GET /api/v1/subscriptions/history`.
class SubscriptionHistoryScreen extends ConsumerWidget {
  const SubscriptionHistoryScreen({super.key});

  static String eventLabel(String event) => switch (event) {
    'trial_started' => 'Free trial started',
    'initial_purchase' => 'Subscribed',
    'renewal' => 'Renewed',
    'cancellation' => 'Cancelled',
    'uncancellation' => 'Resubscribed',
    'expiration' => 'Ended',
    'billing_issue' => 'Payment problem',
    'product_change' => 'Plan changed',
    'refund' => 'Refunded',
    _ => event.replaceAll('_', ' '),
  };

  static String _date(DateTime d) {
    final l = d.toLocal();
    const m = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${l.day} ${m[l.month - 1]} ${l.year}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final history = ref.watch(subscriptionHistoryProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Billing history')),
      body: history.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => e is FeatureUnavailableException
            ? EmptyStateView(
                icon: Icons.receipt_long_outlined,
                title: 'Not available yet',
                message: e.message,
              )
            : ErrorStateView(
                message: friendlyErrorMessage(e),
                onRetry: () => ref.invalidate(subscriptionHistoryProvider),
              ),
        data: (items) => items.isEmpty
            ? const EmptyStateView(
                icon: Icons.receipt_long_outlined,
                title: 'No billing history',
                message: 'Your trial and payments will appear here.',
              )
            : ListView.separated(
                padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
                itemCount: items.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: AppSpacing.sm),
                itemBuilder: (_, i) => _Entry(
                  entry: items[i],
                  label: eventLabel(items[i].event),
                  date: _date,
                  text: text,
                ),
              ),
      ),
    );
  }
}

class _Entry extends StatelessWidget {
  const _Entry({
    required this.entry,
    required this.label,
    required this.date,
    required this.text,
  });

  final SubscriptionHistoryEntry entry;
  final String label;
  final String Function(DateTime) date;
  final TextTheme text;

  @override
  Widget build(BuildContext context) {
    final details = [
      if (entry.occurredAt != null) date(entry.occurredAt!),
      if (entry.expiresAt != null) 'until ${date(entry.expiresAt!)}',
      if (entry.store == 'play_store') 'Google Play',
      if (entry.store == 'app_store') 'App Store',
    ].join(' · ');
    return AppSurface(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: text.titleSmall),
                if (details.isNotEmpty)
                  Text(
                    details,
                    style: text.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          if (entry.price != null) Text(entry.price!, style: text.titleSmall),
        ],
      ),
    );
  }
}
