import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/models/job_summary.dart';
import '../../../../shared/widgets/fade_in_up.dart';
import '../../../../shared/widgets/skeleton.dart';
import '../../../../shared/widgets/state_views.dart';
import 'saved_aware_job_card.dart';

/// One sliver that renders an async job list with consistent loading,
/// error, empty and data states. Used by Home, Explore and Saved so every
/// job list in the app behaves the same.
class AsyncJobSliver extends StatelessWidget {
  const AsyncJobSliver({
    super.key,
    required this.value,
    required this.onRetry,
    required this.empty,
    this.skeletonCount = 2,
    this.fillRemaining = false,
    this.padding = AppSpacing.screenPadding,
    this.quietCards = false,
  });

  final AsyncValue<List<JobSummary>> value;
  final VoidCallback onRetry;

  /// Shown when the list is empty (usually an [EmptyStateView]).
  final Widget empty;
  final int skeletonCount;

  /// Centre empty/error states in the remaining viewport (full-page lists).
  final bool fillRemaining;
  final EdgeInsetsGeometry padding;

  /// Home's quieter job cards.
  final bool quietCards;

  @override
  Widget build(BuildContext context) {
    Widget state(Widget child) => fillRemaining
        ? SliverFillRemaining(hasScrollBody: false, child: child)
        : SliverPadding(
            padding: padding,
            sliver: SliverToBoxAdapter(child: child),
          );

    return value.when(
      loading: () => SliverPadding(
        padding: padding,
        sliver: SliverToBoxAdapter(
          child: JobListSkeleton(count: skeletonCount),
        ),
      ),
      error: (e, _) => state(
        ErrorStateView(
          compact: !fillRemaining,
          message: friendlyErrorMessage(e),
          onRetry: onRetry,
        ),
      ),
      data: (jobs) => jobs.isEmpty
          ? state(empty)
          : SliverPadding(
              padding: padding,
              sliver: SliverList.separated(
                itemCount: jobs.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: AppSpacing.md),
                itemBuilder: (context, i) => FadeInUp(
                  key: ValueKey(jobs[i].id),
                  delay: Duration(milliseconds: 60 * i.clamp(0, 6)),
                  child: SavedAwareJobCard(job: jobs[i], quiet: quietCards),
                ),
              ),
            ),
    );
  }
}
