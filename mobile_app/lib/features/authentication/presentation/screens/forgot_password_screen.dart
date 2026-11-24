import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/form_fields.dart';
import '../../../../shared/widgets/state_views.dart';
import '../../data/repositories/auth_repository.dart';
import '../widgets/auth_scaffold.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  bool _loading = false;
  bool _sent = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    FocusScope.of(context).unfocus();
    if (!(_form.currentState?.validate() ?? false)) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref
          .read(authRepositoryProvider)
          .sendPasswordReset(_email.text.trim());
      if (mounted) setState(() => _sent = true);
    } on RateLimitedException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } on ValidationException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'We couldn\'t send the email right now. Try again in a few minutes.',
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_sent) {
      return AuthScaffold(
        title: 'Check your inbox',
        subtitle:
            'If an account exists for ${_email.text.trim()}, you\'ll get a link to set a new password. It can take a few minutes.',
        leading: const StateIllustration(icon: Icons.mark_email_read_outlined),
        children: [
          LoadingButton(
            label: 'Back to log in',
            onPressed: () => context.pop(),
          ),
          const SizedBox(height: AppSpacing.md),
          Center(
            child: TextButton(
              onPressed: () => setState(() => _sent = false),
              child: const Text('Use a different email'),
            ),
          ),
        ],
      );
    }

    return AuthScaffold(
      title: 'Reset your password',
      subtitle:
          'Enter the email you signed up with and we\'ll send you a reset link.',
      children: [
        Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_error != null) ...[
                InlineBanner(message: _error!, tone: BannerTone.error),
                const SizedBox(height: AppSpacing.lg),
              ],
              AppTextField(
                label: 'Email',
                controller: _email,
                hint: 'name@example.com',
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                prefixIcon: Icons.mail_outline_rounded,
                textInputAction: TextInputAction.done,
                validator: Validators.email,
                onSubmitted: (_) => _send(),
              ),
              const SizedBox(height: AppSpacing.xl),
              LoadingButton(
                label: 'Send reset link',
                loading: _loading,
                onPressed: _send,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
