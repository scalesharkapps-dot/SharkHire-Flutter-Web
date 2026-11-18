import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
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
import '../../../settings/presentation/providers/subscription_provider.dart';
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

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenHorizontal,
            AppSpacing.lg,
            AppSpacing.screenHorizontal,
            AppSpacing.xxxl,
          ),
          children: [
            Row(
              children: [
                Expanded(child: Text('Profile', style: text.headlineMedium)),
                IconButton(
                  tooltip: 'Settings',
                  onPressed: () => context.push(AppRoutes.settings),
                  icon: const Icon(Icons.settings_outlined),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            FadeInUp(
              child: _IdentityCard(
                user: user,
                onEdit: () => context.push(AppRoutes.editProfile),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            FadeInUp(
              delay: const Duration(milliseconds: 60),
              child: const _CvCard(),
            ),
            if (AppConfig.showPremium) ...[
              const SizedBox(height: AppSpacing.md),
              FadeInUp(
                delay: const Duration(milliseconds: 120),
                child: ref.watch(subscriptionProvider).hasPremium
                    ? AppSurface(
                        onTap: () => context.push(AppRoutes.subscription),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.workspace_premium_rounded,
                              color: AppColors.ocean,
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Text(
                                'SharkHire Premium is active',
                                style: text.titleSmall,
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right_rounded,
                              color: AppColors.textTertiary,
                            ),
                          ],
                        ),
                      )
                    : _PremiumCard(
                        onStart: () => context.push(AppRoutes.subscription),
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
                    trailing: ref.watch(subscriptionProvider).hasPremium
                        ? 'Premium'
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
                style: text.bodySmall?.copyWith(color: AppColors.textTertiary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IdentityCard extends StatelessWidget {
  const _IdentityCard({required this.user, required this.onEdit});

  final AppUser user;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final percent = (user.profileCompletion * 100).round();

    return AppSurface(
      onTap: onEdit,
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 64,
                height: 64,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppColors.ocean,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  user.initials,
                  style: text.titleLarge?.copyWith(color: AppColors.white),
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.fullName,
                      style: text.titleLarge,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (user.headline != null)
                      Text(
                        user.headline!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: text.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    if (user.location != null) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 14,
                            color: AppColors.textTertiary,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              user.location!,
                              style: text.bodySmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(
                Icons.edit_outlined,
                size: 20,
                color: AppColors.textTertiary,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Profile strength',
                  style: text.labelMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '$percent%',
                style: text.labelMedium?.copyWith(color: AppColors.ocean),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: AppRadius.pillAll,
            child: LinearProgressIndicator(
              value: user.profileCompletion,
              minHeight: 6,
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
                  icon: const Icon(
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
              const Icon(
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
              const Icon(
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
                TextSpan(
                  text: '\$${AppConstants.monthlyPriceUsd.toStringAsFixed(0)}',
                  style: text.titleLarge,
                ),
                TextSpan(
                  text: ' / month after trial · local price at checkout',
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
