import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/feedback.dart';
import '../../../saved_jobs/presentation/providers/saved_jobs_provider.dart';
import '../providers/application_quota.dart';

/// Five small bars: teal for used applications, amber when all are used.
class QuotaBars extends StatelessWidget {
  const QuotaBars({
    super.key,
    required this.used,
    this.limit = applicationsPerPlan,
    this.barWidth = 16,
    this.barHeight = 5,
  });

  final int used;
  final int limit;
  final double barWidth;
  final double barHeight;

  @override
  Widget build(BuildContext context) {
    final full = used >= limit;
    return ExcludeSemantics(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < limit; i++) ...[
            if (i > 0) const SizedBox(width: 4),
            Container(
              width: barWidth,
              height: barHeight,
              decoration: BoxDecoration(
                color: full
                    ? AppColors.warning
                    : i < used
                    ? AppColors.teal
                    : AppColors.border,
                borderRadius: BorderRadius.circular(barHeight),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// "3 of 5 trial applications left" with the bars, above the Apply button.
class QuotaLine extends StatelessWidget {
  const QuotaLine({super.key, required this.quota});

  final ApplicationQuota quota;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final plan = quota.isPremium ? 'Premium' : 'trial';
    final noun = quota.left == 1 ? 'application' : 'applications';
    return Row(
      children: [
        Expanded(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '${quota.left} of ${quota.limit}',
                  style: TextStyle(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextSpan(text: ' $plan $noun left'),
              ],
            ),
            style: text.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        QuotaBars(used: quota.used),
      ],
    );
  }
}

/// Opens the sheet shown when every application on the plan is used.
Future<void> showQuotaUsedUpSheet(
  BuildContext context, {
  required ApplicationQuota quota,
  required String jobId,
}) => showModalBottomSheet<void>(
  context: context,
  useRootNavigator: true,
  useSafeArea: true,
  isScrollControlled: true,
  builder: (_) => _QuotaUsedUpSheet(quota: quota, jobId: jobId),
);

class _QuotaUsedUpSheet extends ConsumerWidget {
  const _QuotaUsedUpSheet({required this.quota, required this.jobId});

  final ApplicationQuota quota;
  final String jobId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final premium = quota.isPremium;
    final saved = ref.watch(
      savedJobIdsProvider.select((s) => s.contains(jobId)),
    );

    void goPremium() {
      Navigator.of(context).pop();
      context.push(AppRoutes.subscription);
    }

    void save() {
      Navigator.of(context).pop();
      if (saved) return;
      ref.read(savedJobIdsProvider.notifier).toggle(jobId);
      AppFeedback.show(context, 'Saved. You can apply later from Saved.');
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenHorizontal,
        AppSpacing.sm,
        AppSpacing.screenHorizontal,
        AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          QuotaBars(used: quota.limit, barWidth: 34, barHeight: 7),
          const SizedBox(height: AppSpacing.lg),
          Semantics(
            header: true,
            child: Text(
              premium
                  ? 'You\'ve used your ${quota.limit} Premium applications'
                  : 'You\'ve used your ${quota.limit} trial applications',
              style: text.headlineSmall,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            premium
                ? 'Buy Premium again to get ${quota.limit} more applications. '
                      'Your saved jobs and applications stay as they are.'
                : 'Get Premium for ${quota.limit} more applications. '
                      'You can still browse and save jobs for free.',
            style: text.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
          if (!premium) ...[
            const SizedBox(height: AppSpacing.lg),
            for (final perk in const [
              '$applicationsPerPlan more job applications',
              'Every job ranked by your CV',
              'Daily alerts for new matches',
            ])
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle_rounded,
                      size: 18,
                      color: AppColors.teal,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(child: Text(perk, style: text.bodyMedium)),
                  ],
                ),
              ),
          ],
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: goPremium,
              child: Text(premium ? 'Buy Premium again' : 'See Premium'),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: save,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
              ),
              child: Text(saved ? 'Close' : 'Save this job for later'),
            ),
          ),
        ],
      ),
    );
  }
}
