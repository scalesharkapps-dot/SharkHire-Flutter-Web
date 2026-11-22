import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/brand_logo.dart';
import '../../../../shared/widgets/fade_in_up.dart';
import '../../../../shared/widgets/bold_kit.dart';

/// First screen for signed-out users (Bold concept): a big statement, the
/// brand mark, and the two ways in.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Bold.ground,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.xxl,
                        AppSpacing.xl,
                        AppSpacing.xxl,
                        AppSpacing.xl,
                      ),
                      child: IntrinsicHeight(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const BoldTopBar(),
                            const SizedBox(height: 40),
                            const FadeInUp(
                              child: BoldHeadline(
                                semanticsLabel: 'Find work that fits you.',
                                spans: [
                                  ('Find\nwork\nthat ', false),
                                  ('fits', true),
                                  ('\nyou.', false),
                                ],
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xxl),
                            FadeInUp(
                              delay: const Duration(milliseconds: 80),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Container(
                                    width: 132,
                                    height: 132,
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.all(
                                        Radius.circular(30),
                                      ),
                                    ),
                                    alignment: Alignment.center,
                                    child: const SharkMark(size: 116),
                                  ),
                                  const SizedBox(width: AppSpacing.lg),
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.only(bottom: 4),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'CV',
                                            style: TextStyle(
                                              fontFamily: AppFonts.display,
                                              fontSize: 36,
                                              height: 1,
                                              color: Bold.accent,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            'Upload once. Every job in '
                                            'Pakistan and worldwide is ranked '
                                            'for you.',
                                            style: text.bodyMedium?.copyWith(
                                              color: Bold.muted,
                                              height: 1.4,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Spacer(),
                            const SizedBox(height: AppSpacing.xxl),
                            Row(
                              children: [
                                Expanded(
                                  child: BoldPrimaryButton(
                                    label: 'Create account',
                                    onPressed: () =>
                                        context.push(AppRoutes.register),
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                SizedBox(
                                  width: 120,
                                  child: BoldSecondaryButton(
                                    label: 'Log in',
                                    onPressed: () =>
                                        context.push(AppRoutes.login),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Center(
                              child: TextButton(
                                onPressed: () =>
                                    context.push(AppRoutes.employerWelcome),
                                style: TextButton.styleFrom(
                                  foregroundColor: Bold.ink,
                                ),
                                child: const Text(
                                  'Hiring? Create an employer account',
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
            ),
          ),
        ),
      ),
    );
  }
}
