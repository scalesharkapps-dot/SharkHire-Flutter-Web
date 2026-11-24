import 'package:material_ui/material_ui.dart';

import '../../core/theme/app_colors.dart';

/// Initials in a brand-tinted circle (people, candidates, admins).
class PersonAvatar extends StatelessWidget {
  const PersonAvatar({
    super.key,
    required this.initials,
    this.size = 44,
    this.grey = false,
  });

  final String initials;
  final double size;

  /// Neutral grey circle instead of the brand tint.
  final bool grey;

  @override
  Widget build(BuildContext context) {
    final seed = initials.codeUnits.fold<int>(0, (s, c) => s + c);
    final palette = [
      (AppColors.oceanTint, AppColors.oceanDeep),
      (AppColors.cyanTint, AppColors.ocean),
      (AppColors.surfaceMuted, AppColors.slate),
    ];
    final (bg, fg) = grey
        ? (AppColors.surfaceMuted, AppColors.textSecondary)
        : palette[seed % palette.length];
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
      child: Text(
        initials,
        style: TextStyle(
          fontFamily: 'Archivo',
          fontWeight: FontWeight.w700,
          fontSize: size * 0.36,
          color: fg,
        ),
      ),
    );
  }
}
