import 'package:material_ui/material_ui.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
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
    final score = job.matchScore;

    final details = Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.xs,
        AppSpacing.xs,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (score == null) ...[
                CompanyLogo(name: job.companyName, size: 40),
                const SizedBox(width: AppSpacing.md),
              ],
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    job.title,
                    style: text.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              _BookmarkButton(isSaved: isSaved, onPressed: onToggleSave),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _CompanyLine(
                  name: job.companyName,
                  rating: job.companyRating,
                  meta: '${job.location} · ${job.workMode.label}',
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        job.salaryLabel ??
                            '${job.employmentType.label} · '
                                '${DateFormatters.relativeAge(job.postedAt)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: text.labelLarge?.copyWith(
                          fontSize: 14,
                          color: job.salaryLabel != null
                              ? AppColors.ink
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    _SourceBadge(internal: job.isInternal),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
            ),
          ),
        ],
      ),
    );

    // Signal: the match score is the card's signature, a solid FIT block.
    return AppSurface(
      onTap: onTap,
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: AppRadius.xlAll,
        child: score == null
            ? details
            : IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    FitScoreBlock(score: score),
                    Expanded(child: details),
                  ],
                ),
              ),
      ),
    );
  }
}

class _CompanyLine extends StatelessWidget {
  const _CompanyLine({required this.name, required this.meta, this.rating});

  final String name;
  final String meta;
  final double? rating;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodyMedium?.copyWith(
      color: AppColors.textSecondary,
      height: 1.3,
      fontSize: 14,
    );
    // One line that trims at the end, so the company name stays whole and
    // the location gives way first.
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: name),
          if (rating != null) ...[
            const TextSpan(text: '  '),
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Icon(Icons.star_rounded, size: 14, color: AppColors.ink),
            ),
            TextSpan(
              text: ' ${rating!.toStringAsFixed(1)}',
              style: TextStyle(
                color: AppColors.ink,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          TextSpan(text: '  ·  $meta'),
        ],
      ),
      style: style,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

/// Quiet source label: "In-app" (apply on SharkHire) or "External".
class _SourceBadge extends StatelessWidget {
  const _SourceBadge({required this.internal});

  final bool internal;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: internal ? 'Apply in-app' : 'External job',
      excludeSemantics: true,
      child: Text(
        internal ? 'In-app' : 'External',
        style: TextStyle(
          fontFamily: AppFonts.label,
          fontWeight: FontWeight.w500,
          fontSize: 13,
          color: AppColors.textTertiary,
        ),
      ),
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
          color: isSaved ? AppColors.ocean : AppColors.textTertiary,
        ),
      ),
    );
  }
}
