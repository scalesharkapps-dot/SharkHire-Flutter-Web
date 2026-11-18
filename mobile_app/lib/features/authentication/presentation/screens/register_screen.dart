import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/models/domain_enums.dart';
import '../../../../shared/widgets/form_fields.dart';
import '../../../../shared/widgets/pressable.dart';
import '../../data/repositories/auth_repository.dart';
import '../providers/session_provider.dart';
import '../widgets/auth_scaffold.dart';

/// Account creation with the job seeker / employer choice (guide §3.5, 4.1).
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  AppRole _role = AppRole.jobSeeker;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_form.currentState?.validate() ?? false)) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref
          .read(sessionProvider.notifier)
          .signUp(
            fullName: _name.text,
            email: _email.text,
            password: _password.text,
            role: _role,
          );
    } on AuthFailure catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'We couldn\'t create your account. Try again in a moment.',
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return AuthScaffold(
      title: 'Create your account',
      subtitle: 'It takes a minute. You can upload your CV right after.',
      footer: AuthFooterLink(
        prompt: 'Already have an account?',
        action: 'Log in',
        onTap: () => context.pushReplacement(AppRoutes.login),
      ),
      children: [
        Form(
          key: _form,
          child: AutofillGroup(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_error != null) ...[
                  InlineBanner(message: _error!, tone: BannerTone.error),
                  const SizedBox(height: AppSpacing.lg),
                ],
                const FieldLabel('I am a'),
                Row(
                  children: [
                    Expanded(
                      child: _RoleCard(
                        icon: Icons.person_search_outlined,
                        title: 'Job seeker',
                        body: 'Find and apply for jobs',
                        selected: _role == AppRole.jobSeeker,
                        onTap: () => setState(() => _role = AppRole.jobSeeker),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: _RoleCard(
                        icon: Icons.business_center_outlined,
                        title: 'Employer',
                        body: 'Post jobs and hire',
                        selected: _role == AppRole.employer,
                        onTap: () => setState(() => _role = AppRole.employer),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
                AppTextField(
                  label: 'Full name',
                  controller: _name,
                  hint: 'Your name',
                  prefixIcon: Icons.badge_outlined,
                  autofillHints: const [AutofillHints.name],
                  textCapitalization: TextCapitalization.words,
                  validator: Validators.fullName,
                ),
                const SizedBox(height: AppSpacing.lg),
                AppTextField(
                  label: _role == AppRole.employer ? 'Work email' : 'Email',
                  controller: _email,
                  hint: 'name@example.com',
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  prefixIcon: Icons.mail_outline_rounded,
                  validator: Validators.email,
                ),
                const SizedBox(height: AppSpacing.lg),
                PasswordField(
                  controller: _password,
                  validator: Validators.password,
                  autofillHints: const [AutofillHints.newPassword],
                  onChanged: (_) => setState(() {}),
                  onSubmitted: (_) => _submit(),
                ),
                const SizedBox(height: AppSpacing.sm),
                _StrengthMeter(
                  strength: Validators.passwordStrength(_password.text),
                ),
                const SizedBox(height: AppSpacing.xl),
                LoadingButton(
                  label: 'Create account',
                  loading: _loading,
                  onPressed: _submit,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'By creating an account you agree to the SharkHire Terms of Use and Privacy Policy. '
                  'We\'ll send a link to confirm your email.',
                  textAlign: TextAlign.center,
                  style: text.bodySmall,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.icon,
    required this.title,
    required this.body,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String body;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Semantics(
      selected: selected,
      button: true,
      label: '$title. $body',
      excludeSemantics: true,
      child: Pressable(
        onTap: onTap,
        child: AnimatedContainer(
          duration: AppDurations.medium,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: selected ? AppColors.oceanTint : AppColors.white,
            borderRadius: AppRadius.lgAll,
            border: Border.all(
              color: selected ? AppColors.ocean : AppColors.border,
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    icon,
                    color: selected ? AppColors.ocean : AppColors.textSecondary,
                  ),
                  const Spacer(),
                  AnimatedOpacity(
                    duration: AppDurations.fast,
                    opacity: selected ? 1 : 0,
                    child: const Icon(
                      Icons.check_circle_rounded,
                      color: AppColors.ocean,
                      size: 20,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(title, style: text.titleSmall),
              Text(body, style: text.bodySmall, maxLines: 2),
            ],
          ),
        ),
      ),
    );
  }
}

class _StrengthMeter extends StatelessWidget {
  const _StrengthMeter({required this.strength});

  final int strength;

  @override
  Widget build(BuildContext context) {
    const labels = ['Too short', 'Okay', 'Good', 'Strong'];
    const colors = [
      AppColors.error,
      AppColors.warning,
      AppColors.ocean,
      AppColors.success,
    ];
    return Row(
      children: [
        for (var i = 0; i < 3; i++) ...[
          Expanded(
            child: AnimatedContainer(
              duration: AppDurations.medium,
              height: 4,
              decoration: BoxDecoration(
                color: i < strength ? colors[strength] : AppColors.border,
                borderRadius: AppRadius.pillAll,
              ),
            ),
          ),
          const SizedBox(width: 6),
        ],
        SizedBox(
          width: 64,
          child: Text(
            labels[strength],
            textAlign: TextAlign.right,
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: colors[strength]),
          ),
        ),
      ],
    );
  }
}
