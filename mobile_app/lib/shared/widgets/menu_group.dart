import 'package:material_ui/material_ui.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import 'app_surface.dart';

/// One row in a [MenuGroup]: navigation, a switch, or a destructive action.
class MenuItem {
  const MenuItem(
    this.icon,
    this.label, {
    this.onTap,
    this.subtitle,
    this.trailing,
    this.destructive = false,
    this.switchValue,
    this.onSwitch,
  });

  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback? onTap;

  /// Small badge text on the right (e.g. a count).
  final String? trailing;
  final bool destructive;

  /// When set, the row shows a switch instead of a chevron.
  final bool? switchValue;
  final ValueChanged<bool>? onSwitch;
}

/// Titled card of rows with hairline dividers (settings-style list).
class MenuGroup extends StatelessWidget {
  const MenuGroup({super.key, this.title, required this.items});

  final String? title;
  final List<MenuItem> items;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null)
          Padding(
            padding: const EdgeInsets.only(
              left: AppSpacing.xs,
              bottom: AppSpacing.sm,
            ),
            child: Text(
              title!.toUpperCase(),
              style: text.labelSmall?.copyWith(
                color: AppColors.textTertiary,
                letterSpacing: 1.2,
              ),
            ),
          ),
        AppSurface(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (var i = 0; i < items.length; i++) ...[
                if (i > 0) const Divider(indent: 56),
                _MenuTile(item: items[i]),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({required this.item});

  final MenuItem item;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final color = item.destructive ? AppColors.error : AppColors.navy;

    // Switch rows use SwitchListTile so screen readers announce one labelled
    // toggle instead of an unlabelled switch inside a row.
    if (item.switchValue != null) {
      return SwitchListTile(
        value: item.switchValue!,
        onChanged: item.onSwitch,
        activeTrackColor: AppColors.ocean,
        secondary: Icon(item.icon, color: color, size: 22),
        title: Text(item.label, style: text.titleSmall?.copyWith(color: color)),
        subtitle: item.subtitle == null ? null : Text(item.subtitle!),
      );
    }

    Widget? trailing;
    if (!item.destructive) {
      trailing = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (item.trailing != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: const BoxDecoration(
                color: AppColors.oceanTint,
                borderRadius: AppRadius.pillAll,
              ),
              child: Text(
                item.trailing!,
                style: text.labelSmall?.copyWith(color: AppColors.oceanDeep),
              ),
            ),
          const SizedBox(width: 4),
          const Icon(
            Icons.chevron_right_rounded,
            color: AppColors.textTertiary,
          ),
        ],
      );
    }

    return ListTile(
      onTap: item.onTap,
      leading: Icon(item.icon, color: color, size: 22),
      title: Text(item.label, style: text.titleSmall?.copyWith(color: color)),
      subtitle: item.subtitle == null ? null : Text(item.subtitle!),
      trailing: trailing,
    );
  }
}
