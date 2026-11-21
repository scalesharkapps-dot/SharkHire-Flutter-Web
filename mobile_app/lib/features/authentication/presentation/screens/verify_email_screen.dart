import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/form_fields.dart';
import '../../../../shared/widgets/state_views.dart';
import '../../../profile/presentation/providers/current_user_provider.dart';
import '../providers/resend_verification_provider.dart';
import '../providers/session_provider.dart';
import '../widgets/auth_scaffold.dart';

/// Shown after sign-up until the email address is confirmed.
class VerifyEmailScreen extends ConsumerStatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> {
  /// Short pause after a confirmed resend so a double tap can't send twice.
  /// This is not the resend limit; the backend enforces that.
  static const _cooldownSeconds = 30;
  bool _checking = false;
  String? _message;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    // Repaints the "Resend in Ns" countdown while it runs.
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && _cooldownLeft(_resendState.lastSentAt) > 0) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  String get _emailKey =>
      ref.read(currentUserProvider).email.trim().toLowerCase();

  ResendVerificationState get _resendState =>
      ref.read(resendVerificationProvider(_emailKey));

  static int _cooldownLeft(DateTime? lastSentAt) {
    if (lastSentAt == null) return 0;
    final left =
        _cooldownSeconds - DateTime.now().difference(lastSentAt).inSeconds;
    return left > 0 ? left : 0;
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

  void _resend() =>
      ref.read(resendVerificationProvider(_emailKey).notifier).resend();

  @override
  Widget build(BuildContext context) {
    final email = ref.watch(currentUserProvider).email;
    final text = Theme.of(context).textTheme;
    final resend = ref.watch(
      resendVerificationProvider(email.trim().toLowerCase()),
    );
    final cooldown = _cooldownLeft(resend.lastSentAt);
    final canTap = resend.canResend && cooldown == 0;
    final remaining = resend.remainingAttempts;
    final resendLabel = resend.limitReached
        ? 'Resend limit reached'
        : resend.alreadyVerified
        ? 'Email already confirmed'
        : cooldown > 0
        ? 'Resend in ${cooldown}s'
        : 'Resend email';

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
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink,
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
            onPressed: canTap ? _resend : null,
            child: resend.sending
                ? Semantics(
                    label: 'Sending verification email',
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: AppSpacing.sm),
                        Text('Sending…'),
                      ],
                    ),
                  )
                : Text(resendLabel),
          ),
        ),
        if (remaining != null && remaining > 0 && !resend.limitReached) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            '$remaining ${remaining == 1 ? 'resend' : 'resends'} left',
            textAlign: TextAlign.center,
            style: text.bodySmall,
          ),
        ],
        if (resend.notice != null) ...[
          const SizedBox(height: AppSpacing.md),
          Semantics(
            liveRegion: true,
            child: InlineBanner(
              message: resend.notice!,
              tone: switch (resend.noticeTone) {
                ResendNoticeTone.success => BannerTone.success,
                ResendNoticeTone.info => BannerTone.info,
                ResendNoticeTone.error => BannerTone.error,
              },
            ),
          ),
        ],
        if (resend.limitReached) ...[
          const SizedBox(height: AppSpacing.md),
          Semantics(
            liveRegion: true,
            child: const InlineBanner(
              message: resendLimitMessage,
              tone: BannerTone.warning,
            ),
          ),
        ],
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
