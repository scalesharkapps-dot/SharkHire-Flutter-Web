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
    this.quiet = false,
  });

  final JobSummary job;
  final bool isSaved;
  final VoidCallback onToggleSave;
  final VoidCallback? onTap;

  /// Home's quieter layout: title, company and city, salary, then the fit
  /// score with its tick bar and the source as plain text.
  final bool quiet;

  @override
  Widget build(BuildContext context) {
    if (quiet) return _buildQuiet(context);
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

extension on JobCard {
  Widget _buildQuiet(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final score = job.matchScore;
    final secondary = text.bodyMedium?.copyWith(
      color: AppColors.textSecondary,
      fontSize: 14,
      height: 1.3,
    );
    final source = job.isInternal ? 'In-app' : 'External';
    return AppSurface(
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.xs,
        AppSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    job.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: text.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
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
                Text(
                  '${job.companyName} · ${job.location}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: secondary,
                ),
                if (job.salaryLabel != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    job.salaryLabel!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: secondary,
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    if (score != null) FitScoreInline(score: score),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Semantics(
                        label: job.isInternal ? 'Apply in-app' : 'External job',
                        excludeSemantics: true,
                        child: Text(
                          source,
                          textAlign: TextAlign.right,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: text.bodySmall?.copyWith(
                            color: AppColors.textTertiary,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
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

/// Compact source badge: "IN-APP" (apply on SharkHire) or "EXTERNAL".
class _SourceBadge extends StatelessWidget {
  const _SourceBadge({required this.internal});

  final bool internal;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: internal ? 'Apply in-app' : 'External job',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
        decoration: BoxDecoration(
          color: internal ? AppColors.successTint : Colors.transparent,
          borderRadius: AppRadius.smAll,
          border: internal ? null : Border.all(color: AppColors.borderStrong),
        ),
        child: Text(
          internal ? 'IN-APP' : 'EXTERNAL',
          style: TextStyle(
            fontFamily: AppFonts.label,
            fontWeight: FontWeight.w700,
            fontSize: 10,
            letterSpacing: 0.8,
            color: internal ? AppColors.success : AppColors.textSecondary,
          ),
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
