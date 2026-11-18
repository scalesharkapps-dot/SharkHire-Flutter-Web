import 'package:material_ui/material_ui.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

/// SharkHire search field.
///
/// * Editable mode: pass [controller]/[onChanged].
/// * Entry-point mode: pass [onTap] and it renders as a button that opens
///   search (used on Home).
class AppSearchBar extends StatelessWidget {
  const AppSearchBar({
    super.key,
    this.hint = 'Job title, company or skill',
    this.controller,
    this.onChanged,
    this.onTap,
    this.onFilterTap,
    this.activeFilterCount = 0,
    this.leadingIcon = Icons.search_rounded,
    this.dark = false,
  });

  final String hint;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final VoidCallback? onFilterTap;
  final int activeFilterCount;
  final IconData leadingIcon;

  /// Translucent style for navy headers.
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final bg = dark ? AppColors.navySoft : AppColors.white;
    final fg = dark ? AppColors.textOnDarkMuted : AppColors.textTertiary;
    final iconColor = dark
        ? AppColors.textOnDarkMuted
        : AppColors.textSecondary;

    final field = onTap != null
        ? InkWell(
            onTap: onTap,
            borderRadius: AppRadius.lgAll,
            child: SizedBox(
              height: 48,
              child: Row(
                children: [
                  const SizedBox(width: AppSpacing.lg),
                  Icon(leadingIcon, size: 20, color: iconColor),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      hint,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.bodyMedium?.copyWith(color: fg),
                    ),
                  ),
                ],
              ),
            ),
          )
        : TextField(
            controller: controller,
            onChanged: onChanged,
            textInputAction: TextInputAction.search,
            style: text.bodyLarge,
            decoration: InputDecoration(
              hintText: hint,
              filled: false,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 13),
              prefixIcon: Icon(leadingIcon, size: 20, color: iconColor),
              suffixIcon: controller == null
                  ? null
                  : ValueListenableBuilder(
                      valueListenable: controller!,
                      builder: (context, value, _) => value.text.isEmpty
                          ? const SizedBox.shrink()
                          : IconButton(
                              tooltip: 'Clear',
                              icon: const Icon(Icons.close_rounded, size: 20),
                              onPressed: () {
                                controller!.clear();
                                onChanged?.call('');
                              },
                            ),
                    ),
            ),
          );

    return Row(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: bg,
              borderRadius: AppRadius.lgAll,
              border: Border.all(
                color: dark ? AppColors.navySoft : AppColors.borderStrong,
              ),
            ),
            child: Material(type: MaterialType.transparency, child: field),
          ),
        ),
        if (onFilterTap != null) ...[
          const SizedBox(width: AppSpacing.sm),
          _FilterButton(onTap: onFilterTap!, count: activeFilterCount),
        ],
      ],
    );
  }
}

class _FilterButton extends StatelessWidget {
  const _FilterButton({required this.onTap, required this.count});

  final VoidCallback onTap;
  final int count;

  @override
  Widget build(BuildContext context) {
    final active = count > 0;
    return Tooltip(
      message: active ? 'Filters, $count active' : 'Filters',
      child: Badge(
        isLabelVisible: active,
        label: Text('$count'),
        backgroundColor: AppColors.ocean,
        offset: const Offset(-2, 2),
        child: Material(
          color: active ? AppColors.navy : AppColors.white,
          shape: const RoundedRectangleBorder(
            borderRadius: AppRadius.lgAll,
            side: BorderSide(color: AppColors.borderStrong),
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: AppRadius.lgAll,
            child: SizedBox.square(
              dimension: 48,
              child: Icon(
                Icons.tune_rounded,
                size: 20,
                color: active ? AppColors.white : AppColors.navy,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
