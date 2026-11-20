import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_surface.dart';
import '../../domain/subscription_status.dart';
import '../providers/subscription_providers.dart';

/// "N days left in your free trial" (or a payment problem) on Home. The
/// days come from the backend's trial end date, so signing out and in
/// again never restarts the trial. Hidden when subscriptions are off.
class TrialBanner extends ConsumerWidget {
  const TrialBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(subscriptionsEnabledProvider)) {
      return const SizedBox.shrink();
    }
    final status = ref.watch(subscriptionProvider);
    final text = Theme.of(context).textTheme;
    final String message;
    final IconData icon;
    switch (status.state) {
      case AccessState.trialActive:
        final days = status.trialDaysLeft();
        message = days == null
            ? 'You\'re on your free trial'
            : days == 0
            ? 'Your free trial ends today'
            : '$days ${days == 1 ? 'day' : 'days'} left in your free trial';
        icon = Icons.hourglass_bottom_rounded;
      case AccessState.billingIssue:
        message = 'There\'s a problem with your payment';
        icon = Icons.error_outline_rounded;
      default:
        return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenHorizontal,
        AppSpacing.xl,
        AppSpacing.screenHorizontal,
        0,
      ),
      child: AppSurface(
        onTap: () => context.push(AppRoutes.subscription),
        child: Row(
          children: [
            Icon(icon, color: AppColors.ocean),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: Text(message, style: text.titleSmall)),
            Text(
              status.state == AccessState.billingIssue ? 'Fix' : 'Subscribe',
              style: text.labelLarge?.copyWith(color: AppColors.ocean),
            ),
          ],
        ),
      ),
    );
  }
}

/// Re-checks the subscription when the app returns to the foreground
/// (e.g. after the user subscribed or cancelled in store settings).
class SubscriptionResumeRefresher extends ConsumerStatefulWidget {
  const SubscriptionResumeRefresher({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<SubscriptionResumeRefresher> createState() =>
      _SubscriptionResumeRefresherState();
}

class _SubscriptionResumeRefresherState
    extends ConsumerState<SubscriptionResumeRefresher> {
  late final AppLifecycleListener _listener;

  @override
  void initState() {
    super.initState();
    _listener = AppLifecycleListener(
      onResume: () {
        if (ref.read(subscriptionsEnabledProvider)) {
          ref
              .read(subscriptionProvider.notifier)
              .refresh(trigger: 'app_resume');
        }
      },
    );
  }

  @override
  void dispose() {
    _listener.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
