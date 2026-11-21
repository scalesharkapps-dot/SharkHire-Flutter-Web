import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/constants/app_constants.dart';
import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_mode_provider.dart';
import 'features/subscription/presentation/widgets/subscription_widgets.dart';

/// Root widget: wires the global theme and router together.
class SharkHireApp extends ConsumerWidget {
  const SharkHireApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final dark = ref.watch(isDarkThemeProvider);
    // Building the theme also switches AppColors to that palette.
    final theme = AppTheme.build(dark: dark);

    // A new key rebuilds every screen with the new palette; the router
    // keeps the user on the same page.
    return KeyedSubtree(
      key: ValueKey(dark),
      child: MaterialApp.router(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: theme,
        themeMode: dark ? ThemeMode.dark : ThemeMode.light,
        darkTheme: dark ? theme : null,
        routerConfig: router,
        builder: (context, child) => SubscriptionResumeRefresher(
          child: child ?? const SizedBox.shrink(),
        ),
      ),
    );
  }
}
