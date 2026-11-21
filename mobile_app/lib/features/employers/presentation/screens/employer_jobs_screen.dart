import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/feedback.dart';
import '../../../../shared/models/domain_enums.dart';
import '../../../../shared/widgets/app_surface.dart';
import '../../../../shared/widgets/fade_in_up.dart';
import '../../../../shared/widgets/form_fields.dart';
import '../../../../shared/widgets/state_views.dart';
import '../../../../shared/widgets/status_chip.dart';
import '../../data/models/employer_models.dart';
import '../providers/employer_providers.dart';

/// Manage jobs by status: Pending, Published, Rejected, Closed (mockup 4.5).
class EmployerJobsScreen extends ConsumerStatefulWidget {
  const EmployerJobsScreen({super.key});

  @override
  ConsumerState<EmployerJobsScreen> createState() => _EmployerJobsScreenState();
}

class _EmployerJobsScreenState extends ConsumerState<EmployerJobsScreen> {
  static const _tabs = [
    JobStatus.pending,
    JobStatus.approved,
    JobStatus.rejected,
    JobStatus.closed,
  ];
  JobStatus? _filter;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final jobs = ref.watch(employerJobsProvider);
    final applicants = ref.watch(applicantsProvider);
    final shown = _filter == null
        ? jobs
        : jobs.where((j) => j.status == _filter).toList();

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.employerNewJob),
        backgroundColor: AppColors.ink,
        foregroundColor: AppColors.onInk,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Create job'),
      ),
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenHorizontal,
            AppSpacing.lg,
            AppSpacing.screenHorizontal,
            96,
          ),
          children: [
            Text('Manage jobs', style: text.headlineMedium),
            const SizedBox(height: 2),
            Text(
              'New and edited jobs are reviewed by SharkHire before they go live.',
              style: text.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.lg),
            ChoiceChipGroup<JobStatus?>(
              options: [null, ..._tabs],
              selected: {_filter},
              multiSelect: false,
              labelOf: (s) {
                final n = s == null
                    ? jobs.length
                    : jobs.where((j) => j.status == s).length;
                return '${s == null ? 'All' : s.label} ($n)';
              },
              onChanged: (s) => setState(() => _filter = s.first),
            ),
            const SizedBox(height: AppSpacing.lg),
            if (shown.isEmpty)
              EmptyStateView(
                compact: true,
                icon: Icons.work_outline_rounded,
                title: 'No jobs here',
                message: _filter == null
                    ? 'Create your first job post to start receiving applications.'
                    : 'You have no ${_filter!.label.toLowerCase()} jobs.',
              )
            else
              for (var i = 0; i < shown.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: FadeInUp(
                    delay: Duration(milliseconds: 40 * i.clamp(0, 6)),
                    child: _JobCard(
                      job: shown[i],
                      applicants: applicants
                          .where((a) => a.jobId == shown[i].id)
                          .length,
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

class _JobCard extends ConsumerWidget {
  const _JobCard({required this.job, required this.applicants});

  final EmployerJob job;
  final int applicants;

  Future<void> _close(BuildContext context, WidgetRef ref) async {
    final ok = await showModalBottomSheet<bool>(
      context: context,
      useRootNavigator: true,
      builder: (sheet) => SafeArea(
        child: Padding(
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
              Text(
                'Close "${job.title}"?',
                style: Theme.of(sheet).textTheme.headlineSmall,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'It stops accepting applications. Existing applicants stay in your list.',
                style: Theme.of(sheet).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              FilledButton(
                onPressed: () => Navigator.of(sheet).pop(true),
                child: const Text('Close job'),
              ),
              TextButton(
                onPressed: () => Navigator.of(sheet).pop(false),
                child: const Text('Cancel'),
              ),
            ],
          ),
        ),
      ),
    );
    if (ok ?? false) {
      ref.read(employerJobsProvider.notifier).close(job.id);
      if (context.mounted) AppFeedback.show(context, 'Job closed');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final canEdit = job.status != JobStatus.closed;
    return AppSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(job.title, style: text.titleMedium),
                    const SizedBox(height: 2),
                    Text(
                      '${job.location} · ${job.workMode.label} · ${job.vacancies} '
                      '${job.vacancies == 1 ? 'vacancy' : 'vacancies'}',
                      style: text.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              StatusChip.job(job.status),
            ],
          ),
          if (job.status == JobStatus.rejected &&
              job.rejectionReason != null) ...[
            const SizedBox(height: AppSpacing.md),
            InlineBanner(tone: BannerTone.error, message: job.rejectionReason!),
          ],
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: 4,
            children: [
              _Stat(
                icon: Icons.groups_outlined,
                label: '$applicants applicants',
              ),
              _Stat(
                icon: Icons.visibility_outlined,
                label: '${job.views} views',
              ),
            ],
          ),
          if (canEdit) ...[
            const SizedBox(height: AppSpacing.sm),
            const Divider(),
            Wrap(
              alignment: WrapAlignment.end,
              children: [
                if (job.status == JobStatus.approved ||
                    job.status == JobStatus.pending)
                  TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                    ),
                    onPressed: () => _close(context, ref),
                    child: const Text('Close'),
                  ),
                TextButton(
                  onPressed: () =>
                      context.push(AppRoutes.employerEditJob(job.id)),
                  child: Text(
                    job.status == JobStatus.rejected
                        ? 'Fix & resubmit'
                        : 'Edit',
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

class _Stat extends StatelessWidget {
  const _Stat({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 16, color: AppColors.textTertiary),
      const SizedBox(width: 4),
      Text(label, style: Theme.of(context).textTheme.bodySmall),
    ],
  );
}
