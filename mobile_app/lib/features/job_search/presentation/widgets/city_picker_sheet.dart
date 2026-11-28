import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../providers/explore_providers.dart';

/// Bottom sheet to choose the city for Explore: search, Pakistani and
/// international cities, any typed city, or "Any city" to clear it.
class CityPickerSheet extends ConsumerStatefulWidget {
  const CityPickerSheet({super.key});

  static Future<void> show(BuildContext context) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    useSafeArea: true,
    builder: (_) => const CityPickerSheet(),
  );

  @override
  ConsumerState<CityPickerSheet> createState() => _CityPickerSheetState();
}

class _CityPickerSheetState extends ConsumerState<CityPickerSheet> {
  final _search = TextEditingController();
  String _q = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _pick(String? city) {
    ref.read(exploreControllerProvider.notifier).setCity(city);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final current = ref.watch(exploreControllerProvider.select((s) => s.city));
    final q = _q.trim().toLowerCase();
    List<String> match(List<String> cities) => [
      for (final c in cities)
        if (c.toLowerCase().contains(q)) c,
    ];
    final pk = match(pakistanCities);
    final intl = match(internationalCities);
    final typed = _q.trim();
    final exact = [
      ...pakistanCities,
      ...internationalCities,
    ].any((c) => c.toLowerCase() == q);

    Widget tile(String city) {
      final selected = current?.toLowerCase() == city.toLowerCase();
      return ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(city),
        trailing: selected
            ? const Icon(Icons.check_rounded, color: AppColors.teal)
            : null,
        selected: selected,
        onTap: () => _pick(city),
      );
    }

    Widget heading(String label) => Padding(
      padding: const EdgeInsets.only(top: AppSpacing.lg, bottom: 2),
      child: Text(
        label,
        style: text.labelMedium?.copyWith(color: AppColors.textSecondary),
      ),
    );

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.8,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenHorizontal,
                0,
                AppSpacing.sm,
                AppSpacing.sm,
              ),
              child: Row(
                children: [
                  Expanded(child: Text('City', style: text.headlineSmall)),
                  TextButton(
                    onPressed: current == null ? null : () => _pick(null),
                    child: const Text('Clear'),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenHorizontal,
              ),
              child: TextField(
                controller: _search,
                autofocus: false,
                textInputAction: TextInputAction.search,
                decoration: const InputDecoration(
                  hintText: 'Search or type a city',
                  prefixIcon: Icon(Icons.search_rounded),
                ),
                onChanged: (v) => setState(() => _q = v),
                onSubmitted: (v) {
                  if (v.trim().isNotEmpty) _pick(v.trim());
                },
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenHorizontal,
                  AppSpacing.sm,
                  AppSpacing.screenHorizontal,
                  AppSpacing.xl,
                ),
                children: [
                  if (typed.isNotEmpty && !exact)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.place_outlined),
                      title: Text('Use "$typed"'),
                      onTap: () => _pick(typed),
                    ),
                  if (q.isEmpty)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Any city'),
                      selected: current == null,
                      trailing: current == null
                          ? const Icon(
                              Icons.check_rounded,
                              color: AppColors.teal,
                            )
                          : null,
                      onTap: () => _pick(null),
                    ),
                  if (pk.isNotEmpty) ...[
                    heading('Pakistan'),
                    for (final c in pk) tile(c),
                  ],
                  if (intl.isNotEmpty) ...[
                    heading('International'),
                    for (final c in intl) tile(c),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
