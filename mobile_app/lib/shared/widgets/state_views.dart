import 'package:material_ui/material_ui.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

/// Brand illustration used by empty and error states: an icon in layered
/// ocean-tinted circles. Consistent everywhere instead of random artwork.
class StateIllustration extends StatelessWidget {
  const StateIllustration({
    super.key,
    required this.icon,
    Color? tone,
    Color? tint,
  }) : _tone = tone,
       _tint = tint;

  final IconData icon;
  final Color? _tone;
  final Color? _tint;

  @override
  Widget build(BuildContext context) {
    final tone = _tone ?? AppColors.ocean;
    final tint = _tint ?? AppColors.oceanTint;
    return SizedBox.square(
      dimension: 120,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: tint.withValues(alpha: 0.55),
            ),
          ),
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(shape: BoxShape.circle, color: tint),
          ),
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surface,
              boxShadow: AppColors.cardShadow,
            ),
            child: Icon(icon, size: 28, color: tone),
          ),
        ],
      ),
    );
  }
}

/// Friendly empty state with an optional primary action.
class EmptyStateView extends StatelessWidget {
  const EmptyStateView({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.compact = false,
    this.plain = false,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  /// Compact mode for use inside scroll views (no vertical centering).
  final bool compact;

  /// Quiet, left-aligned version without the illustration.
  final bool plain;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    if (plain) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenHorizontal,
          AppSpacing.xl,
          AppSpacing.screenHorizontal,
          AppSpacing.xxl,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: text.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            Text(
              message,
              style: text.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppSpacing.lg),
              FilledButton(
                onPressed: onAction,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.tonal,
                  foregroundColor: AppColors.ink,
                  minimumSize: const Size(0, 44),
                ),
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      );
    }
    final content = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xxxl,
        vertical: AppSpacing.xxl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          StateIllustration(icon: icon),
          const SizedBox(height: AppSpacing.xl),
          Text(title, style: text.headlineSmall, textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.sm),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 300),
            child: Text(
              message,
              style: text.bodyMedium?.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: AppSpacing.xxl),
            FilledButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
    return compact
        ? content
        : Center(child: SingleChildScrollView(child: content));
  }
}

/// Error state with a retry action.
class ErrorStateView extends StatelessWidget {
  const ErrorStateView({
    super.key,
    this.title = 'Something went wrong',
    this.message =
        'We couldn\'t load this right now. Check your connection and try again.',
    required this.onRetry,
    this.compact = false,
  });

  final String title;
  final String message;
  final VoidCallback onRetry;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final content = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xxxl,
        vertical: AppSpacing.xxl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          StateIllustration(
            icon: Icons.wifi_off_rounded,
            tone: AppColors.error,
            tint: AppColors.errorTint,
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(title, style: text.headlineSmall, textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.sm),
          Text(
            message,
            style: text.bodyMedium?.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xxl),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 20),
            label: const Text('Try again'),
          ),
        ],
      ),
    );
    return compact
        ? content
        : Center(child: SingleChildScrollView(child: content));
  }
}
