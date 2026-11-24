// Light / dark appearance.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sharkhire/core/theme/app_colors.dart';
import 'package:sharkhire/core/theme/app_theme.dart';
import 'package:sharkhire/core/theme/theme_mode_provider.dart';
import 'package:sharkhire/features/settings/presentation/screens/settings_screens.dart';
import 'package:sharkhire/shared/widgets/form_fields.dart';

import 'helpers.dart';

class _MemoryStore implements ThemePreferenceStore {
  ThemeMode? saved;
  @override
  Future<ThemeMode?> read() async => saved;
  @override
  Future<void> write(ThemeMode mode) async => saved = mode;
}

void main() {
  tearDown(() => AppColors.useDark(false));

  test('each theme switches the palette', () {
    final light = AppTheme.light;
    expect(light.brightness, Brightness.light);
    expect(AppColors.isDark, isFalse);
    final lightCanvas = AppColors.canvas;

    final dark = AppTheme.dark;
    expect(dark.brightness, Brightness.dark);
    expect(AppColors.isDark, isTrue);
    expect(AppColors.canvas, isNot(lightCanvas));
    expect(dark.scaffoldBackgroundColor, AppColors.canvas);
    // Text stays readable: light ink on the dark canvas.
    expect(AppColors.ink.computeLuminance(), greaterThan(0.7));
    expect(AppColors.canvas.computeLuminance(), lessThan(0.05));
  });

  test('system mode follows the device', () {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    expect(c.read(themeModeProvider), ThemeMode.system);
    final device = c.read(platformBrightnessProvider);
    expect(c.read(isDarkThemeProvider), device == Brightness.dark);
    c.read(themeModeProvider.notifier).set(ThemeMode.dark);
    expect(c.read(isDarkThemeProvider), isTrue);
    c.read(themeModeProvider.notifier).set(ThemeMode.light);
    expect(c.read(isDarkThemeProvider), isFalse);
  });

  testWidgets('choosing Dark in Settings switches the app and saves it', (
    tester,
  ) async {
    usePhone(tester);
    final store = _MemoryStore();
    await launchToSeekerHome(
      tester,
      overrides: [themePreferenceStoreProvider.overrideWithValue(store)],
    );
    await tester.tap(find.text('Profile').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    expect(find.byType(SettingsScreen), findsOneWidget);

    await tester.tap(find.text('Theme'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dark').last);
    await tester.pumpAndSettle();
    expect(AppColors.isDark, isTrue);
    expect(store.saved, ThemeMode.dark);
    // Still on Settings after the rebuild.
    expect(find.byType(SettingsScreen), findsOneWidget);
    final scaffold = tester.widget<Scaffold>(
      find.descendant(
        of: find.byType(SettingsScreen),
        matching: find.byType(Scaffold),
      ),
    );
    expect(scaffold.backgroundColor ?? AppColors.canvas, AppColors.canvas);

    await tester.tap(find.text('Theme'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Light').last);
    await tester.pumpAndSettle();
    expect(AppColors.isDark, isFalse);
    expect(store.saved, ThemeMode.light);
  });

  testWidgets('the app opens in the saved dark theme without errors', (
    tester,
  ) async {
    usePhone(tester);
    await launchToSeekerHome(
      tester,
      overrides: [initialThemeModeProvider.overrideWithValue(ThemeMode.dark)],
    );
    expect(AppColors.isDark, isTrue);
    for (final tab in ['Explore', 'Saved', 'Profile', 'Home']) {
      await tester.tap(find.text(tab).last);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: tab);
    }
  });

  testWidgets('status banner keeps its words on a neutral card', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(
          body: InlineBanner(
            tone: BannerTone.success,
            title: 'Subscription active',
            message: 'Renews on 21 Dec 2026.',
          ),
        ),
      ),
    );
    final title = tester.widget<Text>(find.text('Subscription active'));
    expect(title.style?.color, AppColors.textPrimary);
    final box = tester.widget<Container>(
      find
          .ancestor(
            of: find.text('Subscription active'),
            matching: find.byType(Container),
          )
          .last,
    );
    final deco = box.decoration! as BoxDecoration;
    expect(deco.color, AppColors.surface);
  });
}
