import 'package:material_ui/material_ui.dart';

/// Consistent lightweight feedback helpers.
abstract final class AppFeedback {
  static void show(
    BuildContext context,
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 3),
          action: actionLabel == null
              ? null
              : SnackBarAction(
                  label: actionLabel,
                  onPressed: onAction ?? () {},
                ),
        ),
      );
  }

  /// For features scheduled in a later milestone.
  static void comingSoon(BuildContext context, String feature) =>
      show(context, '$feature is coming soon');
}
