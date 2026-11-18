import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/feedback.dart';
import '../../../../shared/widgets/form_fields.dart';
import '../../../../shared/widgets/state_views.dart';
import '../../../profile/presentation/providers/current_user_provider.dart';
import '../providers/session_provider.dart';
import '../widgets/auth_scaffold.dart';

/// Shown after sign-up until the email address is confirmed.
class VerifyEmailScreen extends ConsumerStatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> {
  static const _cooldownSeconds = 30;
  bool _checking = false;
  bool _resending = false;
  int _cooldown = 0;
  Timer? _timer;
  String? _message;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _check() async {
    setState(() {
      _checking = true;
      _message = null;
    });
    var ok = false;
    String? error;
    try {
      ok = await ref.read(sessionProvider.notifier).refreshVerification();
    } catch (e) {
      error = friendlyErrorMessage(e);
    }
    if (!mounted) return;
    setState(() {
      _checking = false;
      if (!ok) {
        _message =
            error ??
            'We haven\'t seen the confirmation yet. Open the link in the email, then try again.';
      }
    });
  }

  Future<void> _resend() async {
    setState(() => _resending = true);
    try {
      await ref.read(sessionProvider.notifier).resendVerification();
    } catch (e) {
      if (!mounted) return;
      setState(() => _resending = false);
      AppFeedback.show(context, friendlyErrorMessage(e));
      return;
    }
    if (!mounted) return;
    setState(() {
      _resending = false;
      _cooldown = _cooldownSeconds;
    });
    AppFeedback.show(context, 'Verification email sent');
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return t.cancel();
      setState(() => _cooldown--);
      if (_cooldown <= 0) t.cancel();
    });
  }

  @override
  Widget build(BuildContext context) {
    final email = ref.watch(currentUserProvider).email;
    final text = Theme.of(context).textTheme;

    return AuthScaffold(
      showBack: false,
      title: 'Confirm your email',
      leading: const StateIllustration(icon: Icons.mark_email_unread_outlined),
      children: [
        Text.rich(
          TextSpan(
            children: [
              const TextSpan(text: 'We sent a confirmation link to '),
              TextSpan(
                text: email,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.navy,
                ),
              ),
              const TextSpan(
                text: '. Open it on this device, then come back here.',
              ),
            ],
          ),
          style: text.bodyLarge?.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.xl),
        if (_message != null) ...[
          InlineBanner(message: _message!, tone: BannerTone.warning),
          const SizedBox(height: AppSpacing.lg),
        ],
        LoadingButton(
          label: 'I\'ve confirmed my email',
          loading: _checking,
          onPressed: _check,
        ),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: _cooldown > 0 || _resending ? null : _resend,
            child: Text(
              _cooldown > 0 ? 'Resend in ${_cooldown}s' : 'Resend email',
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Center(
          child: TextButton(
            onPressed: () => ref.read(sessionProvider.notifier).signOut(),
            child: const Text('Use a different email'),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Can\'t find it? Check your spam or promotions folder.',
          textAlign: TextAlign.center,
          style: text.bodySmall,
        ),
      ],
    );
  }
}
