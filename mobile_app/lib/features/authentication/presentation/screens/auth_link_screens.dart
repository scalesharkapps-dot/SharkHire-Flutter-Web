import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/form_fields.dart';
import '../../../../shared/widgets/state_views.dart';
import '../../data/repositories/auth_repository.dart';
import '../../domain/auth_link.dart';
import '../../domain/session.dart';
import '../providers/auth_link_provider.dart';
import '../providers/session_provider.dart';
import '../widgets/auth_scaffold.dart';

enum _Confirm { working, confirmed, confirmedLogIn, expired, failed }

/// Where the "Confirm your email" link brings the user back
/// (`/auth/callback`). Signs them in when the link carries a session,
/// otherwise asks them to log in. Expired, used and broken links get a
/// clear way forward.
class AuthCallbackScreen extends ConsumerStatefulWidget {
  const AuthCallbackScreen({super.key});

  @override
  ConsumerState<AuthCallbackScreen> createState() => _AuthCallbackScreenState();
}

class _AuthCallbackScreenState extends ConsumerState<AuthCallbackScreen> {
  _Confirm _phase = _Confirm.working;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _handle());
  }

  Future<void> _handle() async {
    if (_started || !mounted) return;
    _started = true;
    final link = ref.read(authLinkProvider.notifier).take();
    final session = ref.read(sessionProvider.notifier);

    if (link == null || link.hasError) {
      _set(link != null && link.isExpired ? _Confirm.expired : _Confirm.failed);
      return;
    }
    if (link.hasSession) {
      try {
        await session.signInWithLink(link);
        _set(_Confirm.confirmed);
      } on AuthFailure {
        _set(_Confirm.expired);
      } catch (_) {
        // Confirmed, but the account couldn't be loaded (offline…).
        _set(_Confirm.confirmedLogIn);
      }
      return;
    }
    // Supabase confirmed the address but sent no session (token-hash or
    // PKCE template). If this device is mid sign-up, finish it here.
    if (ref.read(sessionProvider).stage == SessionStage.unverified) {
      try {
        if (await session.refreshVerification()) {
          _set(_Confirm.confirmed);
          return;
        }
      } catch (_) {
        // Fall through: ask them to log in.
      }
    }
    _set(_Confirm.confirmedLogIn);
  }

  void _set(_Confirm phase) {
    if (mounted) setState(() => _phase = phase);
  }

  @override
  Widget build(BuildContext context) {
    final signedIn = ref.watch(sessionProvider).isSignedIn;
    switch (_phase) {
      case _Confirm.working:
        return const AuthScaffold(
          title: 'Confirming your email',
          subtitle: 'One moment…',
          showBack: false,
          leading: StateIllustration(icon: Icons.mark_email_read_outlined),
          children: [Center(child: CircularProgressIndicator())],
        );
      case _Confirm.confirmed:
        return AuthScaffold(
          title: 'Email confirmed',
          subtitle: 'Your SharkHire account is ready.',
          showBack: false,
          leading: StateIllustration(
            icon: Icons.verified_outlined,
            tone: AppColors.success,
            tint: AppColors.successTint,
          ),
          children: [
            LoadingButton(
              label: 'Continue',
              // The router sends each user on to the right place
              // (preferences, job seeker, employer or admin home).
              onPressed: () => context.go(AppRoutes.home),
            ),
          ],
        );
      case _Confirm.confirmedLogIn:
        return AuthScaffold(
          title: 'Email confirmed',
          subtitle: 'Log in with your email and password to continue.',
          showBack: false,
          leading: StateIllustration(
            icon: Icons.verified_outlined,
            tone: AppColors.success,
            tint: AppColors.successTint,
          ),
          children: [
            LoadingButton(
              label: signedIn ? 'Continue' : 'Log in',
              onPressed: () =>
                  context.go(signedIn ? AppRoutes.home : AppRoutes.login),
            ),
          ],
        );
      case _Confirm.expired:
      case _Confirm.failed:
        final expired = _phase == _Confirm.expired;
        return AuthScaffold(
          title: expired ? 'This link has expired' : 'This link didn\'t work',
          subtitle: expired
              ? 'Links in SharkHire emails work once and expire after a '
                    'while. Ask for a new one below.'
              : 'The link is incomplete or was already used. Log in to '
                    'check your account or get a new link.',
          showBack: false,
          leading: StateIllustration(
            icon: Icons.link_off_rounded,
            tone: AppColors.error,
          ),
          children: [
            LoadingButton(
              label: signedIn ? 'Get a new link' : 'Log in',
              onPressed: () => context.go(
                signedIn ? AppRoutes.verifyEmail : AppRoutes.login,
              ),
            ),
            if (!signedIn) ...[
              const SizedBox(height: AppSpacing.sm),
              Center(
                child: TextButton(
                  onPressed: () => context.go(AppRoutes.forgotPassword),
                  child: const Text('Reset my password instead'),
                ),
              ),
            ],
          ],
        );
    }
  }
}

