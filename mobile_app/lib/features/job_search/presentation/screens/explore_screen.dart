import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_search_bar.dart';
import '../../../../shared/widgets/state_views.dart';
import '../../../saved_jobs/presentation/widgets/async_job_sliver.dart';
import '../providers/explore_providers.dart';
import '../../../subscription/presentation/providers/pro_access.dart';
import '../../../subscription/presentation/widgets/pro_badge.dart';
import '../../../subscription/presentation/widgets/pro_upgrade_dialog.dart';
import '../widgets/city_picker_sheet.dart';
import '../widgets/explore_filter_sheet.dart';

/// Explore: search jobs worldwide with filters
/// (project guide §3.5 "Job search, filters and job details").
class ExploreScreen extends ConsumerStatefulWidget {
  const ExploreScreen({super.key});

  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen> {
  /// Jobs shown per page; "Show more" reveals the next page.
  static const pageSize = 6;
  int _visible = pageSize;

  late final TextEditingController _search = TextEditingController(
    text: ref.read(exploreControllerProvider).query,
  );

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(exploreControllerProvider);
    final controller = ref.read(exploreControllerProvider.notifier);
    final results = ref.watch(exploreResultsProvider);
    final cityLabel = state.city;
    final pro = ref.watch(proAccessProvider);

    // The backend is the final authority: if it refuses remote-only
    // (403 PRO_FEATURE_REQUIRED), switch Remote off and offer Pro.
    ref.listen(exploreResultsProvider, (_, next) {
      if (next.hasError && isProFeatureRequired(next.error)) {
        controller.removeRemote();
        showRemoteProDialog(context);
      }
    });
    final text = Theme.of(context).textTheme;

    // A new search or filter starts again from the first page.
    ref.listen(exploreControllerProvider, (_, _) {
      if (_visible != pageSize) setState(() => _visible = pageSize);
    });
    final total = results.value?.length ?? 0;
    final remaining = total - _visible;

    // Keep the field in sync when the query is set elsewhere (e.g. Home).
    ref.listen(exploreControllerProvider.select((s) => s.query), (_, q) {
      if (_search.text != q) _search.text = q;
    });

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenHorizontal,
                  AppSpacing.lg,
                  AppSpacing.screenHorizontal,
                  0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Explore jobs',
                            style: text.headlineLarge,
                          ),
                        ),
                        TextButton.icon(
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.textSecondary,
                          ),
                          onPressed: () => context.push(AppRoutes.roles),
                          icon: const Icon(Icons.blur_circular_rounded),
                          label: const Text('By role'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Jobs worldwide, matched to you',
                      style: text.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    AppSearchBar(
                      controller: _search,
                      onChanged: controller.setQuery,
                      activeFilterCount: state.activeFilterCount,
                      onFilterTap: () => ExploreFilterSheet.show(context),
                    ),
                  ],
                ),
              ),
            ),

            // Quick filter chips
            SliverToBoxAdapter(
              child: SizedBox(
                height: 72,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screenHorizontal,
                    AppSpacing.md,
                    AppSpacing.screenHorizontal,
                    AppSpacing.md,
                  ),
                  itemCount: ExploreFilter.values.length + 1,
                  separatorBuilder: (_, _) =>
                      const SizedBox(width: AppSpacing.sm),
                  itemBuilder: (context, i) {
                    if (i == 0) {
                      return _CityChip(
                        city: state.city,
                        onTap: () => CityPickerSheet.show(context),
                        onClear: () => controller.setCity(null),
                      );
                    }
                    final f = ExploreFilter.values[i - 1];
                    if (f == ExploreFilter.remote && !pro) {
                      return FilterChip(
                        label: ProLockedLabel(f.label),
                        selected: false,
                        onSelected: (_) => showRemoteProDialog(context),
                        labelStyle: text.labelMedium?.copyWith(
                          color: AppColors.ink,
                        ),
                        backgroundColor: AppColors.surfaceMuted,
                        side: const BorderSide(color: Colors.transparent),
                      );
                    }
                    final selected = state.filters.contains(f);
                    return FilterChip(
                      label: Text(f.label),
                      selected: selected,
                      onSelected: (_) => controller.toggle(f),
                      labelStyle: text.labelMedium?.copyWith(
                        color: selected ? AppColors.onInk : AppColors.ink,
                      ),
                      backgroundColor: AppColors.surfaceMuted,
                      side: BorderSide(
                        color: selected ? AppColors.ink : Colors.transparent,
                      ),
                    );
                  },
                ),
              ),
            ),

            // Cities, while the Pakistan filter is on
            if (state.filters.contains(ExploreFilter.pakistan))
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.screenHorizontal,
                      ),
                      child: Text(
                        'City in Pakistan',
                        style: text.labelMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 60,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.screenHorizontal,
                          AppSpacing.sm,
                          AppSpacing.screenHorizontal,
                          AppSpacing.md,
                        ),
                        itemCount: pakistanCities.length + 2,
                        separatorBuilder: (_, _) =>
                            const SizedBox(width: AppSpacing.sm),
                        itemBuilder: (context, i) {
                          if (i == pakistanCities.length + 1) {
                            return ActionChip(
                              avatar: const Icon(
                                Icons.search_rounded,
                                size: 18,
                              ),
                              label: const Text('More cities'),
                              onPressed: () => CityPickerSheet.show(context),
                              backgroundColor: AppColors.surfaceMuted,
                              side: const BorderSide(color: Colors.transparent),
                            );
                          }
                          final city = i == 0 ? null : pakistanCities[i - 1];
                          final selected = state.city == city;
                          return ChoiceChip(
                            label: Text(city ?? 'All cities'),
                            selected: selected,
                            showCheckmark: false,
                            onSelected: (_) => controller.setCity(city),
                            labelStyle: text.labelMedium?.copyWith(
                              color: selected ? AppColors.onInk : AppColors.ink,
                            ),
                            backgroundColor: AppColors.surfaceMuted,
                            selectedColor: AppColors.ink,
                            side: BorderSide(
                              color: selected
                                  ? AppColors.ink
                                  : Colors.transparent,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),

            // Result count + sort
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenHorizontal,
                  0,
                  AppSpacing.sm,
                  AppSpacing.sm,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: AppDurations.fast,
                        layoutBuilder: (current, previous) => Stack(
                          alignment: Alignment.centerLeft,
                          children: [...previous, ?current],
                        ),
                        child: Text(
                          results.whenOrNull(
                                data: (j) =>
                                    '${j.length} ${j.length == 1 ? 'job' : 'jobs'} '
                                    '${cityLabel == null ? 'found' : 'in $cityLabel'}',
                              ) ??
                              'Searching…',
                          key: ValueKey(results.value?.length),
                          style: text.titleMedium,
                        ),
                      ),
                    ),
                    _SortMenu(value: state.sort, onChanged: controller.setSort),
                  ],
                ),
              ),
            ),

            // Results
            AsyncJobSliver(
              value: results.whenData((jobs) => jobs.take(_visible).toList()),
              skeletonCount: 3,
              onRetry: () {
                ref.invalidate(allJobsProvider);
                ref.invalidate(jobSearchProvider);
              },
              empty: cityLabel != null
                  ? EmptyStateView(
                      compact: true,
                      icon: Icons.location_off_outlined,
                      title: 'No jobs in $cityLabel yet',
                      message:
                          'Try another city, or clear the city to see all jobs.',
                      actionLabel: 'Clear city',
                      onAction: () => controller.setCity(null),
                    )
                  : EmptyStateView(
                      compact: true,
                      icon: Icons.search_off_rounded,
                      title: 'No jobs match',
                      message:
                          'Try a different keyword or remove a few filters.',
                      actionLabel: 'Clear search & filters',
                      onAction: () {
                        _search.clear();
                        controller.reset();
                      },
                    ),
            ),

            if (remaining > 0)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenHorizontal,
                  AppSpacing.lg,
                  AppSpacing.screenHorizontal,
                  0,
                ),
                sliver: SliverToBoxAdapter(
                  child: OutlinedButton.icon(
                    onPressed: () => setState(() => _visible += pageSize),
                    icon: const Icon(Icons.expand_more_rounded),
                    label: Text('Show more jobs ($remaining left)'),
                  ),
                ),
              ),

            // Source note (guide §3.9: show source and freshness)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenHorizontal,
                  AppSpacing.xl,
                  AppSpacing.screenHorizontal,
                  AppSpacing.xxxl,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 16,
                      color: AppColors.textTertiary,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'External listings are refreshed regularly and open on the '
                        'employer\'s site. "Apply in-app" jobs are posted directly on SharkHire.',
                        style: text.bodySmall?.copyWith(
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SortMenu extends StatelessWidget {
  const _SortMenu({required this.value, required this.onChanged});

  final ExploreSort value;
  final ValueChanged<ExploreSort> onChanged;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return PopupMenuButton<ExploreSort>(
      initialValue: value,
      onSelected: onChanged,
      tooltip: 'Sort jobs',
      color: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.lgAll),
      itemBuilder: (_) => [
        for (final s in ExploreSort.values)
          PopupMenuItem(
            value: s,
            child: Text(s.label, style: text.bodyMedium),
          ),
      ],
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.swap_vert_rounded,
                size: 18,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 4),
              Text(
                value.label,
                style: text.labelMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// First chip on Explore: "City" opens the picker; a chosen city shows its
/// name with a clear (x) button.
class _CityChip extends StatelessWidget {
  const _CityChip({
    required this.city,
    required this.onTap,
    required this.onClear,
  });

  final String? city;
  final VoidCallback onTap;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final chosen = city != null;
    final fg = chosen ? AppColors.onInk : AppColors.ink;
    return InputChip(
      avatar: Icon(Icons.place_outlined, size: 18, color: fg),
      label: Text(chosen ? city! : 'City'),
      tooltip: chosen ? 'Change city' : 'Choose a city',
      onPressed: onTap,
      onDeleted: chosen ? onClear : null,
      deleteIcon: Icon(Icons.close_rounded, size: 16, color: fg),
      deleteButtonTooltipMessage: 'Clear city',
      selected: chosen,
      showCheckmark: false,
      labelStyle: text.labelMedium?.copyWith(color: fg),
      backgroundColor: AppColors.surfaceMuted,
      selectedColor: AppColors.ink,
      side: BorderSide(color: chosen ? AppColors.ink : Colors.transparent),
    );
  }
}
