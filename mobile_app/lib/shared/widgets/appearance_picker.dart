import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/theme_mode_provider.dart';
import 'app_surface.dart';

/// "Appearance" setting: System, Light or Dark. Saved on this device.
class AppearancePicker extends ConsumerWidget {
  const AppearancePicker({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final mode = ref.watch(themeModeProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            left: AppSpacing.xs,
            bottom: AppSpacing.sm,
          ),
          child: Text(
            'APPEARANCE',
            style: text.labelSmall?.copyWith(
              color: AppColors.textTertiary,
              letterSpacing: 1.1,
            ),
          ),
        ),
        AppSurface(
          elevated: false,
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Row(
            children: [
              for (final (m, label, icon) in const [
                (ThemeMode.system, 'System', Icons.brightness_auto_outlined),
                (ThemeMode.light, 'Light', Icons.light_mode_outlined),
                (ThemeMode.dark, 'Dark', Icons.dark_mode_outlined),
              ])
                Expanded(
                  child: _Option(
                    label: label,
                    icon: icon,
                    selected: mode == m,
                    onTap: () => ref.read(themeModeProvider.notifier).set(m),
                  ),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xs,
            AppSpacing.sm,
            AppSpacing.xs,
            0,
          ),
          child: Text(
            'System follows your device\'s light or dark setting.',
            style: text.bodySmall,
          ),
        ),
      ],
    );
  }
}

class _Option extends StatelessWidget {
  const _Option({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final fg = selected ? AppColors.ink : AppColors.textSecondary;
    return Semantics(
      button: true,
      selected: selected,
      label: '$label appearance',
      excludeSemantics: true,
      child: Material(
        color: selected ? AppColors.surfaceMuted : Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.mdAll,
          side: BorderSide(
            color: selected ? AppColors.borderStrong : Colors.transparent,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          customBorder: const RoundedRectangleBorder(
            borderRadius: AppRadius.mdAll,
          ),
          child: SizedBox(
            height: 64,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 22, color: fg),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: text.labelMedium?.copyWith(
                    color: fg,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
