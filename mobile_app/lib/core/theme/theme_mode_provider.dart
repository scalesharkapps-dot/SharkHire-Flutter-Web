import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:material_ui/material_ui.dart';

/// Where the chosen appearance (system / light / dark) is kept on the
/// device. Failures are ignored: the app then follows the system setting.
abstract interface class ThemePreferenceStore {
  Future<ThemeMode?> read();
  Future<void> write(ThemeMode mode);
}

class SecureThemePreferenceStore implements ThemePreferenceStore {
  const SecureThemePreferenceStore([
    this._storage = const FlutterSecureStorage(),
  ]);

  final FlutterSecureStorage _storage;
  static const _key = 'sharkhire.theme_mode';

  @override
  Future<ThemeMode?> read() async {
    try {
      final v = await _storage.read(key: _key);
      return ThemeMode.values.where((m) => m.name == v).firstOrNull;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> write(ThemeMode mode) async {
    try {
      await _storage.write(key: _key, value: mode.name);
    } catch (_) {
      // Not saved: the choice still applies until the app closes.
    }
  }
}

final themePreferenceStoreProvider = Provider<ThemePreferenceStore>(
  (ref) => const SecureThemePreferenceStore(),
);

/// The appearance saved on this device, read once in `main` before the
/// first frame so the app doesn't flash the wrong theme.
final initialThemeModeProvider = Provider<ThemeMode>((ref) => ThemeMode.system);

/// The user's appearance choice: follow the system, or always light / dark.
class ThemeModeController extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ref.read(initialThemeModeProvider);

  void set(ThemeMode mode) {
    if (mode == state) return;
    state = mode;
    ref.read(themePreferenceStoreProvider).write(mode);
  }
}

final themeModeProvider = NotifierProvider<ThemeModeController, ThemeMode>(
  ThemeModeController.new,
);

/// The device's light / dark setting, kept current while the app runs.
class PlatformBrightnessController extends Notifier<Brightness>
    with WidgetsBindingObserver {
  @override
  Brightness build() {
    final binding = WidgetsBinding.instance;
    binding.addObserver(this);
    ref.onDispose(() => binding.removeObserver(this));
    return binding.platformDispatcher.platformBrightness;
  }

  @override
  void didChangePlatformBrightness() {
    state = WidgetsBinding.instance.platformDispatcher.platformBrightness;
  }
}

final platformBrightnessProvider =
    NotifierProvider<PlatformBrightnessController, Brightness>(
      PlatformBrightnessController.new,
    );

/// Whether the dark theme is showing right now.
final isDarkThemeProvider = Provider<bool>((ref) {
  return switch (ref.watch(themeModeProvider)) {
    ThemeMode.dark => true,
    ThemeMode.light => false,
    ThemeMode.system =>
      ref.watch(platformBrightnessProvider) == Brightness.dark,
  };
});
