import 'package:material_ui/material_ui.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/date_formatters.dart';
import '../../../../shared/widgets/app_search_bar.dart';
import '../../../../shared/widgets/brand_logo.dart';

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

    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.screenHorizontal,
        topInset + AppSpacing.md,
        AppSpacing.screenHorizontal,
        AppSpacing.xl,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Brand row
          Row(
            children: [
              const SharkMark(size: 30),
              const SizedBox(width: AppSpacing.sm),
              const Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: SharkHireWordmark(fontSize: 19),
                  ),
                ),
              ),
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
          const SizedBox(height: AppSpacing.xl),

          // Greeting
          Text(
            '${DateFormatters.greeting()}, $firstName',
            style: text.headlineMedium,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '$strongMatches strong matches',
                  style: TextStyle(
                    color: AppColors.ocean,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const TextSpan(text: ' for your profile today'),
              ],
            ),
            style: text.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Search entry
          AppSearchBar(
            hint: 'Search jobs, companies or skills',
            onTap: onSearchTap,
          ),
          const SizedBox(height: AppSpacing.md),

          // Statistics strip
          DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.surfaceSubtle,
              borderRadius: AppRadius.lgAll,
              border: Border.all(color: AppColors.border),
            ),
            child: IntrinsicHeight(
              child: Row(
                children: [
                  Expanded(
                    child: _Stat(
                      value: '$strongMatches',
                      label: 'Top matches',
                      onTap: onSearchTap,
                    ),
                  ),
                  const VerticalDivider(width: 1, indent: 12, endIndent: 12),
                  Expanded(
                    child: _Stat(
                      value: '$savedCount',
                      label: 'Saved',
                      onTap: onSavedTap,
                    ),
                  ),
                  const VerticalDivider(width: 1, indent: 12, endIndent: 12),
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
        ],
      ),
    );
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
      borderRadius: AppRadius.lgAll,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedSwitcher(
              duration: AppDurations.medium,
              child: Text(
                value,
                key: ValueKey(value),
                style: text.titleLarge?.copyWith(
                  height: 1.1,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: text.bodySmall,
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
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: SizedBox.square(
            dimension: 48,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(icon, color: AppColors.ink, size: 24),
                if (showDot)
                  Positioned(
                    top: 12,
                    right: 13,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.surface,
                          width: 1.5,
                        ),
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
        color: AppColors.ink,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: SizedBox.square(
            dimension: 48,
            child: Center(
              child: Text(
                initials,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppColors.onInk,
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
