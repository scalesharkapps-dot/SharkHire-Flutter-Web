import 'package:material_ui/material_ui.dart';

import '../../../../core/theme/app_colors.dart';

/// Label for a filter that needs Pro: lock icon, the name and a small
/// "PRO" tag. Used on the Remote filter for free users.
class ProLockedLabel extends StatelessWidget {
  const ProLockedLabel(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Semantics(
      label: '$label, Pro feature',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.lock_outline_rounded,
            size: 15,
            color: AppColors.textSecondary,
          ),
          const SizedBox(width: 5),
          Text(label),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(
              color: AppColors.teal.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'PRO',
              style: text.labelSmall?.copyWith(
                color: AppColors.teal,
                fontWeight: FontWeight.w700,
                fontSize: 10,
                letterSpacing: 0.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
