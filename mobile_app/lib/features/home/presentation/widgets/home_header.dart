import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/date_formatters.dart';
import '../../../../shared/widgets/app_search_bar.dart';

/// Top of Home: brand row, greeting, job search and the user's job-search
/// statistics. Light and quiet so the jobs below carry the page.
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

    final divider = VerticalDivider(
      width: 1,
      indent: 6,
      endIndent: 6,
      color: AppColors.bandLine,
    );

    // Signal: the navy band carries the page's identity; jobs sit below it.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Container(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.screenHorizontal,
          topInset + AppSpacing.md,
          AppSpacing.screenHorizontal,
          AppSpacing.xl,
        ),
        color: AppColors.band,
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
                          color: AppColors.bandMuted,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${DateFormatters.greeting()}, $firstName.',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: text.headlineMedium?.copyWith(
                          color: AppColors.bandInk,
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
                const SizedBox(width: AppSpacing.sm),
                _Avatar(initials: initials, onTap: onAvatarTap),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            // Search entry
            AppSearchBar(
              hint: 'Search jobs, companies or skills',
              onTap: onSearchTap,
              dark: AppColors.isDark,
            ),
            const SizedBox(height: AppSpacing.lg),

            // Statistics strip, on the band.
            DecoratedBox(
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.bandLine)),
              ),
              child: Padding(
                padding: const EdgeInsets.only(top: AppSpacing.md),
                child: IntrinsicHeight(
                  child: Row(
                    children: [
                      Expanded(
                        child: _Stat(
                          value: '$strongMatches',
                          label: 'Top matches',
                          highlight: true,
                          onTap: onSearchTap,
                        ),
                      ),
                      divider,
                      Expanded(
                        child: _Stat(
                          value: '$savedCount',
                          label: 'Saved',
                          onTap: onSavedTap,
                        ),
                      ),
                      divider,
                      Expanded(
                        child: _Stat(
                          value: '$appliedCount',
                          label: 'Applied',
                          onTap: onAppliedTap,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
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
  const _Stat({
    required this.value,
    required this.label,
    this.onTap,
    this.highlight = false,
  });

  final String value;
  final String label;
  final VoidCallback? onTap;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.lgAll,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
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
                  fontSize: 24,
                  height: 1.1,
                  color: highlight ? AppColors.teal : AppColors.bandInk,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: text.bodySmall?.copyWith(color: AppColors.bandMuted),
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
      child: Material(
        color: AppColors.bandSoft,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.lgAll),
        child: InkWell(
          onTap: onTap,
          customBorder: const RoundedRectangleBorder(
            borderRadius: AppRadius.lgAll,
          ),
          child: SizedBox.square(
            dimension: 48,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(icon, color: AppColors.bandInk, size: 22),
                if (showDot)
                  Positioned(
                    top: 10,
                    right: 11,
                    child: Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        color: AppColors.teal,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.bandSoft, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
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
        color: AppColors.bandSoft,
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
                  color: AppColors.bandInk,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
