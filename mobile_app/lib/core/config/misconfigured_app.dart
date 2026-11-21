import 'package:material_ui/material_ui.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_theme.dart';

/// Shown instead of the app when a production build is missing its server
/// settings, so a misconfigured build can never reach users with sample data.
/// Testers see this; store reviewers never should.
class MisconfiguredApp extends StatelessWidget {
  const MisconfiguredApp({super.key, required this.problem});

  final String problem;

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light,
    home: Builder(
      builder: (context) {
        final text = Theme.of(context).textTheme;
        return Scaffold(
          body: SafeArea(
            child: Padding(
              padding: AppSpacing.screenPadding,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.settings_suggest_outlined,
                    size: 40,
                    color: AppColors.ocean,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'This build is not configured',
                    style: text.headlineSmall,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Rebuild with the production settings file. $problem',
                    style: text.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ),
  );
}
