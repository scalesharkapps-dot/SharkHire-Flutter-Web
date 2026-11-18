import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../providers/session_provider.dart';

/// Asks before signing out, then clears the session (the router returns the
/// user to the welcome screen).
Future<void> confirmSignOut(BuildContext context, WidgetRef ref) async {
  final text = Theme.of(context).textTheme;
  final confirmed = await showModalBottomSheet<bool>(
    context: context,
    useRootNavigator: true,
    builder: (sheet) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenHorizontal,
          0,
          AppSpacing.screenHorizontal,
          AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Log out of SharkHire?', style: text.headlineSmall),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Your saved jobs and applications stay with your account.',
              style: text.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.xl),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.error),
              onPressed: () => Navigator.of(sheet).pop(true),
              child: const Text('Log out'),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextButton(
              onPressed: () => Navigator.of(sheet).pop(false),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    ),
  );
  if (confirmed ?? false) await ref.read(sessionProvider.notifier).signOut();
}
