import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_mode_provider.dart';
import '../../../../core/utils/feedback.dart';
import '../../../../shared/widgets/app_surface.dart';
import '../../../../shared/widgets/appearance_picker.dart';
import '../../../../shared/widgets/form_fields.dart';
import '../../../../shared/widgets/legal_sheet.dart';
import '../../../../shared/widgets/menu_group.dart';
import '../../../authentication/presentation/widgets/sign_out_sheet.dart';
import '../../../profile/presentation/providers/current_user_provider.dart';
import '../../data/repositories/account_repository.dart';
import '../providers/settings_provider.dart';

/// Shared page frame for the settings screens.
class _SettingsPage extends StatelessWidget {
  const _SettingsPage({
    required this.title,
    required this.children,
    this.bigTitle = false,
  });

  final String title;
  final List<Widget> children;

  /// Big bold page heading in the body instead of the app bar title.
  final bool bigTitle;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: bigTitle ? null : Text(title)),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenHorizontal,
            AppSpacing.sm,
            AppSpacing.screenHorizontal,
            AppSpacing.xxxl,
          ),
          children: [
            if (bigTitle) ...[
              Semantics(
                header: true,
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0) const SizedBox(height: AppSpacing.xl),
              children[i],
            ],
          ],
        ),
      ),
    ),
  );
}

/// Settings: notification preferences and account.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(settingsProvider);
    final user = ref.watch(currentUserProvider);
    final set = ref.read(settingsProvider.notifier).update;

    return _SettingsPage(
      title: 'Settings',
      bigTitle: true,
      children: [
        MenuGroup(
          title: 'Appearance',
          normalCaseTitle: true,
          items: [
            MenuItem(
              Icons.contrast_rounded,
              'Theme',
              value: appearanceLabel(ref.watch(themeModeProvider)),
              onTap: () => showAppearanceSheet(context),
            ),
          ],
        ),
        MenuGroup(
          title: 'Push notifications',
          normalCaseTitle: true,
          items: [
            MenuItem(
              Icons.work_outline_rounded,
              'New matching jobs',
              switchValue: s.newMatches,
              onSwitch: (v) => set((x) => x.copyWith(newMatches: v)),
            ),
            MenuItem(
              Icons.trending_up_rounded,
              'Application updates',
              switchValue: s.applicationUpdates,
              onSwitch: (v) => set((x) => x.copyWith(applicationUpdates: v)),
            ),
            MenuItem(
              Icons.schedule_rounded,
              'Saved job reminders',
              switchValue: s.savedJobReminders,
              onSwitch: (v) => set((x) => x.copyWith(savedJobReminders: v)),
            ),
            MenuItem(
              Icons.forum_outlined,
              'Messages from employers',
              switchValue: s.employerMessages,
              onSwitch: (v) => set((x) => x.copyWith(employerMessages: v)),
            ),
          ],
        ),
        MenuGroup(
          title: 'Email',
          normalCaseTitle: true,
          items: [
            MenuItem(
              Icons.mail_outline_rounded,
              'Weekly job digest',
              subtitle: 'Top matches sent to ${user.email}',
              switchValue: s.emailUpdates,
              onSwitch: (v) => set((x) => x.copyWith(emailUpdates: v)),
            ),
          ],
        ),
        MenuGroup(
          title: 'Account',
          normalCaseTitle: true,
          items: [
            MenuItem(
              Icons.person_outline_rounded,
              'Edit profile',
              onTap: () => context.push(AppRoutes.editProfile),
            ),
            MenuItem(
              Icons.password_rounded,
              'Change password',
              onTap: () => context.push(AppRoutes.changePassword),
            ),
            MenuItem(
              Icons.lock_outline_rounded,
              'Privacy & security',
              onTap: () => context.push(AppRoutes.privacy),
            ),
          ],
        ),
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
      ],
    );
  }
}

/// Privacy & security (guide §3.12).
class PrivacyScreen extends ConsumerWidget {
  const PrivacyScreen({super.key});

