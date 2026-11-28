import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';

/// "Unlock Remote Job Opportunities!" – shown when a free user taps the
/// Remote filter, or when the backend answers PRO_FEATURE_REQUIRED.
/// "Upgrade to Pro" opens the existing subscription screen.
Future<void> showRemoteProDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    useRootNavigator: true,
    builder: (dialog) {
      final text = Theme.of(dialog).textTheme;
      return AlertDialog(
        icon: const Icon(Icons.public_rounded, color: AppColors.teal, size: 32),
        title: const Text('Unlock Remote Job Opportunities!'),
        content: Text(
          'Remote job search is exclusively available to Pro members. '
          'Upgrade to Pro to explore remote opportunities from around the world.',
          style: text.bodyMedium?.copyWith(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialog).pop(),
            child: const Text('Maybe Later'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(dialog).pop();
              context.push(AppRoutes.subscription);
            },
            child: const Text('Upgrade to Pro'),
          ),
        ],
      );
    },
  );
}
