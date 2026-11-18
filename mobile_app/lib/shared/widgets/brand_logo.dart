import 'package:material_ui/material_ui.dart';

import '../../core/constants/asset_paths.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

/// The official Scale Shark shark mark.
///
/// The source artwork sits on a white background, so on tinted surfaces it is
/// shown inside a white tile ([framed] = true) to keep edges clean.
class SharkMark extends StatelessWidget {
  const SharkMark({super.key, this.size = 40, this.framed = false});

  final double size;
  final bool framed;

  /// The exact image provider this widget renders at [size]. Pass it to
  /// `precacheImage` so the logo is decoded before it animates in.
  static ImageProvider providerFor(BuildContext context, double size) {
    // Small sizes use the 128px mark; large sizes use the full-resolution logo.
    final asset = size <= 48
        ? AssetPaths.scaleSharkMark
        : AssetPaths.scaleSharkLogo;
    final dpr = MediaQuery.devicePixelRatioOf(context);
    return ResizeImage(AssetImage(asset), width: (size * dpr).round());
  }

  @override
  Widget build(BuildContext context) {
    final image = Image(
      image: providerFor(context, size),
      width: size,
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
      semanticLabel: 'Scale Shark logo',
    );

    if (!framed) return image;

    return Container(
      padding: EdgeInsets.all(size * 0.08),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: AppRadius.mdAll,
        border: Border.all(color: AppColors.border),
      ),
      child: image,
    );
  }
}

/// The shark mark inside a white circular badge, for dark backgrounds.
class SharkBadge extends StatelessWidget {
  const SharkBadge({super.key, this.size = 120, this.glow = false});

  final double size;

  /// Soft cyan halo. Off by default: the brand mark stands on its own.
  final bool glow;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      // A square inscribed in the circle is ~70% of its diameter.
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.white,
        shape: BoxShape.circle,
        boxShadow: glow
            ? [
                BoxShadow(
                  color: AppColors.cyan.withValues(alpha: 0.35),
                  blurRadius: size * 0.35,
                  spreadRadius: size * 0.02,
                ),
              ]
            : null,
      ),
      child: SharkMark(size: size * 0.7),
    );
  }
}

/// "SharkHire" wordmark in Archivo Black: "Shark" in navy (or white when
/// [onDark] is true) followed by "Hire" in teal.
class SharkHireWordmark extends StatelessWidget {
  const SharkHireWordmark({super.key, this.fontSize = 28, this.onDark = false});

  final double fontSize;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontFamily: AppFonts.display,
      fontSize: fontSize,
      height: 1,
      letterSpacing: -0.02 * fontSize,
      color: onDark ? AppColors.white : AppColors.navy,
    );
    // A logotype: announced as one image, exempt from text-contrast rules.
    return Semantics(
      image: true,
      label: 'SharkHire',
      excludeSemantics: true,
      child: Text.rich(
        TextSpan(
          style: style,
          children: const [
            TextSpan(text: 'Shark'),
            TextSpan(
              text: 'Hire',
              style: TextStyle(color: AppColors.teal),
            ),
          ],
        ),
      ),
    );
  }
}
