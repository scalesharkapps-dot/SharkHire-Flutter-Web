import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/bold_kit.dart';
import '../../../../shared/widgets/fade_in_up.dart';

/// Welcome for employers (Bold concept): what hiring on SharkHire gives
/// them, then straight into an employer account.
class EmployerWelcomeScreen extends StatelessWidget {
  const EmployerWelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
                        AppSpacing.md,
                        AppSpacing.xxl,
                        AppSpacing.xl,
                      ),
                      child: IntrinsicHeight(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                IconButton(
                                  tooltip: 'Back',
                                  onPressed: () => context.canPop()
                                      ? context.pop()
                                      : context.go(AppRoutes.welcome),
                                  icon: const Icon(
                                    Icons.arrow_back_rounded,
                                    color: Bold.ink,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.xs),
                                const Expanded(
                                  child: BoldTopBar(label: 'FOR EMPLOYERS'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 36),
                            const FadeInUp(
                              child: BoldHeadline(
                                semanticsLabel: 'Hire fast. Hire right.',
                                spans: [
                                  ('Hire\nfast.\nHire\n', false),
                                  ('right.', true),
                                ],
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xxl),
                            const FadeInUp(
                              delay: Duration(milliseconds: 80),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: _Perk(
                                      icon: Icons.add_rounded,
                                      title: 'Post a job',
                                      body: 'in a few minutes',
                                    ),
                                  ),
                                  SizedBox(width: AppSpacing.sm),
                                  Expanded(
                                    child: _Perk(
                                      icon: Icons.groups_outlined,
                                      title: 'Ranked applicants',
                                      body: 'best CV fit first',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Spacer(),
                            const SizedBox(height: AppSpacing.xxl),
                            BoldPrimaryButton(
                              label: 'Create employer account',
                              onPressed: () =>
                                  context.push(AppRoutes.registerEmployer),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Center(
                              child: TextButton(
                                onPressed: () => context.push(AppRoutes.login),
                                style: TextButton.styleFrom(
                                  foregroundColor: Bold.ink,
                                ),
                                child: const Text('Already hiring? Log in'),
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

class _Perk extends StatelessWidget {
  const _Perk({required this.icon, required this.title, required this.body});

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Bold.raised,
        borderRadius: const BorderRadius.all(Radius.circular(22)),
        border: Border.all(color: Bold.raisedLine),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Bold.accent, size: 22),
          const SizedBox(height: AppSpacing.sm),
          Text(
            title,
            style: const TextStyle(
              fontFamily: AppFonts.label,
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: Bold.ink,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            body,
            style: const TextStyle(
              fontFamily: AppFonts.body,
              fontSize: 13,
              color: Bold.muted,
            ),
          ),
        ],
      ),
    );
  }
}
