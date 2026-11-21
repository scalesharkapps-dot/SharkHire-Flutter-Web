import 'package:material_ui/material_ui.dart';

import 'app_colors.dart';

/// Brand typefaces, matching thescaleshark.io:
/// * **Archivo Black** – brand moments only (splash, welcome hero)
/// * **Archivo** – titles, labels, buttons
/// * **Hind** – body copy
///
/// Fonts are bundled in `assets/fonts/` (SIL Open Font License),
/// so they render offline with no runtime download.
abstract final class AppFonts {
  static const String display = 'ArchivoBlack';
  static const String label = 'Archivo';
  static const String body = 'Hind';
}

abstract final class AppTypography {
  static TextTheme textTheme() {
    const display = AppFonts.display;
    const label = AppFonts.label;
    const body = AppFonts.body;
    final color = AppColors.textPrimary;

    return TextTheme(
      // Large brand moments (splash, onboarding hero).
      displayLarge: TextStyle(
        fontFamily: display,
        fontSize: 44,
        height: 1.1,
        letterSpacing: -0.5,
        color: color,
      ),
      displayMedium: TextStyle(
        fontFamily: display,
        fontSize: 36,
        height: 1.12,
        letterSpacing: -0.4,
        color: color,
      ),
      displaySmall: TextStyle(
        fontFamily: display,
        fontSize: 30,
        height: 1.15,
        letterSpacing: -0.3,
        color: color,
      ),

      // Screen and section headings.
      // Calm, editorial headings (Archivo Bold, tight tracking) – the
      // heavy display face is kept for brand moments only.
      headlineLarge: TextStyle(
        fontFamily: label,
        fontWeight: FontWeight.w700,
        fontSize: 28,
        height: 1.2,
        letterSpacing: -0.6,
        color: color,
      ),
      headlineMedium: TextStyle(
        fontFamily: label,
        fontWeight: FontWeight.w700,
        fontSize: 24,
        height: 1.22,
        letterSpacing: -0.5,
        color: color,
      ),
      // Section titles use Archivo Bold – calmer than Archivo Black.
      headlineSmall: TextStyle(
        fontFamily: label,
        fontWeight: FontWeight.w700,
        fontSize: 20,
        height: 1.25,
        letterSpacing: -0.4,
        color: color,
      ),

      // Card titles, app bar titles, list headers.
      titleLarge: TextStyle(
        fontFamily: label,
        fontWeight: FontWeight.w700,
        fontSize: 20,
        height: 1.3,
        color: color,
      ),
      titleMedium: TextStyle(
        fontFamily: label,
        fontWeight: FontWeight.w600,
        fontSize: 17,
        height: 1.3,
        letterSpacing: -0.2,
        color: color,
      ),
      titleSmall: TextStyle(
        fontFamily: label,
        fontWeight: FontWeight.w600,
        fontSize: 15,
        height: 1.3,
        color: color,
      ),

      // Body copy.
      bodyLarge: TextStyle(
        fontFamily: body,
        fontWeight: FontWeight.w400,
        fontSize: 17,
        height: 1.45,
        color: color,
      ),
      bodyMedium: TextStyle(
        fontFamily: body,
        fontWeight: FontWeight.w400,
        fontSize: 15,
        height: 1.45,
        color: color,
      ),
      bodySmall: TextStyle(
        fontFamily: body,
        fontWeight: FontWeight.w400,
        fontSize: 13,
        height: 1.4,
        color: AppColors.textSecondary,
      ),

      // Buttons, chips, tabs, metadata.
      labelLarge: TextStyle(
        fontFamily: label,
        fontWeight: FontWeight.w600,
        fontSize: 16,
        height: 1.2,
        color: color,
      ),
      labelMedium: TextStyle(
        fontFamily: label,
        fontWeight: FontWeight.w600,
        fontSize: 13,
        height: 1.2,
        color: color,
      ),
      labelSmall: TextStyle(
        fontFamily: label,
        fontWeight: FontWeight.w600,
        fontSize: 11,
        height: 1.2,
        letterSpacing: 0.3,
        color: color,
      ),
    );
  }
}
