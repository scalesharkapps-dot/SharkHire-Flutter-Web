import 'package:material_ui/material_ui.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

/// Company logo tile. Until real logos come from the API it shows the
/// company initial on a brand-palette tint chosen deterministically from
/// the name, so the same company always looks the same.
class CompanyLogo extends StatelessWidget {
  const CompanyLogo({
    super.key,
    required this.name,
    this.size = 44,
    this.imageUrl,
    this.grey = false,
  });

  final String name;
  final double size;
  final String? imageUrl;

  /// Neutral grey tile instead of the brand tints.
  final bool grey;

  static List<(Color, Color)> get _palettes => [
    (AppColors.oceanTint, AppColors.oceanDeep),
    (AppColors.cyanTint, AppColors.ocean),
    (AppColors.surfaceMuted, AppColors.ink),
    (AppColors.surfaceMuted, AppColors.slate),
  ];

  @override
  Widget build(BuildContext context) {
    final seed = name.codeUnits.fold<int>(0, (sum, c) => sum + c);
    final (bg, fg) = grey
        ? (AppColors.surfaceMuted, AppColors.textSecondary)
        : _palettes[seed % _palettes.length];
    final radius = BorderRadius.circular(size * 0.28);

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: imageUrl == null ? bg : AppColors.white,
        borderRadius: radius,
        border: Border.all(color: AppColors.border),
      ),
      child: imageUrl != null
          ? Image.network(imageUrl!, fit: BoxFit.cover)
          : Text(
              name.isEmpty ? '?' : name.characters.first.toUpperCase(),
              style: TextStyle(
                fontFamily: 'Archivo',
                fontWeight: FontWeight.w700,
                fontSize: size * 0.42,
                height: 1,
                color: fg,
              ),
            ),
    );
  }
}

/// Small rounded label used for job attributes and sources.
class InfoPill extends StatelessWidget {
  const InfoPill({
    super.key,
    required this.label,
    this.icon,
    Color? background,
    Color? foreground,
    this.bordered = false,
  }) : _background = background,
       _foreground = foreground;

  /// "Apply in-app" – internal SharkHire job.
  const InfoPill.internal({super.key})
    : label = 'Apply in-app',
      icon = Icons.verified_outlined,
      _background = _oceanTint,
      _foreground = _oceanDeep,
      bordered = false;

  /// "External" – job from an external board; apply on the source site.
  const InfoPill.external({super.key})
    : label = 'External',
      icon = Icons.north_east_rounded,
      _background = null,
      _foreground = null,
      bordered = true;

  final String label;
  final IconData? icon;
  final Color? _background;
  final Color? _foreground;
  final bool bordered;

  // Markers for the theme's ocean tint / deep ocean (resolved at build).
  static const _oceanTint = Color(0x00000001);
  static const _oceanDeep = Color(0x00000002);

  Color get background => identical(_background, _oceanTint)
      ? AppColors.oceanTint
      : _background ?? AppColors.surfaceSubtle;

  Color get foreground => identical(_foreground, _oceanDeep)
      ? AppColors.oceanDeep
      : _foreground ?? AppColors.textSecondary;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: AppRadius.smAll,
        border: bordered ? Border.all(color: AppColors.border) : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: foreground),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontSize: 12,
                color: foreground,
                letterSpacing: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
