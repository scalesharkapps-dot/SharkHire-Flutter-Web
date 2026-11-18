import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_surface.dart';
import '../../../../shared/widgets/form_fields.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../../profile/presentation/providers/current_user_provider.dart';
import '../../data/models/admin_models.dart';
import '../providers/admin_providers.dart';
import '../widgets/admin_widgets.dart';
import 'admin_jobs_screen.dart' show ModerationJobCard;

/// Admin overview (mockup 4.6, on mobile): totals, pending approvals,
/// JSearch usage against the plan limit and recent activity.
class AdminOverviewScreen extends ConsumerWidget {
  const AdminOverviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final user = ref.watch(currentUserProvider);
    final users = ref.watch(adminUsersProvider);
    final companies = ref.watch(adminCompaniesProvider);
    final jobs = ref.watch(moderationJobsProvider);
    final applications = ref.watch(adminApplicationsProvider);
    final audit = ref.watch(auditLogProvider);
    final pending = jobs.where((j) => j.status == JobStatus.pending).toList();
    final unverified = companies
        .where((c) => c.verification == Verification.pending)
        .length;

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
                decoration: const BoxDecoration(
                  color: AppColors.white,
                  border: Border(bottom: BorderSide(color: AppColors.border)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ADMIN',
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
                    Text(
                      pending.isEmpty
                          ? 'No jobs are waiting for approval.'
                          : '${pending.length} ${pending.length == 1 ? 'job needs' : 'jobs need'} your approval.',
                      style: text.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenHorizontal,
                AppSpacing.xl,
                AppSpacing.screenHorizontal,
                AppSpacing.xxxl,
              ),
              sliver: SliverList.list(
                children: [
                  StatGrid(
                    tiles: [
                      StatTile(
                        label: 'Users',
                        value: '${users.length}',
                        icon: Icons.people_outline_rounded,
                        onTap: () => context.go(AppRoutes.adminUsers),
                      ),
                      StatTile(
                        label: unverified == 0
                            ? 'Employers'
                            : 'Employers · $unverified to verify',
                        value: '${companies.length}',
                        icon: Icons.apartment_outlined,
                        onTap: () => context.push(AppRoutes.adminEmployers),
                      ),
                      StatTile(
                        label: 'Jobs · ${pending.length} pending',
                        value: '${jobs.length}',
                        icon: Icons.work_outline_rounded,
                        onTap: () => context.go(AppRoutes.adminJobs),
                      ),
                      StatTile(
                        label: 'Applications',
                        value: '${applications.length}',
                        icon: Icons.send_outlined,
                        onTap: () => context.push(AppRoutes.adminApplications),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  SectionHeader(
                    title: 'Pending approvals',
                    actionLabel: 'See all',
                    onAction: () => context.go(AppRoutes.adminJobs),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  if (pending.isEmpty)
                    const InlineBanner(
                      tone: BannerTone.success,
                      message: 'All caught up. Nothing to review.',
                    )
                  else
                    for (final j in pending.take(2))
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: ModerationJobCard(job: j),
                      ),
                  const SizedBox(height: AppSpacing.md),
                  AppSurface(
                    onTap: () => context.push(AppRoutes.adminApiMonitoring),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'JSearch API usage',
                                style: text.titleMedium,
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right_rounded,
                              color: AppColors.textTertiary,
                            ),
                          ],
                        ),
                        Text(
                          'This month, against the plan limit',
                          style: text.bodySmall,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        UsageMeter(
                          used: ref.watch(jsearchUsageProvider),
                          limit: ref
                              .watch(platformSettingsProvider)
                              .jsearchMonthlyLimit,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppSurface(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Applications per day', style: text.titleMedium),
                        Text('Last 7 days', style: text.bodySmall),
                        const SizedBox(height: AppSpacing.lg),
                        const BarChart(
                          values: [12, 18, 9, 22, 27, 19, 31],
                          labels: ['M', 'T', 'W', 'T', 'F', 'S', 'Today'],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  SectionHeader(
                    title: 'Recent activity',
                    actionLabel: 'Audit log',
                    onAction: () => context.push(AppRoutes.adminAuditLogs),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppSurface(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        for (var i = 0; i < audit.take(4).length; i++) ...[
                          if (i > 0) const Divider(indent: AppSpacing.lg),
                          ListTile(
                            leading: const Icon(
                              Icons.history_rounded,
                              color: AppColors.ocean,
                            ),
                            title: Text(
                              '${audit[i].action}: ${audit[i].entityLabel}',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              '${audit[i].admin} · ${formatAgo(audit[i].at)}',
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
