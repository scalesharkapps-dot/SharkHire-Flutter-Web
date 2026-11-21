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

StatusTone _verificationTone(Verification v) => switch (v) {
  Verification.verified => StatusTone.positive,
  Verification.pending => StatusTone.progress,
  Verification.rejected => StatusTone.negative,
};

/// Employer verification (guide §3.7).
class AdminEmployersScreen extends ConsumerWidget {
  const AdminEmployersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final companies = ref.watch(adminCompaniesProvider);
    return AdminPage(
      title: 'Employers',
      intro:
          'Verified employers show a badge on their jobs. Check the company details before verifying.',
      children: [
        for (final c in companies)
          AppSurface(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CompanyLogo(name: c.name, size: 40),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(c.name, style: text.titleSmall),
                          Text(
                            '${c.owner} · ${c.industry ?? 'Industry not set'}',
                            style: text.bodySmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    StatusChip(
                      label: c.verification.label,
                      tone: _verificationTone(c.verification),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  '${c.jobCount} jobs · joined ${formatDate(c.joinedAt)}',
                  style: text.bodySmall,
                ),
                if (c.verification == Verification.pending) ...[
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.error,
                            minimumSize: const Size(0, 44),
                          ),
                          onPressed: () {
                            ref
                                .read(adminCompaniesProvider.notifier)
                                .verify(c.id, Verification.rejected);
                            AppFeedback.show(
                              context,
                              '${c.name} verification rejected',
                            );
                          },
                          child: const Text('Reject'),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(0, 44),
                          ),
                          onPressed: () {
                            ref
                                .read(adminCompaniesProvider.notifier)
                                .verify(c.id, Verification.verified);
                            AppFeedback.show(
                              context,
                              '${c.name} is now verified',
                            );
                          },
                          child: const Text('Verify'),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

/// Application monitoring (in-app applications only).
class AdminApplicationsScreen extends ConsumerStatefulWidget {
  const AdminApplicationsScreen({super.key});

  @override
  ConsumerState<AdminApplicationsScreen> createState() =>
      _AdminApplicationsScreenState();
}

class _AdminApplicationsScreenState
    extends ConsumerState<AdminApplicationsScreen> {
  ApplicationStatus? _status;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final all = ref.watch(adminApplicationsProvider);
    final shown = _status == null
        ? all
        : all.where((a) => a.status == _status).toList();
    return AdminPage(
      title: 'Applications',
      intro:
          'Applications to SharkHire employer jobs. External applications happen on other sites.',
      children: [
        ChoiceChipGroup<ApplicationStatus?>(
          options: [null, ...ApplicationStatus.values],
          selected: {_status},
          multiSelect: false,
          labelOf: (s) => s?.label ?? 'All',
          onChanged: (s) => setState(() => _status = s.first),
        ),
        if (shown.isEmpty)
          const EmptyStateView(
            compact: true,
            icon: Icons.inbox_outlined,
            title: 'Nothing here',
            message: 'No applications have this status.',
          )
        else
          for (final a in shown)
            AppSurface(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(a.candidate, style: text.titleSmall),
                        Text(
                          '${a.job} · ${a.company}',
                          style: text.bodySmall,
                          maxLines: 2,
                        ),
                        Text(formatAgo(a.submittedAt), style: text.bodySmall),
                      ],
                    ),
                  ),
                  StatusChip.application(a.status),
                ],
              ),
            ),
      ],
    );
  }
}

/// Cached external (JSearch) listings (guide §3.7, §3.9).
class AdminExternalJobsScreen extends ConsumerWidget {
  const AdminExternalJobsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final listings = ref.watch(externalListingsProvider);
    final stale = listings.where((l) => l.isStale).length;
    return AdminPage(
      title: 'External listings',
      intro:
          'Imported jobs. People apply on the original site. '
          '$stale ${stale == 1 ? 'listing has' : 'listings have'} expired and ${stale == 1 ? 'is' : 'are'} hidden from job seekers.',
      children: [
        for (final l in listings)
          AppSurface(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(l.title, style: text.titleSmall)),
                    StatusChip(
                      label: l.isStale ? 'Expired' : 'Fresh',
                      tone: l.isStale
                          ? StatusTone.neutral
                          : StatusTone.positive,
                    ),
                  ],
                ),
                Text(
                  '${l.company} · ${l.country} · ${l.publisher}',
                  style: text.bodySmall,
                ),
                const SizedBox(height: 4),
                Text(
                  'Fetched ${formatAgo(l.fetchedAt)} · expires ${formatDate(l.expiresAt)}',
                  style: text.bodySmall,
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// CV processing outcomes and retention (guide §3.7 "CV management").
class AdminCvReportsScreen extends ConsumerWidget {
  const AdminCvReportsScreen({super.key});

  static const _failed = [
    ('Scanned_CV_photo.pdf', 'No readable text (image-only PDF)', 3),
    ('Resume_final_v7.docx', 'File is password protected', 20),
    ('cv.pdf', 'File larger than 5 MB', 30),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final months = ref.watch(platformSettingsProvider).cvRetentionMonths;
    return AdminPage(
      title: 'CV reports',
      intro:
          'How CV uploads are processing. CV files stay private; admins see outcomes only.',
      children: [
        const StatGrid(
          tiles: [
            StatTile(
              label: 'Uploaded this month',
              value: '418',
              icon: Icons.upload_file_rounded,
            ),
            StatTile(
              label: 'Processed (96%)',
              value: '402',
              icon: Icons.task_alt_rounded,
            ),
            StatTile(
              label: 'Failed',
              value: '16',
              icon: Icons.error_outline_rounded,
            ),
            StatTile(
              label: 'Avg. processing',
              value: '6.2s',
              icon: Icons.timer_outlined,
            ),
          ],
        ),
        const GroupLabel('Recent failures'),
        for (final (file, reason, hours) in _failed)
          AppSurface(
            elevated: false,
            child: Row(
              children: [
                Icon(Icons.error_outline_rounded, color: AppColors.error),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        file,
                        style: text.titleSmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(reason, style: text.bodySmall),
                      Text(
                        formatAgo(
                          DateTime.now().subtract(Duration(hours: hours)),
                        ),
                        style: text.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        InlineBanner(
          tone: BannerTone.info,
          title: 'Retention policy',
          message:
              'Inactive CVs are deleted after $months months. Change this in Platform settings.',
        ),
      ],
    );
  }
}
