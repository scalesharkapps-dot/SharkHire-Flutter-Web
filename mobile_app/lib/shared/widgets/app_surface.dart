import 'package:material_ui/material_ui.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import 'pressable.dart';

/// The standard SharkHire card surface: white, 16px corners, hairline border
/// and a soft navy-tinted shadow. Use it for every card-like container so
/// elevation stays consistent across screens.
/// Marker default: "the theme's border colour" (resolved at build).
const Color _themeBorder = Color(0x00FFFFFE);

class AppSurface extends StatelessWidget {
  const AppSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.onTap,
    this.color,
    this.borderColor = _themeBorder,
    this.radius = AppRadius.xlAll,
    this.elevated = true,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? color;
  final Color? borderColor;
  final BorderRadius radius;
  final bool elevated;

  @override
  Widget build(BuildContext context) {
    final surface = DecoratedBox(
      decoration: BoxDecoration(
        color: color ?? AppColors.surface,
        borderRadius: radius,
        border: borderColor == null
            ? null
            : Border.all(
                color: identical(borderColor, _themeBorder)
                    ? AppColors.border
                    : borderColor!,
              ),
        boxShadow: elevated ? AppColors.cardShadow : null,
      ),
      child: Material(
        type: MaterialType.transparency,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );

    return onTap == null ? surface : Pressable(child: surface);
  }
}
