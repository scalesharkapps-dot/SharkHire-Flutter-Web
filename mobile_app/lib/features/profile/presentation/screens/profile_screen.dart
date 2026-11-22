import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/feedback.dart';
import '../../../../shared/models/app_user.dart';
import '../../../../shared/widgets/app_surface.dart';
import '../../../../shared/widgets/fade_in_up.dart';
import '../../../../shared/widgets/menu_group.dart';
import '../../../saved_jobs/presentation/providers/saved_jobs_provider.dart';
import '../../../../core/utils/date_formatters.dart';
import '../../../authentication/presentation/widgets/sign_out_sheet.dart';
import '../../../resume/data/models/resume_models.dart';
import '../../../notifications/presentation/providers/notifications_provider.dart';
import '../../../resume/presentation/providers/cv_provider.dart';
import '../../../subscription/presentation/providers/subscription_providers.dart';
import '../providers/current_user_provider.dart';

/// Profile hub: identity, CV, premium, activity and account settings
/// (project guide §3.10 "CV and profile" and "Other").
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final savedCount = ref.watch(savedJobIdsProvider).length;
    final text = Theme.of(context).textTheme;
    final unread = ref.watch(unreadNotificationsProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: ListView(
          padding: EdgeInsets.zero,
          children: [
            _ProfileBand(
              user: user,
              onEdit: () => context.push(AppRoutes.editProfile),
              onSettings: () => context.push(AppRoutes.settings),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenHorizontal,
                AppSpacing.lg,
                AppSpacing.screenHorizontal,
                AppSpacing.xxxl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FadeInUp(
                    delay: const Duration(milliseconds: 60),
                    child: const _CvCard(),
                  ),
                  if (AppConfig.showPremium) ...[
                    const SizedBox(height: AppSpacing.md),
                    FadeInUp(
                      delay: const Duration(milliseconds: 120),
                      child: ref.watch(subscriptionProvider).hasAccess
                          ? AppSurface(
                              onTap: () => context.push(AppRoutes.subscription),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.workspace_premium_rounded,
                                    color: AppColors.ocean,
                                  ),
                                  const SizedBox(width: AppSpacing.md),
                                  Expanded(
                                    child: Text(
                                      'Your subscription is active',
                                      style: text.titleSmall,
                                    ),
                                  ),
                                  Icon(
                                    Icons.chevron_right_rounded,
                                    color: AppColors.textTertiary,
                                  ),
                                ],
                              ),
                            )
                          : _PremiumCard(
                              onStart: () =>
                                  context.push(AppRoutes.subscription),
                            ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.xxl),
                  MenuGroup(
                    title: 'Job activity',
                    items: [
                      MenuItem(
                        Icons.psychology_outlined,
                        'CV & extracted skills',
                        onTap: () => ref.read(cvProvider).hasCv
                            ? context.push(AppRoutes.cvReview)
                            : context.push(AppRoutes.cvUpload),
                      ),
                      MenuItem(
                        Icons.send_outlined,
                        'Applications',
                        onTap: () => context.push(AppRoutes.applications),
                      ),
                      MenuItem(
                        Icons.bookmark_border_rounded,
                        'Saved jobs',
                        trailing: savedCount > 0 ? '$savedCount' : null,
                        onTap: () => context.go(AppRoutes.saved),
                      ),
                      MenuItem(
                        Icons.notifications_active_outlined,
                        'Job alerts',
                        onTap: () => context.push(AppRoutes.jobAlerts),
                      ),
                      MenuItem(
                        Icons.tune_rounded,
                        'Job preferences',
                        onTap: () => context.push(AppRoutes.jobPreferences),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  MenuGroup(
                    title: 'Account',
                    items: [
                      if (AppConfig.showPremium)
                        MenuItem(
                          Icons.workspace_premium_outlined,
                          'Subscription',
                          trailing: ref.watch(subscriptionProvider).hasAccess
                              ? 'Active'
                              : null,
                          onTap: () => context.push(AppRoutes.subscription),
                        ),
                      MenuItem(
                        Icons.notifications_none_rounded,
                        'Notifications',
                        trailing: unread > 0 ? '$unread' : null,
                        onTap: () => context.push(AppRoutes.notifications),
                      ),
                      MenuItem(
                        Icons.lock_outline_rounded,
                        'Privacy & security',
                        onTap: () => context.push(AppRoutes.privacy),
                      ),
                      MenuItem(
                        Icons.help_outline_rounded,
                        'Help & support',
                        onTap: () => context.push(AppRoutes.help),
                      ),
                      MenuItem(
                        Icons.settings_outlined,
                        'Settings',
                        onTap: () => context.push(AppRoutes.settings),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  MenuGroup(
                    items: [
                      MenuItem(
                        Icons.logout_rounded,
                        'Log out',
                        destructive: true,
                        onTap: () => confirmSignOut(context, ref),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  Center(
                    child: Text(
                      '${AppConstants.appName} v${AppConstants.appVersion}  ·  by ${AppConstants.companyName}',
                      style: text.bodySmall?.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Signal header band: avatar, name, role and profile strength on navy.
class _ProfileBand extends StatelessWidget {
  const _ProfileBand({
    required this.user,
    required this.onEdit,
    required this.onSettings,
  });

  final AppUser user;
  final VoidCallback onEdit;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final percent = (user.profileCompletion * 100).round();
    final subtitle = [
      if (user.headline != null) user.headline!,
      if (user.location != null) user.location!,
    ].join(' · ');

    Widget squareButton(IconData icon, String tooltip, VoidCallback onTap) =>
        Tooltip(
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
                child: Icon(icon, size: 21, color: AppColors.bandInk),
              ),
            ),
          ),
        );

    return Container(
      color: AppColors.band,
      padding: EdgeInsets.fromLTRB(
        AppSpacing.screenHorizontal,
        MediaQuery.paddingOf(context).top + AppSpacing.lg,
        AppSpacing.screenHorizontal,
        AppSpacing.xl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 66,
                height: 66,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppColors.teal,
                  borderRadius: BorderRadius.all(Radius.circular(16)),
                ),
                child: Text(
                  user.initials,
                  style: TextStyle(
                    fontFamily: AppFonts.display,
                    fontSize: 22,
                    color: AppColors.isDark ? AppColors.onInk : AppColors.navy,
                  ),
                ),
              ),
              const Spacer(),
              squareButton(Icons.edit_outlined, 'Edit profile', onEdit),
              const SizedBox(width: AppSpacing.sm),
              squareButton(Icons.settings_outlined, 'Settings', onSettings),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          InkWell(
            onTap: onEdit,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.fullName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.headlineMedium?.copyWith(
                    color: AppColors.bandInk,
                  ),
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.bodyMedium?.copyWith(
                      color: AppColors.bandMuted,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Profile strength',
                  style: text.bodySmall?.copyWith(color: AppColors.bandMuted),
                ),
              ),
              Text(
                '$percent%',
                style: text.labelMedium?.copyWith(
                  color: AppColors.teal,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: AppRadius.pillAll,
            child: LinearProgressIndicator(
              value: user.profileCompletion,
              minHeight: 5,
              color: AppColors.teal,
              backgroundColor: AppColors.bandLine,
            ),
          ),
        ],
      ),
    );
  }
}

class _CvCard extends ConsumerWidget {
  const _CvCard();

  Future<void> _remove(BuildContext context, WidgetRef ref) async {
    final ok = await showModalBottomSheet<bool>(
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
              Text(
                'Remove your CV?',
                style: Theme.of(sheet).textTheme.headlineSmall,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Recommendations will stop using it until you upload another CV.',
                style: Theme.of(sheet).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: AppColors.error),
                onPressed: () => Navigator.of(sheet).pop(true),
                child: const Text('Remove CV'),
              ),
              TextButton(
                onPressed: () => Navigator.of(sheet).pop(false),
                child: const Text('Cancel'),
              ),
            ],
          ),
        ),
      ),
    );
    if (!(ok ?? false)) return;
    try {
      await ref.read(cvProvider.notifier).remove();
      if (context.mounted) AppFeedback.show(context, 'CV removed');
    } catch (e) {
      if (context.mounted) AppFeedback.show(context, friendlyErrorMessage(e));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final cv = ref.watch(cvProvider).active;
    return AppSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: cv == null
                      ? AppColors.oceanTint
                      : AppColors.successTint,
                  borderRadius: AppRadius.lgAll,
                ),
                child: Icon(
                  cv == null ? Icons.description_outlined : Icons.task_rounded,
                  color: cv == null ? AppColors.ocean : AppColors.success,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cv?.fileName ?? 'Your CV',
                      style: text.titleSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      cv == null
                          ? 'No CV yet · PDF or DOCX'
                          : 'Active · ${CvRules.formatSize(cv.sizeBytes)} · uploaded ${DateFormatters.relativeAge(cv.uploadedAt).toLowerCase()}',
                      style: text.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (cv != null)
                IconButton(
                  tooltip: 'Remove CV',
                  onPressed: () => _remove(context, ref),
                  icon: Icon(
                    Icons.delete_outline_rounded,
                    color: AppColors.textTertiary,
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (cv != null) ...[
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => context.push(AppRoutes.cvReview),
                icon: const Icon(Icons.fact_check_outlined, size: 20),
                label: const Text('Review extracted profile'),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => context.push(AppRoutes.cvUpload),
              icon: const Icon(Icons.upload_rounded, size: 20),
              label: Text(cv != null ? 'Replace CV' : 'Upload CV'),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Icon(
                Icons.lock_outline_rounded,
                size: 14,
                color: AppColors.textTertiary,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Private. Only shared with an employer when you apply.',
                  style: text.bodySmall?.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PremiumCard extends StatelessWidget {
  const _PremiumCard({required this.onStart});

  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return AppSurface(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.workspace_premium_outlined,
                color: AppColors.ocean,
                size: 18,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'SHARKHIRE PREMIUM',
                style: text.labelSmall?.copyWith(
                  color: AppColors.ocean,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Try ${AppConstants.freeTrialDays} days free',
            style: text.headlineSmall,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'CV-based recommendations, Pakistan and international job leads, '
            'and advanced filters.',
            style: text.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(text: 'One monthly plan', style: text.titleMedium),
                TextSpan(
                  text: ' · your local price is shown by the store',
                  style: text.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: onStart,
              child: const Text('Start free trial'),
            ),
          ),
        ],
      ),
    );
  }
}