/// Set a new password from the recovery email (`/auth/reset-password`).
class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _form = GlobalKey<FormState>();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  AuthLink? _link;
  bool _ready = false;
  bool _loading = false;
  bool _done = false;
  bool _linkExpired = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final link = ref.read(authLinkProvider.notifier).take();
      setState(() {
        _link = link;
        _ready = true;
        _linkExpired = link == null || !link.canResetPassword;
      });
    });
  }

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_loading) return;
    FocusScope.of(context).unfocus();
    if (!(_form.currentState?.validate() ?? false)) return;
    final link = _link;
    if (link == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref
          .read(authRepositoryProvider)
          .resetPassword(
            newPassword: _password.text,
            tokenHash: link.tokenHash,
            recoveryToken: link.tokenHash == null ? link.accessToken : null,
          );
      // The backend revoked every session of the account (this device's
      // too), so sign in again with the new password.
      if (ref.read(sessionProvider).isSignedIn) {
        await ref.read(sessionProvider.notifier).signOutLocally();
      }
      if (mounted) setState(() => _done = true);
    } on UnauthorizedException {
      if (mounted) setState(() => _linkExpired = true);
    } on ValidationException catch (e) {
      _showError(e.fieldErrors.values.firstOrNull ?? e.message);
    } catch (e) {
      _showError(friendlyErrorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(String message) {
    if (mounted) setState(() => _error = message);
  }

  @override
  Widget build(BuildContext context) {
    final signedIn = ref.watch(sessionProvider).isSignedIn;
    if (!_ready) {
      return const AuthScaffold(
        title: 'Reset your password',
        showBack: false,
        children: [Center(child: CircularProgressIndicator())],
      );
    }
    if (_done) {
      return AuthScaffold(
        title: 'Password updated',
        subtitle: signedIn
            ? 'Use your new password next time you log in.'
            : 'Log in with your new password.',
        showBack: false,
        leading: StateIllustration(
          icon: Icons.lock_reset_rounded,
          tone: AppColors.success,
          tint: AppColors.successTint,
        ),
        children: [
          LoadingButton(
            label: signedIn ? 'Continue' : 'Log in',
            onPressed: () =>
                context.go(signedIn ? AppRoutes.home : AppRoutes.login),
          ),
        ],
      );
    }
    if (_linkExpired) {
      return AuthScaffold(
        title: 'This reset link has expired',
        subtitle:
            'Reset links work once and expire after a while. Ask for a new '
            'one and use it straight away.',
        showBack: false,
        leading: StateIllustration(
          icon: Icons.link_off_rounded,
          tone: AppColors.error,
        ),
        children: [
          LoadingButton(
            label: signedIn ? 'Back to SharkHire' : 'Send a new link',
            onPressed: () => context.go(
              signedIn ? AppRoutes.home : AppRoutes.forgotPassword,
            ),
          ),
        ],
      );
    }

    return AuthScaffold(
      title: 'Set a new password',
      subtitle: 'Choose a password you don\'t use anywhere else.',
      showBack: false,
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
                PasswordField(
                  controller: _password,
                  label: 'New password',
                  validator: Validators.newPassword,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.newPassword],
                ),
                const SizedBox(height: AppSpacing.md),
                PasswordField(
                  controller: _confirm,
                  label: 'Confirm new password',
                  validator: Validators.matches(() => _password.text),
                  autofillHints: const [AutofillHints.newPassword],
                  onSubmitted: (_) => _submit(),
                ),
                const SizedBox(height: AppSpacing.sm),
                const PasswordRules(),
                const SizedBox(height: AppSpacing.xl),
                LoadingButton(
                  label: 'Update password',
                  loading: _loading,
                  onPressed: _submit,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// The password policy in one line, under new-password fields.
class PasswordRules extends StatelessWidget {
  const PasswordRules({super.key});

  @override
  Widget build(BuildContext context) => Text(
    'At least 8 characters, with an uppercase letter, a lowercase letter '
    'and a number.',
    style: Theme.of(
      context,
    ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
  );
}
