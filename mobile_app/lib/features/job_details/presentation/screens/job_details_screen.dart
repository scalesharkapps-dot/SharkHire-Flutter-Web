import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/date_formatters.dart';
import '../../../../core/utils/feedback.dart';
import '../../../../shared/models/job_summary.dart';
import '../../../../shared/widgets/app_surface.dart';
import '../../../../shared/widgets/bottom_action_bar.dart';
import '../../../../shared/widgets/company_logo.dart';
import '../../../../shared/widgets/fade_in_up.dart';
import '../../../../shared/widgets/form_fields.dart';
import '../../../../shared/widgets/match_score_badge.dart';
import '../../../../shared/widgets/skeleton.dart';
import '../../../../shared/widgets/state_views.dart';
import '../../../../shared/widgets/status_chip.dart';
import '../../../applications/presentation/providers/applications_provider.dart';
import '../../../resume/presentation/providers/cv_provider.dart';
import '../../../saved_jobs/presentation/providers/saved_jobs_provider.dart';
import '../../data/models/job_details.dart';
import '../../data/repositories/job_details_repository.dart';

/// Job details for external (JSearch) and internal (employer) jobs
/// (guide §3.5, mockup 4.3).
class JobDetailsScreen extends ConsumerWidget {
  const JobDetailsScreen({super.key, required this.jobId});

  final String jobId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final details = ref.watch(jobDetailsProvider(jobId));
    final isSaved = ref.watch(
      savedJobIdsProvider.select((s) => s.contains(jobId)),
    );

    return Scaffold(
      appBar: AppBar(
        // The title is the page's own heading below, so not repeated here.
        title: Semantics(label: 'Job details', child: const SizedBox()),
        actions: [
          IconButton(
            tooltip: isSaved ? 'Remove from saved' : 'Save job',
            onPressed: () {
              ref.read(savedJobIdsProvider.notifier).toggle(jobId);
              AppFeedback.show(
                context,
                isSaved ? 'Removed from saved jobs' : 'Saved to your jobs',
              );
            },
            icon: Icon(
              isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
              color: isSaved ? AppColors.ocean : AppColors.textSecondary,
            ),
          ),
        ],
      ),
      body: details.when(
        loading: () => const _DetailsSkeleton(),
        error: (e, _) => e is JobNotFound
            ? EmptyStateView(
                icon: Icons.work_off_outlined,
                title: 'This job is no longer available',
                message: 'It may have been filled or removed by the employer.',
                actionLabel: 'Find similar jobs',
                onAction: () => context.go(AppRoutes.explore),
              )
            : ErrorStateView(
                onRetry: () => ref.invalidate(jobDetailsProvider(jobId)),
              ),
        data: (d) => _DetailsBody(details: d),
      ),
      bottomNavigationBar: details.hasValue
          ? _ApplyBar(details: details.value!)
          : null,
    );
  }
}

class _DetailsBody extends ConsumerWidget {
  const _DetailsBody({required this.details});

  final JobDetails details;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final s = details.summary;
    final cv = ref.watch(cvProvider);
    final mySkills = {
      for (final k
          in cv.profile?.skills ??
              const ['Flutter', 'Dart', 'Firebase', 'REST APIs', 'Git'])
        k.toLowerCase(),
    };