  Future<void> _requestData(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(accountRepositoryProvider).requestDataExport();
    } catch (e) {
      if (context.mounted) AppFeedback.show(context, friendlyErrorMessage(e));
      return;
    }
    if (context.mounted) {
      AppFeedback.show(
        context,
        'Request received. We\'ll email you a download link.',
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(settingsProvider);
    final text = Theme.of(context).textTheme;

    return _SettingsPage(
      title: 'Privacy & security',
      bigTitle: true,
      children: [
        const InlineBanner(
          tone: BannerTone.info,
          showMark: false,
          title: 'Your CV is private',
          message:
              'It\'s stored in private storage and shared with an employer only when you apply '
              'to their job. Other job seekers can never see it.',
        ),
        MenuGroup(
          title: 'CV processing',
          normalCaseTitle: true,
          items: [
            MenuItem(
              Icons.psychology_outlined,
              'Allow AI-assisted CV reading',
              subtitle:
                  'Lets an external AI service read your CV text to extract details more accurately.',
              switchValue: s.aiParsingConsent,
              onSwitch: (v) => ref
                  .read(settingsProvider.notifier)
                  .update((x) => x.copyWith(aiParsingConsent: v)),
            ),
          ],
        ),
        MenuGroup(
          title: 'Your data',
          normalCaseTitle: true,
          items: [
            MenuItem(
              Icons.download_outlined,
              'Request a copy of my data',
              onTap: () => _requestData(context, ref),
            ),
            MenuItem(
              Icons.description_outlined,
              'Privacy Policy',
              onTap: () => showLegalSheet(context, LegalDocument.privacy),
            ),
          ],
        ),
        MenuGroup(
          items: [
            MenuItem(
              Icons.delete_forever_outlined,
              'Delete account',
              destructive: true,
              onTap: () => context.push(AppRoutes.deleteAccount),
            ),
          ],
        ),
        Text(
          'Signed-in sessions are protected by secure tokens. Never share your password.',
          style: text.bodySmall,
        ),
      ],
    );
  }
}

/// Help & support: common questions and how to reach the team.
class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  static const supportEmail = 'support@thescaleshark.io';

  static const _faqs = [
    (
      'How are jobs matched to me?',
      'We compare the skills, job titles and experience from your CV with each job, plus your '
          'preferences for location, job type and work mode. The match percentage shows how well they fit.',
    ),
    (
      'What\'s the difference between "Apply in-app" and "External"?',
      '"Apply in-app" jobs are posted on SharkHire, so you apply here and can track every step. '
          'External jobs come from other job sites; you apply on the employer\'s site.',
    ),
    (
      'Who can see my CV?',
      'Only you, until you apply. When you apply to a SharkHire job, that employer can see the CV you sent.',
    ),
    (
      'How do I cancel Premium?',
      'Open your Google Play or App Store subscriptions and cancel SharkHire Premium. '
          'Cancel at least 24 hours before your trial ends to avoid being charged.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return _SettingsPage(
      title: 'Help & support',
      children: [
        Text('Common questions', style: text.titleMedium),
        AppSurface(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (var i = 0; i < _faqs.length; i++) ...[
                if (i > 0) const Divider(),
                Theme(
                  data: Theme.of(
                    context,
                  ).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    title: Text(_faqs[i].$1, style: text.titleSmall),
                    childrenPadding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      0,
                      AppSpacing.lg,
                      AppSpacing.lg,
                    ),
                    expandedAlignment: Alignment.centerLeft,
                    children: [Text(_faqs[i].$2, style: text.bodyMedium)],
                  ),
                ),
              ],
            ],
          ),
        ),
        Text('Contact us', style: text.titleMedium),
        AppSurface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Email the SharkHire team', style: text.titleSmall),
              const SizedBox(height: 4),
              const SelectableText(supportEmail),
              const SizedBox(height: AppSpacing.md),
              OutlinedButton.icon(
                onPressed: () async {
                  await Clipboard.setData(
                    const ClipboardData(text: supportEmail),
                  );
                  if (context.mounted) {
                    AppFeedback.show(context, 'Email address copied');
                  }
                },
                icon: const Icon(Icons.copy_rounded, size: 18),
                label: const Text('Copy email address'),
              ),
            ],
          ),
        ),
        MenuGroup(
          items: [
            MenuItem(
              Icons.gavel_outlined,
              'Terms of Use',
              onTap: () => showLegalSheet(context, LegalDocument.terms),
            ),
            MenuItem(
              Icons.privacy_tip_outlined,
              'Privacy Policy',
              onTap: () => showLegalSheet(context, LegalDocument.privacy),
            ),
          ],
        ),
        Center(
          child: Text(
            '${AppConstants.appName} v${AppConstants.appVersion} · ${AppConstants.companyLegalName}',
            textAlign: TextAlign.center,
            style: text.bodySmall?.copyWith(color: AppColors.textTertiary),
          ),
        ),
      ],
    );
  }
}
