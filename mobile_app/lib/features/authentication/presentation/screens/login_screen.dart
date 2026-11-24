import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/feedback.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/form_fields.dart';
import '../../data/login_preferences.dart';
import '../../data/repositories/auth_repository.dart';
import '../providers/session_provider.dart';
import '../widgets/auth_scaffold.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  bool _rememberMe = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  /// Fills in the remembered email and the last "Remember me" choice.
  Future<void> _loadPreferences() async {
    final prefs = await ref.read(loginPreferencesStoreProvider).read();
    if (!mounted) return;
    setState(() {
      _rememberMe = prefs.rememberMe;
      if (_email.text.isEmpty && prefs.email != null) {
        _email.text = prefs.email!;
      }
    });
  }

  @override
  void dispose() {
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
    final email = _email.text.trim();
    try {
      await ref
          .read(sessionProvider.notifier)
          .signIn(email, _password.text, rememberMe: _rememberMe);
      await ref
          .read(loginPreferencesStoreProvider)
          .write(LoginPreferences(rememberMe: _rememberMe, email: email));
      // Ask the phone / browser password manager to save the email and
      // password (only with "Remember me"). The app never stores them.
      TextInput.finishAutofillContext(shouldSave: _rememberMe);
      // The router redirects to the right place for this user.
    } on AuthFailure catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'We couldn\'t log you in. Check your connection and try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _fillDemo(String email) {
    _email.text = email;
    _password.text = MockAuthRepository.demoPassword;
    setState(() => _error = null);
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'Log in to SharkHire',
      showBrandMark: false,
      subtitle: 'Log in to see your matches and applications.',
      footer: AuthFooterLink(
        prompt: 'New to SharkHire?',
        action: 'Create account',
        onTap: () => context.pushReplacement(AppRoutes.register),
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
                AppTextField(
                  label: 'Email',
                  sentenceCaseLabel: true,
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
                  sentenceCaseLabel: true,
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Enter your password' : null,
                  onSubmitted: (_) => _submit(),
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    Expanded(
                      child: _RememberMe(
                        value: _rememberMe,
                        onChanged: (v) => setState(() => _rememberMe = v),
                      ),
                    ),
                    TextButton(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                        ),
                      ),
                      onPressed: () => context.push(AppRoutes.forgotPassword),
                      child: const Text('Forgot password?'),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                LoadingButton(
                  label: 'Log in',
                  loading: _loading,
                  onPressed: _submit,
                ),
                if (AppConfig.showGoogleSignIn) ...[
                  const SizedBox(height: AppSpacing.xl),
                  const LabeledDivider('or'),
                  const SizedBox(height: AppSpacing.xl),
                  OutlinedButton.icon(
                    onPressed: () => AppFeedback.show(
                      context,
                      'Google sign-in becomes available when SharkHire is connected to its account service.',
                    ),
                    icon: const _GoogleMark(),
                    label: const Text('Continue with Google'),
                  ),
                ],
                if (AppConfig.useMockData) ...[
                  const SizedBox(height: AppSpacing.xl),
                  _DemoAccounts(onPick: _fillDemo),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// "Remember me" checkbox with a tappable label.
class _RememberMe extends StatelessWidget {
  const _RememberMe({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: InkWell(
        onTap: () => onChanged(!value),
        borderRadius: AppRadius.mdAll,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox.square(
                dimension: 32,
                child: Checkbox(
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  value: value,
                  onChanged: (v) => onChanged(v ?? false),
                  activeColor: AppColors.ink,
                  checkColor: AppColors.onInk,
                  side: BorderSide(color: AppColors.borderStrong, width: 1.5),
                  shape: const RoundedRectangleBorder(
                    borderRadius: AppRadius.smAll,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Flexible(
                child: Text(
                  'Remember me',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Neutral "G" mark (no third-party logo asset is bundled).
class _GoogleMark extends StatelessWidget {
  const _GoogleMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.borderStrong),
      ),
      child: const Text(
        'G',
        style: TextStyle(
          fontFamily: 'Archivo',
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),
      ),
    );
  }
}

/// Development helper, shown only while the app runs on mock data.
class _DemoAccounts extends StatelessWidget {
  const _DemoAccounts({required this.onPick});

  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Demo accounts', style: text.titleSmall),
        const SizedBox(height: 2),
        Text(
          'Preview build only. Tap to fill the form.',
          style: text.bodySmall,
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            ActionChip(
              avatar: const Icon(Icons.person_outline_rounded, size: 18),
              label: const Text('Job seeker'),
              onPressed: () => onPick(MockAuthRepository.demoSeekerEmail),
            ),
            ActionChip(
              avatar: const Icon(Icons.business_center_outlined, size: 18),
              label: const Text('Employer'),
              onPressed: () => onPick(MockAuthRepository.demoEmployerEmail),
            ),
            ActionChip(
              avatar: const Icon(Icons.admin_panel_settings_outlined, size: 18),
              label: const Text('Admin'),
              onPressed: () => onPick(MockAuthRepository.demoAdminEmail),
            ),
          ],
        ),
      ],
    );
  }
}