    final facts = <(String, String)>[
      ('Employment', s.employmentType.label),
      ('Work mode', s.workMode.label),
      if (details.experienceLevel != null)
        ('Experience', details.experienceLevel!.label),
      if (details.education != null) ('Education', details.education!),
      if (details.vacancies != null) ('Vacancies', '${details.vacancies}'),
      if (details.deadline != null) ('Apply by', _date(details.deadline!)),
      ('Salary', s.salaryLabel ?? 'Not stated'),
      (
        'Posted',
        '${DateFormatters.relativeAge(s.postedAt)} ago'.replaceAll(
          'Just now ago',
          'Today',
        ),
      ),
      if (details.publisher != null) ('Source', details.publisher!),
      if (details.lastCheckedAt != null)
        (
          'Last checked',
          '${DateFormatters.relativeAge(details.lastCheckedAt!)} ago',
        ),
    ];

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: ListView(
          padding: const EdgeInsets.only(bottom: AppSpacing.xxxl),
          children: [
            _JobBand(details: details),
            for (final w in <Widget>[
              const SizedBox(height: AppSpacing.lg),

              // Match
              FadeInUp(
                delay: const Duration(milliseconds: 60),
                child: cv.hasCv || s.matchScore != null
                    ? _MatchCard(
                        score: s.matchScore ?? 0,
                        reasons: details.matchReasons,
                      )
                    : const SizedBox.shrink(),
              ),

              if (!s.isInternal) ...[
                const SizedBox(height: AppSpacing.lg),
                const InlineBanner(
                  tone: BannerTone.warning,
                  message:
                      'You\'ll apply on the employer\'s website. SharkHire only records that you '
                      'opened the application, not whether it was submitted.',
                ),
              ],

              _Heading('Job information'),
              AppSurface(
                padding: EdgeInsets.zero,
                elevated: false,
                child: Column(
                  children: [
                    for (var i = 0; i < facts.length; i++) ...[
                      if (i > 0)
                        const Divider(
                          indent: AppSpacing.lg,
                          endIndent: AppSpacing.lg,
                        ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                          vertical: 12,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                facts[i].$1,
                                style: text.bodyMedium?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Flexible(
                              child: Text(
                                facts[i].$2,
                                textAlign: TextAlign.right,
                                style: text.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              _Heading('Required skills'),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  for (final k in details.requiredSkills)
                    mySkills.contains(k.toLowerCase())
                        ? InfoPill(
                            label: k,
                            icon: Icons.check_rounded,
                            background: AppColors.successTint,
                            foreground: AppColors.success,
                          )
                        : InfoPill(label: k, bordered: true),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text('Green skills are on your CV.', style: text.bodySmall),

              _Heading('About the role'),
              Text(details.description, style: text.bodyLarge),
              if (details.responsibilities.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.lg),
                Text('What you\'ll do', style: text.titleSmall),
                const SizedBox(height: AppSpacing.sm),
                ...details.responsibilities.map((r) => _BulletLine(r)),
              ],
              if (details.requirements.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.lg),
                Text('What they\'re looking for', style: text.titleSmall),
                const SizedBox(height: AppSpacing.sm),
                ...details.requirements.map((r) => _BulletLine(r)),
              ],

              if (details.applicationInstructions != null) ...[
                _Heading('How to apply'),
                Text(details.applicationInstructions!, style: text.bodyLarge),
              ],

              if (details.companyAbout != null) ...[
                _Heading('About ${s.companyName}'),
                AppSurface(
                  elevated: false,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CompanyLogo(name: s.companyName, size: 40),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Text(
                          details.companyAbout!,
                          style: text.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ])
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenHorizontal,
                ),
                child: w,
              ),
          ],
        ),
      ),
    );
  }

  static String _date(DateTime d) {
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
    return '${d.day} ${m[d.month - 1]} ${d.year}';
  }
}

/// The one fit block: big score with its tick bar, then the reasons.
class _MatchCard extends StatelessWidget {
  const _MatchCard({required this.score, required this.reasons});

  final int score;
  final List<String> reasons;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final tier = MatchTier.of(score);
    return AppSurface(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FitScoreInline(score: score, fontSize: 56, label: tier.label),
          if (reasons.isNotEmpty) const SizedBox(height: AppSpacing.lg),
          for (final r in reasons)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Icon(
                      r.startsWith('Some')
                          ? Icons.remove_circle_outline_rounded
                          : Icons.check_rounded,
                      size: 16,
                      color: r.startsWith('Some')
                          ? AppColors.warning
                          : AppColors.success,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: Text(r, style: text.bodyMedium)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ApplyBar extends ConsumerWidget {
  const _ApplyBar({required this.details});

  final JobDetails details;

  Future<void> _openExternal(BuildContext context, WidgetRef ref) async {
    final url = details.applyUrl;
    if (url == null) return;
    ref.read(externalApplyClicksProvider.notifier).record(details.id);
    // Best effort: the click is recorded even if tracking fails.
    ref
        .read(jobDetailsRepositoryProvider)
        .recordExternalApplyClick(details.id)
        .ignore();
    final ok = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );
    if (!ok && context.mounted) {
      AppFeedback.show(
        context,
        'We couldn\'t open the employer\'s site. Try again later.',
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final application = ref.watch(
      applicationsProvider.select(
        (apps) => apps
            .where(
              (a) =>
                  a.job.id == details.id &&
                  a.status != ApplicationStatus.withdrawn,
            )
            .firstOrNull,
      ),
    );
    final clicked = ref.watch(
      externalApplyClicksProvider.select((c) => c.contains(details.id)),
    );

    Widget primary;
    if (details.isInternal && application != null) {
      primary = OutlinedButton(
        onPressed: () =>
            context.push(AppRoutes.applicationDetails(application.id)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Flexible(
              child: Text('Applied', overflow: TextOverflow.ellipsis),
            ),
            const SizedBox(width: AppSpacing.sm),
            StatusChip.application(application.status),
          ],
        ),
      );
    } else if (details.isInternal) {
      primary = FilledButton(
        onPressed: () => context.push(AppRoutes.applyToJob(details.id)),
        child: const Text('Apply now'),
      );
    } else {
      primary = FilledButton.icon(
        onPressed: () => _openExternal(context, ref),
        icon: const Icon(Icons.open_in_new_rounded, size: 20),
        label: Text(
          clicked ? 'Open employer site again' : 'Apply on employer site',
          overflow: TextOverflow.ellipsis,
        ),
      );
    }

    return BottomActionBar(
      maxWidth: 640,
      child: SizedBox(width: double.infinity, child: primary),
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: AppSpacing.xxl, bottom: AppSpacing.md),
    child: Text(text, style: Theme.of(context).textTheme.titleMedium),
  );
}

class _BulletLine extends StatelessWidget {
  const _BulletLine(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 9, right: AppSpacing.sm),
          width: 5,
          height: 5,
          decoration: BoxDecoration(
            color: AppColors.ocean,
            shape: BoxShape.circle,
          ),
        ),
        Expanded(
          child: Text(text, style: Theme.of(context).textTheme.bodyLarge),
        ),
      ],
    ),
  );
}

class _DetailsSkeleton extends StatelessWidget {
  const _DetailsSkeleton();

  @override
  Widget build(BuildContext context) => ListView(
    padding: AppSpacing.screenPadding,
    children: const [
      Shimmer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Skeleton(width: 52, height: 52, radius: 14),
                SizedBox(width: AppSpacing.md),
                Skeleton(width: 140, height: 14),
              ],
            ),
            SizedBox(height: AppSpacing.xl),
            Skeleton(width: 260, height: 22),
            SizedBox(height: AppSpacing.md),
            Skeleton(width: 180),
            SizedBox(height: AppSpacing.xl),
            Skeleton(height: 110, radius: 16),
            SizedBox(height: AppSpacing.xl),
            Skeleton(height: 220, radius: 16),
          ],
        ),
      ),
    ],
  );
}

/// Top of the job: company, title and the key facts in one line, on the
/// page background. The fit score lives in the match card just below.
class _JobBand extends StatelessWidget {
  const _JobBand({required this.details});

  final JobDetails details;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final s = details.summary;
    final meta = [
      s.location,
      s.workMode.label,
      s.employmentType.label,
      if (s.salaryLabel != null) s.salaryLabel!,
    ].join(' · ');

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenHorizontal,
        AppSpacing.sm,
        AppSpacing.screenHorizontal,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CompanyLogo(name: s.companyName, size: 44),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.companyName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.titleSmall,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      [
                        if (s.companyRating != null)
                          '${s.companyRating!.toStringAsFixed(1)} rating',
                        s.isInternal
                            ? 'Apply in-app · Verified employer'
                            : 'External · ${details.publisher ?? 'Job board'}',
                      ].join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.bodySmall?.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Semantics(
            header: true,
            child: Text(
              s.title,
              style: text.headlineMedium?.copyWith(
                color: AppColors.ink,
                fontSize: 30,
                height: 1.12,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            meta,
            style: text.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
