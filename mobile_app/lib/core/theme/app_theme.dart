import 'package:cupertino_ui/cupertino_ui.dart'
    show CupertinoPageTransitionsBuilder;
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

/// Global Material 3 theme for SharkHire, light and dark.
///
/// Building a theme also switches [AppColors] to that palette, so widgets
/// that read [AppColors] directly match it.
abstract final class AppTheme {
  static ThemeData get light => build(dark: false);
  static ThemeData get dark => build(dark: true);

  static ColorScheme _scheme(bool dark) => ColorScheme(
    brightness: dark ? Brightness.dark : Brightness.light,
    primary: AppColors.ink,
    onPrimary: AppColors.onInk,
    primaryContainer: AppColors.oceanTint,
    onPrimaryContainer: AppColors.ink,
    secondary: AppColors.ocean,
    onSecondary: dark ? AppColors.navy : AppColors.white,
    secondaryContainer: AppColors.oceanTint,
    onSecondaryContainer: AppColors.oceanDeep,
    tertiary: AppColors.cyan,
    onTertiary: AppColors.navy,
    tertiaryContainer: AppColors.cyanTint,
    onTertiaryContainer: AppColors.ink,
    error: AppColors.error,
    onError: dark ? AppColors.navy : AppColors.white,
    errorContainer: AppColors.errorTint,
    onErrorContainer: dark ? const Color(0xFFFFD9D4) : const Color(0xFF7A1A12),
    surface: AppColors.surface,
    onSurface: AppColors.textPrimary,
    onSurfaceVariant: AppColors.textSecondary,
    surfaceContainerLowest: AppColors.surface,
    surfaceContainerLow: AppColors.surfaceSubtle,
    surfaceContainer: AppColors.canvas,
    surfaceContainerHigh: AppColors.surfaceMuted,
    surfaceContainerHighest: dark
        ? const Color(0xFF223244)
        : const Color(0xFFE5ECF2),
    outline: AppColors.borderStrong,
    outlineVariant: AppColors.border,
    shadow: dark ? const Color(0x66000000) : const Color(0x1A0E2134),
    scrim: dark ? const Color(0xB3000000) : const Color(0x990E2134),
    inverseSurface: AppColors.ink,
    onInverseSurface: AppColors.onInk,
    inversePrimary: AppColors.cyan,
    surfaceTint: Colors.transparent,
  );

  static ThemeData build({required bool dark}) {
    AppColors.useDark(dark);
    final scheme = _scheme(dark);
    final textTheme = AppTypography.textTheme();

    return ThemeData(
      useMaterial3: true,
      brightness: dark ? Brightness.dark : Brightness.light,
      colorScheme: scheme,
      textTheme: textTheme,
      fontFamily: AppFonts.body,
      scaffoldBackgroundColor: AppColors.canvas,
      splashFactory: InkRipple.splashFactory,
      highlightColor: AppColors.ink.withValues(alpha: 0.04),
      materialTapTargetSize: MaterialTapTargetSize.padded,

      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.canvas,
        foregroundColor: AppColors.ink,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleSpacing: AppSpacing.screenHorizontal,
        titleTextStyle: textTheme.headlineSmall,
        systemOverlayStyle:
            (dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark)
                .copyWith(statusBarColor: Colors.transparent),
      ),

      cardTheme: CardThemeData(
        color: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.xlAll,
          side: BorderSide(color: AppColors.border),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.ink,
          foregroundColor: AppColors.onInk,
          disabledBackgroundColor: AppColors.border,
          disabledForegroundColor: AppColors.textSecondary,
          minimumSize: const Size(64, 48),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
          textStyle: textTheme.labelLarge?.copyWith(fontSize: 15),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.ocean,
          foregroundColor: dark ? AppColors.navy : AppColors.white,
          elevation: 0,
          minimumSize: const Size(64, 48),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
          textStyle: textTheme.labelLarge?.copyWith(fontSize: 15),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.ink,
          backgroundColor: AppColors.surface,
          minimumSize: const Size(64, 48),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
          side: BorderSide(color: AppColors.borderStrong),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
          textStyle: textTheme.labelLarge?.copyWith(fontSize: 15),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.ocean,
          textStyle: textTheme.labelMedium?.copyWith(fontSize: 14),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
        ),
      ),

      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(foregroundColor: AppColors.ink),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md + 2,
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: AppColors.textTertiary,
        ),
        labelStyle: textTheme.bodyMedium?.copyWith(
          color: AppColors.textSecondary,
        ),
        prefixIconColor: AppColors.textSecondary,
        suffixIconColor: AppColors.textSecondary,
        border: OutlineInputBorder(
          borderRadius: AppRadius.mdAll,
          borderSide: BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.mdAll,
          borderSide: BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.mdAll,
          borderSide: BorderSide(color: AppColors.ocean, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.mdAll,
          borderSide: BorderSide(color: AppColors.error),
        ),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surface,
        selectedColor: AppColors.ink,
        disabledColor: AppColors.surfaceSubtle,
        checkmarkColor: AppColors.onInk,
        side: BorderSide(color: AppColors.border),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
        labelStyle: textTheme.labelMedium,
        secondaryLabelStyle: textTheme.labelMedium?.copyWith(
          color: AppColors.onInk,
        ),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
        showCheckmark: false,
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        height: 64,
        // Quiet navigation: colour and weight mark the active tab, no pill.
        indicatorColor: Colors.transparent,
        overlayColor: WidgetStateProperty.all(Colors.transparent),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return textTheme.labelSmall?.copyWith(
            fontSize: 12,
            letterSpacing: 0,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? AppColors.ink : AppColors.textTertiary,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            size: 24,
            color: selected ? AppColors.ink : AppColors.textTertiary,
          );
        }),
      ),

      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: AppColors.surface,
        elevation: 0,
        indicatorColor: AppColors.surfaceSubtle,
        indicatorShape: const RoundedRectangleBorder(
          borderRadius: AppRadius.mdAll,
        ),
        selectedIconTheme: IconThemeData(color: AppColors.ink, size: 22),
        unselectedIconTheme: IconThemeData(
          color: AppColors.textTertiary,
          size: 22,
        ),
        selectedLabelTextStyle: textTheme.labelLarge?.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: AppColors.ink,
        ),
        unselectedLabelTextStyle: textTheme.labelLarge?.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColors.textSecondary,
        ),
      ),

      listTileTheme: ListTileThemeData(
        iconColor: AppColors.ink,
        titleTextStyle: textTheme.titleSmall,
        subtitleTextStyle: textTheme.bodySmall,
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        minVerticalPadding: AppSpacing.md,
      ),

      dividerTheme: DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 1,
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: AppColors.borderStrong,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: dark ? AppColors.surfaceMuted : AppColors.navy,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: dark ? AppColors.ink : AppColors.white,
        ),
        actionTextColor: AppColors.cyan,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
        insetPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: AppColors.ocean,
        linearTrackColor: AppColors.oceanTint,
        circularTrackColor: AppColors.oceanTint,
      ),

      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}
