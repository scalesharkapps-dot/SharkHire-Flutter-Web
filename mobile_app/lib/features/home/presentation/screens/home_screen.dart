import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../job_search/data/mock_jobs.dart';
import '../../../../shared/models/job_summary.dart';
import '../../../../shared/widgets/fade_in_up.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../../../shared/widgets/state_views.dart';
import '../../../applications/presentation/providers/applications_provider.dart';
import '../../../job_matches/presentation/providers/job_matches_providers.dart';
import '../../../job_search/presentation/providers/explore_providers.dart';
import '../../../notifications/presentation/providers/notifications_provider.dart';
import '../../../profile/presentation/providers/current_user_provider.dart';
import '../../../saved_jobs/presentation/providers/saved_jobs_provider.dart';
import '../../../saved_jobs/presentation/widgets/async_job_sliver.dart';
import '../../../subscription/presentation/widgets/subscription_widgets.dart';
import '../providers/home_providers.dart';
import '../widgets/home_header.dart';
import '../widgets/home_sections.dart';

/// Personalised job seeker dashboard (project guide §3.10 "Home").
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final recommended = ref.watch(recommendedJobsProvider);
    final recent = ref.watch(recentJobsProvider);
    final savedCount = ref.watch(savedJobIdsProvider).length;
    final strongMatches = ref.watch(strongMatchCountProvider);

    Future<void> refresh() async {
      ref.invalidate(allJobsProvider);
      await ref.read(allJobsProvider.future).catchError((_) => <JobSummary>[]);
    }

    void openCategory(String category) {
      ref.read(exploreControllerProvider.notifier)
        ..reset()
        ..setQuery(category);
      context.go(AppRoutes.explore);
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        body: RefreshIndicator(
          onRefresh: refresh,
          edgeOffset: MediaQuery.paddingOf(context).top,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: HomeHeader(
                  firstName: user.firstName,
                  initials: user.initials,
                  strongMatches: strongMatches,
                  savedCount: savedCount,
                  appliedCount: ref
                      .watch(applicationsProvider)
                      .where((a) => a.isActive)
                      .length,
                  onSearchTap: () => context.go(AppRoutes.explore),
                  hasUnread: ref.watch(unreadNotificationsProvider) > 0,
                  onNotificationsTap: () =>
                      context.push(AppRoutes.notifications),
                  onAvatarTap: () => context.go(AppRoutes.profile),
                  onSavedTap: () => context.go(AppRoutes.saved),
                  onAppliedTap: () => context.push(AppRoutes.applications),
                ),
              ),

              const SliverToBoxAdapter(child: TrialBanner()),

              if (!user.hasCv)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screenHorizontal,
                    AppSpacing.xl,
                    AppSpacing.screenHorizontal,
                    0,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: FadeInUp(
                      child: CvPromptCard(
                        profileCompletion: user.profileCompletion,
                        onUpload: () => context.push(AppRoutes.cvUpload),
                      ),
                    ),
                  ),
                ),

              _sectionHeader(
                SectionHeader(
                  title: 'Recommended for you',
                  subtitle: 'Ranked by how well they fit your CV',
                  actionLabel: 'See all',
                  onAction: () => context.go(AppRoutes.explore),
                ),
              ),
              AsyncJobSliver(
                value: recommended,
                onRetry: refresh,
                empty: _noMatches,
              ),

              _sectionHeader(const SectionHeader(title: 'Browse by category')),
              SliverToBoxAdapter(
                child: CategoryStrip(
                  categories: MockJobs.categories,
                  onTap: openCategory,
                ),
              ),

              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenHorizontal,
                  AppSpacing.lg,
                  AppSpacing.screenHorizontal,
                  0,
                ),
                sliver: SliverToBoxAdapter(
                  child: JobAlertCard(
                    title: 'Job alert: Flutter jobs',
                    meta: 'Daily  ·  Pakistan & remote  ·  Active',
                    onTap: () => context.push(AppRoutes.jobAlerts),
                  ),
                ),
              ),

              _sectionHeader(
                SectionHeader(
                  title: 'Recently posted',
                  actionLabel: 'See all',
                  onAction: () {
                    ref
                        .read(exploreControllerProvider.notifier)
                        .setSort(ExploreSort.newest);
                    context.go(AppRoutes.explore);
                  },
                ),
              ),
              AsyncJobSliver(
                value: recent,
                onRetry: refresh,
                skeletonCount: 1,
                empty: _noMatches,
              ),

              const SliverToBoxAdapter(
                child: SizedBox(height: AppSpacing.xxxl),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _sectionHeader(Widget child) => SliverPadding(
    padding: const EdgeInsets.fromLTRB(
      AppSpacing.screenHorizontal,
      AppSpacing.xxl,
      AppSpacing.sm,
      AppSpacing.md,
    ),
    sliver: SliverToBoxAdapter(child: child),
  );
}

const _noMatches = EmptyStateView(
  compact: true,
  icon: Icons.work_outline_rounded,
  title: 'No matches yet',
  message: 'Upload your CV and set your preferences to get recommendations.',
);
