import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/state_views.dart';
import '../../../job_search/presentation/providers/explore_providers.dart';
import '../providers/saved_jobs_provider.dart';
import '../widgets/async_job_sliver.dart';

/// Saved opportunities (project guide §3.10 "Saved jobs").
class SavedJobsScreen extends ConsumerWidget {
  const SavedJobsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saved = ref.watch(savedJobsProvider);
    final text = Theme.of(context).textTheme;
    final count = saved.value?.length ?? 0;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenHorizontal,
                  AppSpacing.lg,
                  AppSpacing.screenHorizontal,
                  AppSpacing.lg,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Saved jobs', style: text.headlineLarge),
                    const SizedBox(height: 2),
                    Text(
                      count == 0
                          ? 'Bookmark jobs to compare and apply later'
                          : '$count ${count == 1 ? 'job' : 'jobs'} saved',
                      style: text.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            AsyncJobSliver(
              value: saved,
              fillRemaining: true,
              onRetry: () {
                ref.invalidate(allJobsProvider);
                ref.invalidate(remoteSavedJobsProvider);
              },
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenHorizontal,
                0,
                AppSpacing.screenHorizontal,
                AppSpacing.xxxl,
              ),
              empty: EmptyStateView(
                plain: true,
                icon: Icons.bookmark_border_rounded,
                title: 'No saved jobs yet',
                message:
                    'Tap the bookmark on any job to keep it here and compare it later.',
                actionLabel: 'Explore jobs',
                onAction: () => context.go(AppRoutes.explore),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
