import 'package:material_ui/material_ui.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/app_search_bar.dart';

/// Top of Home: date and page title, job search and the user's job-search
/// statistics. Sits on the page background and stays quiet, so the job
/// cards and their fit scores carry the page.
class HomeHeader extends StatelessWidget {
  const HomeHeader({
    super.key,
    required this.firstName,
    required this.initials,
    required this.strongMatches,
    required this.savedCount,
    required this.appliedCount,
    this.hasUnread = false,
    this.onSearchTap,
    this.onNotificationsTap,
    this.onAvatarTap,
    this.onSavedTap,
    this.onAppliedTap,
  });

  final String firstName;
  final String initials;
  final int strongMatches;
  final int savedCount;
  final int appliedCount;
  final bool hasUnread;
  final VoidCallback? onSearchTap;
  final VoidCallback? onNotificationsTap;
  final VoidCallback? onAvatarTap;
  final VoidCallback? onSavedTap;
  final VoidCallback? onAppliedTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final topInset = MediaQuery.paddingOf(context).top;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.screenHorizontal,
        topInset + AppSpacing.md,
        AppSpacing.screenHorizontal,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _dateLabel(DateTime.now()),
                      style: text.labelMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Your matches',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.headlineMedium?.copyWith(
                        color: AppColors.ink,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              _HeaderIconButton(
                icon: Icons.notifications_none_rounded,
                tooltip: 'Notifications',
                showDot: hasUnread,
                onTap: onNotificationsTap,
              ),
              const SizedBox(width: AppSpacing.xs),
              _Avatar(initials: initials, onTap: onAvatarTap),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          AppSearchBar(hint: 'Search jobs', onTap: onSearchTap),
          const SizedBox(height: AppSpacing.lg),

          Row(
            children: [
              Flexible(
                child: _Stat(
                  value: '$strongMatches',
                  label: 'Top matches',
                  onTap: onSearchTap,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Flexible(
                child: _Stat(
                  value: '$savedCount',
                  label: 'Saved',
                  onTap: onSavedTap,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Flexible(
                child: _Stat(
                  value: '$appliedCount',
                  label: 'Applied',
                  onTap: onAppliedTap,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _dateLabel(DateTime d) {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${days[d.weekday - 1]}, ${d.day} ${months[d.month - 1]}';
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label, this.onTap});

  final String value;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.mdAll,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs,
          vertical: AppSpacing.xs,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedSwitcher(
              duration: AppDurations.medium,
              child: Text(
                value,
                key: ValueKey(value),
                style: text.headlineMedium?.copyWith(
                  fontSize: 22,
                  height: 1.1,
                  color: AppColors.ink,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: text.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.icon,
    required this.tooltip,
    this.onTap,
    this.showDot = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;
  final bool showDot;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox.square(
          dimension: 48,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(icon, color: AppColors.textSecondary, size: 22),
              if (showDot)
                Positioned(
                  top: 12,
                  right: 13,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppColors.teal,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.canvas, width: 1.5),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.initials, this.onTap});

  final String initials;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Profile',
      child: Material(
        color: AppColors.surfaceMuted,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: SizedBox.square(
            dimension: 48,
            child: Center(
              child: Text(
                initials,
                style: TextStyle(
                  fontFamily: AppFonts.label,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
