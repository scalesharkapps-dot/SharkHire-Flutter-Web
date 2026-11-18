import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/brand_logo.dart';
import '../../../../shared/widgets/fade_in_up.dart';

/// First screen for signed-out users: what SharkHire does and the two
/// ways in (create an account or log in).
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  static const _points = [
    (
      Icons.fact_check_outlined,
      'Matches from your CV',
      'Upload once. We rank every job by how well it fits you.',
    ),
    (
      Icons.public_rounded,
      'Pakistan and international',
      'Local roles and remote jobs worldwide in one place.',
    ),
    (
      Icons.track_changes_rounded,
      'Every application tracked',
      'See when you are reviewed, shortlisted or invited to interview.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.navy,
        body: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Column(
                  children: [
                    // Brand + promise
                    Expanded(
                      child: SafeArea(
                        bottom: false,
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 480),
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(
                                AppSpacing.xxl,
                                AppSpacing.xxxl,
                                AppSpacing.xxl,
                                AppSpacing.xxl,
                              ),
                              child: FadeInUp(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Row(
                                      children: [
                                        SharkBadge(size: 52, glow: false),
                                        SizedBox(width: AppSpacing.md),
                                        Flexible(
                                          child: FittedBox(
                                            fit: BoxFit.scaleDown,
                                            child: SharkHireWordmark(
                                              fontSize: 26,
                                              onDark: true,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: AppSpacing.xxxl),
                                    Text(
                                      'Find work that fits you.',
                                      style: text.displaySmall?.copyWith(
                                        color: AppColors.white,
                                      ),
                                    ),
                                    const SizedBox(height: AppSpacing.md),
                                    Text(
                                      'Job search and hiring for Pakistan and beyond, by Scale Shark.',
                                      style: text.bodyLarge?.copyWith(
                                        color: AppColors.textOnDarkMuted,
                                      ),
                                    ),
                                    const SizedBox(height: AppSpacing.xxl),
                                    for (final (icon, title, body) in _points)
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: AppSpacing.lg,
                                        ),
                                        child: _ValuePoint(
                                          icon: icon,
                                          title: title,
                                          body: body,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Actions
                    Container(
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(28),
                        ),
                      ),
                      child: SafeArea(
                        top: false,
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 480),
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(
                                AppSpacing.xxl,
                                AppSpacing.xxl,
                                AppSpacing.xxl,
                                AppSpacing.xl,
                              ),
                              child: Column(
                                children: [
                                  SizedBox(
                                    width: double.infinity,
                                    child: FilledButton(
                                      onPressed: () =>
                                          context.push(AppRoutes.register),
                                      child: const Text('Create account'),
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.md),
                                  SizedBox(
                                    width: double.infinity,
                                    child: OutlinedButton(
                                      onPressed: () =>
                                          context.push(AppRoutes.login),
                                      child: const Text('Log in'),
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.lg),
                                  Text(
                                    'Hiring? Create an employer account to post jobs.',
                                    textAlign: TextAlign.center,
                                    style: text.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ValuePoint extends StatelessWidget {
  const _ValuePoint({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: const BoxDecoration(
            color: AppColors.navySoft,
            borderRadius: AppRadius.lgAll,
          ),
          child: Icon(icon, color: AppColors.cyan, size: 20),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: text.titleSmall?.copyWith(color: AppColors.white),
              ),
              const SizedBox(height: 2),
              Text(
                body,
                style: text.bodyMedium?.copyWith(
                  color: AppColors.textOnDarkMuted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
