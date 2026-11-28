import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../providers/explore_providers.dart';
import '../../../subscription/presentation/providers/pro_access.dart';
import '../../../subscription/presentation/widgets/pro_badge.dart';
import '../../../subscription/presentation/widgets/pro_upgrade_dialog.dart';
import 'city_picker_sheet.dart';

/// Bottom sheet with grouped filters and sort.
class ExploreFilterSheet extends ConsumerWidget {
  const ExploreFilterSheet({super.key});

  static Future<void> show(BuildContext context) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    useSafeArea: true,
    builder: (_) => const ExploreFilterSheet(),
  );

  static const _groups = <(String, List<ExploreFilter>)>[
    ('Region', [ExploreFilter.pakistan, ExploreFilter.international]),
    (
      'Employment type',
      [
        ExploreFilter.fullTime,
        ExploreFilter.partTime,
        ExploreFilter.contract,
        ExploreFilter.internship,
      ],
    ),
    ('Work mode', [ExploreFilter.remote]),
    ('How to apply', [ExploreFilter.applyInApp]),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(exploreControllerProvider);
    final controller = ref.read(exploreControllerProvider.notifier);
    final count = ref.watch(exploreResultsProvider).value?.length;
    final pro = ref.watch(proAccessProvider);
    final text = Theme.of(context).textTheme;

    Widget chip(String label, bool selected, VoidCallback onTap) => ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      labelStyle: text.labelMedium?.copyWith(
        color: selected ? AppColors.onInk : AppColors.ink,
      ),
      side: BorderSide(color: selected ? AppColors.ink : AppColors.border),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenHorizontal,
        0,
        AppSpacing.screenHorizontal,
        AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text('Filters', style: text.headlineSmall)),
              TextButton(
                onPressed: state.activeFilterCount == 0
                    ? null
                    : controller.clearFilters,
                child: const Text('Reset'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text('Sort by', style: text.titleSmall),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final s in ExploreSort.values)
                chip(s.label, state.sort == s, () => controller.setSort(s)),
            ],
          ),
          for (final (title, filters) in _groups) ...[
            const SizedBox(height: AppSpacing.xl),
            Text(title, style: text.titleSmall),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final f in filters)
                  if (f == ExploreFilter.remote && !pro)
                    ChoiceChip(
                      label: ProLockedLabel(f.label),
                      selected: false,
                      onSelected: (_) => showRemoteProDialog(context),
                      labelStyle: text.labelMedium?.copyWith(
                        color: AppColors.ink,
                      ),
                      side: BorderSide(color: AppColors.border),
                    )
                  else
                    chip(
                      f.label,
                      state.filters.contains(f),
                      () => controller.toggle(f),
                    ),
              ],
            ),
            if (title == 'Region') ...[
              const SizedBox(height: AppSpacing.xl),
              Text('City', style: text.titleSmall),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  chip(
                    'All cities',
                    state.city == null,
                    () => controller.setCity(null),
                  ),
                  if (state.filters.contains(ExploreFilter.pakistan))
                    for (final c in pakistanCities)
                      chip(c, state.city == c, () => controller.setCity(c)),
                  // A chosen city outside the quick list stays visible.
                  if (state.city != null &&
                      !(state.filters.contains(ExploreFilter.pakistan) &&
                          pakistanCities.contains(state.city)))
                    chip(state.city!, true, () {}),
                  ActionChip(
                    avatar: const Icon(Icons.search_rounded, size: 18),
                    label: const Text('Search all cities'),
                    onPressed: () => CityPickerSheet.show(context),
                  ),
                ],
              ),
            ],
          ],
          const SizedBox(height: AppSpacing.xxl),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(count == null ? 'Show jobs' : 'Show $count jobs'),
            ),
          ),
        ],
      ),
    );
  }
}
