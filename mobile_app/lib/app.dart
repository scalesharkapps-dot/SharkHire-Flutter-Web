import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/constants/app_constants.dart';
import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/subscription/presentation/widgets/subscription_widgets.dart';

/// Root widget: wires the global theme and router together.
class SharkHireApp extends ConsumerWidget {
  const SharkHireApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      // Dark mode is planned; until it is designed, keep the brand light theme.
      themeMode: ThemeMode.light,
      routerConfig: router,
      builder: (context, child) =>
          SubscriptionResumeRefresher(child: child ?? const SizedBox.shrink()),
    );
  }
}
