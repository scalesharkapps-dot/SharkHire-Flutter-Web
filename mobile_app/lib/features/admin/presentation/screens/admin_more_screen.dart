import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/menu_group.dart';
import '../../../../shared/widgets/person_avatar.dart';
import '../../../authentication/presentation/widgets/sign_out_sheet.dart';
import '../../../profile/presentation/providers/current_user_provider.dart';
import '../../data/models/admin_models.dart';
import '../providers/admin_providers.dart';

/// All other admin modules (guide §3.10 C), grouped.
class AdminMoreScreen extends ConsumerWidget {
  const AdminMoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final user = ref.watch(currentUserProvider);
    final toVerify = ref
        .watch(adminCompaniesProvider)
        .where((c) => c.verification == Verification.pending)
        .length;
    void open(String path) => context.push(path);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
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
                    PersonAvatar(initials: user.initials, size: 52),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(user.fullName, style: text.titleLarge),
                          Text('Platform admin', style: text.bodySmall),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
                MenuGroup(
                  title: 'Moderation',
                  items: [
                    MenuItem(
                      Icons.apartment_outlined,
                      'Employers',
                      trailing: toVerify > 0 ? '$toVerify' : null,
                      onTap: () => open(AppRoutes.adminEmployers),
                    ),
                    MenuItem(
                      Icons.send_outlined,
                      'Applications',
                      onTap: () => open(AppRoutes.adminApplications),
                    ),
                    MenuItem(
                      Icons.public_rounded,
                      'External listings',
                      onTap: () => open(AppRoutes.adminExternalJobs),
                    ),
                    MenuItem(
                      Icons.description_outlined,
                      'CV reports',
                      onTap: () => open(AppRoutes.adminCvReports),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
                MenuGroup(
                  title: 'Content',
                  items: [
                    MenuItem(
                      Icons.category_outlined,
                      'Categories and skills',
                      onTap: () => open(AppRoutes.adminCategories),
                    ),
                    MenuItem(
                      Icons.campaign_outlined,
                      'Announcements',
                      onTap: () => open(AppRoutes.adminAnnouncements),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
                MenuGroup(
                  title: 'System',
                  items: [
                    MenuItem(
                      Icons.monitor_heart_outlined,
                      'API monitoring',
                      onTap: () => open(AppRoutes.adminApiMonitoring),
                    ),
                    MenuItem(
                      Icons.insights_rounded,
                      'Analytics',
                      onTap: () => open(AppRoutes.adminAnalytics),
                    ),
                    MenuItem(
                      Icons.history_rounded,
                      'Audit logs',
                      onTap: () => open(AppRoutes.adminAuditLogs),
                    ),
                    MenuItem(
                      Icons.settings_outlined,
                      'Platform settings',
                      onTap: () => open(AppRoutes.adminSettings),
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
                const SizedBox(height: AppSpacing.lg),
                Center(
                  child: Text(
                    'Admin actions are recorded in the audit log.',
                    style: text.bodySmall?.copyWith(
                      color: AppColors.textTertiary,
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
