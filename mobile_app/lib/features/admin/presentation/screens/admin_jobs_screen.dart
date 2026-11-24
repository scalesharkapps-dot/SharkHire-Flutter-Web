import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/feedback.dart';
import '../../../../shared/widgets/app_surface.dart';
import '../../../../shared/widgets/company_logo.dart';
import '../../../../shared/widgets/form_fields.dart';
import '../../../../shared/widgets/state_views.dart';
import '../../../../shared/widgets/status_chip.dart';
import '../../data/models/admin_models.dart';
import '../providers/admin_providers.dart';
import '../widgets/admin_widgets.dart';

/// Job moderation (mockup 4.7, on mobile). Approve or reject employer jobs;
/// each action is written to the audit log and the employer is notified.
class AdminJobsScreen extends ConsumerStatefulWidget {
  const AdminJobsScreen({super.key});

  @override
  ConsumerState<AdminJobsScreen> createState() => _AdminJobsScreenState();
}

class _AdminJobsScreenState extends ConsumerState<AdminJobsScreen> {
  JobStatus _tab = JobStatus.pending;

  @override
  Widget build(BuildContext context) {
    final jobs = ref.watch(moderationJobsProvider);
    final shown = jobs.where((j) => j.status == _tab).toList();

    return AdminPage(
      bigTitle: false,
      title: 'Job approvals',
      showBack: false,
      intro:
          'Employer jobs stay Pending until you approve them. Rejected jobs go back with your reason.',
      children: [
        ChoiceChipGroup<JobStatus>(
          options: const [
            JobStatus.pending,
            JobStatus.approved,
            JobStatus.rejected,
          ],
          selected: {_tab},
          multiSelect: false,
          labelOf: (s) =>
              '${s == JobStatus.pending ? 'Pending' : s.label} (${jobs.where((j) => j.status == s).length})',
          onChanged: (s) => setState(() => _tab = s.first),
        ),
        if (shown.isEmpty)
          EmptyStateView(
            compact: true,
            icon: Icons.task_alt_rounded,
            title: _tab == JobStatus.pending ? 'All caught up' : 'Nothing here',
            message: _tab == JobStatus.pending
                ? 'No jobs are waiting for approval.'
                : 'No ${_tab.label.toLowerCase()} jobs.',
          )
        else
          for (final j in shown) ModerationJobCard(job: j),
      ],
    );
  }
}

/// A job awaiting (or after) moderation, with Approve / Reject actions.
class ModerationJobCard extends ConsumerWidget {
  const ModerationJobCard({super.key, required this.job});

  final ModerationJob job;

  Future<void> _reject(BuildContext context, WidgetRef ref) async {
    final notifier = ref.read(moderationJobsProvider.notifier);
    final reason = await askForReason(
      context,
      title: 'Reject "${job.title}"?',
      hint: 'Tell the employer what to change, e.g. add a salary range',
      action: 'Reject job',
    );
    if (reason == null) return;
    notifier.reject(job.id, reason);
    if (context.mounted) {
      AppFeedback.show(
        context,
        '"${job.title}" rejected. The employer can see your reason.',
      );
    }
  }

  void _approve(BuildContext context, WidgetRef ref) {
    ref.read(moderationJobsProvider.notifier).approve(job.id);
    AppFeedback.show(context, '"${job.title}" approved and published.');
  }

  Future<void> _details(
    BuildContext context,
    WidgetRef ref,
  ) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    builder: (sheet) {
      final text = Theme.of(sheet).textTheme;
      return SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenHorizontal,
            0,
            AppSpacing.screenHorizontal,
            AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(job.title, style: text.headlineSmall),
              const SizedBox(height: 4),
              Text('${job.company} · ${job.location}', style: text.bodyMedium),
              Text(
                '${job.employmentType.label} · ${job.workMode.label}'
                '${job.salaryLabel == null ? ' · No salary given' : ' · ${job.salaryLabel}'}',
                style: text.bodySmall,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                job.description.isEmpty
                    ? 'No description provided.'
                    : job.description,
                style: text.bodyLarge,
              ),
              if (job.skills.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.lg),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    for (final s in job.skills)
                      InfoPill(label: s, bordered: true),
                  ],
                ),
              ],
              if (job.rejectionReason != null) ...[
                const SizedBox(height: AppSpacing.lg),
                InlineBanner(
                  tone: BannerTone.error,
                  title: 'Rejection reason',
                  message: job.rejectionReason!,
                ),
              ],
              if (job.status == JobStatus.pending) ...[
                const SizedBox(height: AppSpacing.xl),
                FilledButton(
                  onPressed: () {
                    Navigator.of(sheet).pop();
                    _approve(context, ref);
                  },
                  child: const Text('Approve and publish'),
                ),
                const SizedBox(height: AppSpacing.sm),
                OutlinedButton(
                  onPressed: () {
                    Navigator.of(sheet).pop();
                    _reject(context, ref);
                  },
                  child: const Text('Reject'),
                ),
              ],
            ],
          ),
        ),
      );
    },
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    return AppSurface(
      onTap: () => _details(context, ref),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CompanyLogo(name: job.company, size: 40),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(job.title, style: text.titleSmall),
                    Text(
                      '${job.company} · ${formatAgo(job.submittedAt)}',
                      style: text.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    StatusChip.job(job.status),
                  ],
                ),
              ),
            ],
          ),
          if (job.salaryLabel == null && job.status == JobStatus.pending) ...[
            const SizedBox(height: AppSpacing.md),
            const InlineBanner(
              tone: BannerTone.warning,
              message: 'No salary range given.',
            ),
          ],
          if (job.status == JobStatus.pending) ...[
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      minimumSize: const Size(0, 44),
                    ),
                    onPressed: () => _reject(context, ref),
                    child: const Text('Reject'),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 44),
                    ),
                    onPressed: () => _approve(context, ref),
                    child: const Text('Approve'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
