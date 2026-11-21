import 'package:material_ui/material_ui.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/date_formatters.dart';
import '../models/job_summary.dart';
import 'app_surface.dart';
import 'company_logo.dart';
import 'match_score_badge.dart';

/// Reusable job listing card used by Home, Explore, Matches and Saved.
///
/// Layout: company logo + title/company on top with the match ring at the
/// right; location and terms; salary; then source pill, age and bookmark.
class JobCard extends StatelessWidget {
  const JobCard({
    super.key,
    required this.job,
    required this.isSaved,
    required this.onToggleSave,
    this.onTap,
  });

  final JobSummary job;
  final bool isSaved;
  final VoidCallback onToggleSave;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return AppSurface(
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CompanyLogo(name: job.companyName),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      job.title,
                      style: text.titleMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    _CompanyLine(
                      name: job.companyName,
                      rating: job.companyRating,
                    ),
                  ],
                ),
              ),
              if (job.matchScore != null) ...[
                const SizedBox(width: AppSpacing.sm),
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.sm),
                  child: MatchScoreRing(score: job.matchScore!, size: 42),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _MetaRow(
                  icon: Icons.location_on_outlined,
                  text:
                      '${job.location}  ·  ${job.workMode.label}  ·  '
                      '${job.employmentType.label}',
                ),
                if (job.salaryLabel != null) ...[
                  const SizedBox(height: 6),
                  _MetaRow(
                    icon: Icons.payments_outlined,
                    text: job.salaryLabel!,
                    emphasize: true,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              job.isInternal
                  ? const InfoPill.internal()
                  : const InfoPill.external(),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  DateFormatters.relativeAge(job.postedAt),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.bodySmall?.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
              ),
              _BookmarkButton(isSaved: isSaved, onPressed: onToggleSave),
            ],
          ),
        ],
      ),
    );
  }
}

class _CompanyLine extends StatelessWidget {
  const _CompanyLine({required this.name, this.rating});

  final String name;
  final double? rating;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodyMedium?.copyWith(
      color: AppColors.textSecondary,
      height: 1.3,
    );
    return Row(
      children: [
        Flexible(
          child: Text(
            name,
            style: style,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (rating != null) ...[
          const SizedBox(width: 6),
          Icon(Icons.star_rounded, size: 15, color: AppColors.ink),
          const SizedBox(width: 2),
          Text(
            rating!.toStringAsFixed(1),
            style: style?.copyWith(
              color: AppColors.ink,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({
    required this.icon,
    required this.text,
    this.emphasize = false,
  });

  final IconData icon;
  final String text;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).textTheme.bodyMedium;
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textTertiary),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: emphasize
                ? base?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                  )
                : base?.copyWith(color: AppColors.textSecondary),
          ),
        ),
      ],
    );
  }
}

class _BookmarkButton extends StatelessWidget {
  const _BookmarkButton({required this.isSaved, required this.onPressed});

  final bool isSaved;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      tooltip: isSaved ? 'Remove from saved' : 'Save job',
      icon: AnimatedSwitcher(
        duration: AppDurations.fast,
        child: Icon(
          isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
          key: ValueKey(isSaved),
          color: isSaved ? AppColors.ocean : AppColors.textSecondary,
        ),
      ),
    );
  }
}
