import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/date_formatters.dart';
import '../../../../shared/models/domain_enums.dart';
import '../../../../shared/widgets/app_surface.dart';
import '../../../../shared/widgets/fade_in_up.dart';
import '../../../../shared/widgets/person_avatar.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../../../shared/widgets/state_views.dart';
import '../../../../shared/widgets/status_chip.dart';
import '../../../profile/presentation/providers/current_user_provider.dart';
import '../../data/models/employer_models.dart';
import '../providers/employer_providers.dart';

/// Employer overview (mockup 4.5): counts, recent applications and jobs
/// that need attention.
class EmployerOverviewScreen extends ConsumerWidget {
  const EmployerOverviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final jobs = ref.watch(employerJobsProvider);
    final applicants = ref.watch(applicantsProvider);
    final company = ref.watch(companyProvider);
    final user = ref.watch(currentUserProvider);

    final active = jobs.where((j) => j.status == JobStatus.approved).length;
    final pending = jobs.where((j) => j.status == JobStatus.pending).length;
    final shortlisted = applicants
        .where((a) => a.status == ApplicationStatus.shortlisted)
        .length;
    final recent = [...applicants]
      ..sort((a, b) => b.appliedAt.compareTo(a.appliedAt));
    final attention = jobs
        .where(
          (j) =>
              j.status == JobStatus.rejected || j.status == JobStatus.pending,
        )
        .toList();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        body: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Container(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.screenHorizontal,
                  MediaQuery.paddingOf(context).top + AppSpacing.lg,
                  AppSpacing.screenHorizontal,
                  AppSpacing.xxl,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  border: Border(bottom: BorderSide(color: AppColors.border)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'EMPLOYER DASHBOARD',
                      style: text.labelSmall?.copyWith(
                        color: AppColors.ocean,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Hello, ${user.firstName}',
                      style: text.headlineMedium,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            company.name,
                            style: text.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Icon(
                          company.verification == VerificationStatus.verified
                              ? Icons.verified_rounded
                              : Icons.hourglass_top_rounded,
                          size: 16,
                          color:
                              company.verification ==
                                  VerificationStatus.verified
                              ? AppColors.ocean
                              : AppColors.textTertiary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          company.verification == VerificationStatus.verified
                              ? 'Verified'
                              : 'Verification pending',
                          style: text.bodySmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    GridView.count(
                      crossAxisCount: 2,
                      // GridView adds the status-bar inset by default.
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: AppSpacing.sm,
                      crossAxisSpacing: AppSpacing.sm,
                      childAspectRatio: 2.2,
                      children: [
                        _Stat(
                          value: active,
                          label: 'Active jobs',
                          onTap: () => context.go(AppRoutes.employerJobs),
                        ),
                        _Stat(
                          value: pending,
                          label: 'Pending approval',
                          onTap: () => context.go(AppRoutes.employerJobs),
                        ),
                        _Stat(
                          value: applicants.length,
                          label: 'Applicants',
                          onTap: () => context.go(AppRoutes.employerApplicants),
                        ),
                        _Stat(
                          value: shortlisted,
                          label: 'Shortlisted',
                          onTap: () => context.go(AppRoutes.employerApplicants),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () => context.push(AppRoutes.employerNewJob),
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Post a job'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (attention.isNotEmpty) ...[
              _padded(const SectionHeader(title: 'Needs attention')),
              SliverPadding(
                padding: AppSpacing.screenPadding,
                sliver: SliverToBoxAdapter(
                  child: _RowGroup(
                    children: [
                      for (final j in attention) _AttentionRow(job: j),
                    ],
                  ),
                ),
              ),
            ],
            _padded(
              SectionHeader(
                title: 'Recent applications',
                actionLabel: 'See all',
                onAction: () => context.go(AppRoutes.employerApplicants),
              ),
            ),
            if (recent.isEmpty)
              const SliverToBoxAdapter(
                child: EmptyStateView(
                  compact: true,
                  icon: Icons.groups_outlined,
                  title: 'No applications yet',
                  message:
                      'When candidates apply to your published jobs, they\'ll appear here.',
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenHorizontal,
                  0,
                  AppSpacing.screenHorizontal,
                  AppSpacing.xxxl,
                ),
                sliver: SliverToBoxAdapter(
                  child: FadeInUp(
                    child: _RowGroup(
                      children: [
                        for (final a in recent.take(4))
                          _RecentRow(applicant: a),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  static Widget _padded(Widget child) => SliverPadding(
    padding: const EdgeInsets.fromLTRB(
      AppSpacing.screenHorizontal,
      AppSpacing.xxl,
      AppSpacing.sm,
      AppSpacing.md,
    ),
    sliver: SliverToBoxAdapter(child: child),
  );
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label, this.onTap});

  final int value;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Material(
      color: AppColors.surfaceSubtle,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.lgAll,
        side: BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.lgAll,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$value',
                style: text.headlineSmall?.copyWith(
                  height: 1.1,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: text.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One card of plain rows with hairline dividers.
class _RowGroup extends StatelessWidget {
  const _RowGroup({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => AppSurface(
    elevated: false,
    padding: EdgeInsets.zero,
    child: Column(
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) const Divider(height: 1, indent: AppSpacing.lg),
          children[i],
        ],
      ],
    ),
  );
}

class _PlainRow extends StatelessWidget {
  const _PlainRow({
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.subtitleColor,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color? subtitleColor;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          12,
          AppSpacing.sm,
          12,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: text.titleSmall),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: text.bodySmall?.copyWith(
                      color: subtitleColor ?? AppColors.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary),
          ],
        ),
      ),
    );
  }
}

class _AttentionRow extends StatelessWidget {
  const _AttentionRow({required this.job});

  final EmployerJob job;

  @override
  Widget build(BuildContext context) {
    final rejected = job.status == JobStatus.rejected;
    return _PlainRow(
      title: job.title,
      subtitle: rejected
          ? (job.rejectionReason ?? 'Rejected by admin')
          : 'Waiting for admin approval',
      subtitleColor: rejected ? AppColors.error : null,
      onTap: () => context.push(AppRoutes.employerEditJob(job.id)),
    );
  }
}

class _RecentRow extends StatelessWidget {
  const _RecentRow({required this.applicant});

  final Applicant applicant;

  @override
  Widget build(BuildContext context) {
    final a = applicant;
    final age = DateFormatters.relativeAge(a.appliedAt);
    return _PlainRow(
      title: a.name,
      subtitle: '${a.jobTitle} · ${age == 'Just now' ? age : '$age ago'}',
      onTap: () => context.push(AppRoutes.employerCandidate(a.id)),
    );
  }
}

/// Applicant summary row used on Overview and Applicants.
class ApplicantRow extends StatelessWidget {
  const ApplicantRow({super.key, required this.applicant});

  final Applicant applicant;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final a = applicant;
    final age = DateFormatters.relativeAge(a.appliedAt);
    return AppSurface(
      onTap: () => context.push(AppRoutes.employerCandidate(a.id)),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          PersonAvatar(initials: a.initials),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(a.name, style: text.titleSmall),
                Text(
                  '${a.jobTitle} · ${age == 'Just now' ? age : '$age ago'}',
                  style: text.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          StatusChip(
            label: a.status == ApplicationStatus.submitted
                ? 'New'
                : a.status.label,
            tone: toneOfApplication(a.status),
          ),
        ],
      ),
    );
  }
}
