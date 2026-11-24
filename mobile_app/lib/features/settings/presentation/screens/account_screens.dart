import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/feedback.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/form_fields.dart';
import '../../../authentication/data/repositories/auth_repository.dart';
import '../../../authentication/presentation/providers/session_provider.dart';
import '../../../authentication/presentation/screens/auth_link_screens.dart';
import '../../data/repositories/account_repository.dart';

/// Shared frame: app bar, centred column, comfortable on phones and web.
class _AccountPage extends StatelessWidget {
  const _AccountPage({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(),
    body: SafeArea(
      top: false,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenHorizontal,
              0,
              AppSpacing.screenHorizontal,
              AppSpacing.xxxl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Semantics(
                  header: true,
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                child,
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

/// Settings → Change password: current password, new password, confirm.
class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _form = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _new = TextEditingController();
  final _confirm = TextEditingController();
  bool _loading = false;
  bool _sendingLink = false;
  String? _error;

  @override
  void dispose() {
    _current.dispose();
    _new.dispose();
    _confirm.dispose();
    super.dispose();
  }

  String? _validateNew(String? v) {
    final policy = Validators.newPassword(v);
    if (policy != null) return policy;
    if (v == _current.text) {
      return 'Choose a password different from your current one';
    }
    return null;
  }

  Future<void> _submit() async {
    if (_loading) return;
    FocusScope.of(context).unfocus();
    if (!(_form.currentState?.validate() ?? false)) return;
    final email = ref.read(sessionProvider).user?.email;
    if (email == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref
          .read(authRepositoryProvider)
          .changePassword(
            email: email,
            currentPassword: _current.text,
            newPassword: _new.text,
          );
      if (!mounted) return;
      AppFeedback.show(context, 'Password changed');
      context.canPop() ? context.pop() : context.go(AppRoutes.settings);
    } on AuthFailure catch (e) {
      _fail(e.message);
    } on ValidationException catch (e) {
      _fail(e.fieldErrors.values.firstOrNull ?? e.message);
    } catch (e) {
      _fail(friendlyErrorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _fail(String message) {
    if (mounted) setState(() => _error = message);
  }

  Future<void> _sendResetLink() async {
    final email = ref.read(sessionProvider).user?.email;
    if (email == null || _sendingLink) return;
    setState(() => _sendingLink = true);
    try {
      await ref.read(authRepositoryProvider).sendPasswordReset(email);
      if (mounted) {
        AppFeedback.show(context, 'We sent a password reset link to $email');
      }
    } catch (e) {
      if (mounted) AppFeedback.show(context, friendlyErrorMessage(e));
    } finally {
      if (mounted) setState(() => _sendingLink = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _AccountPage(
      title: 'Change password',
      child: Form(
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
                controller: _current,
                label: 'Current password',
                sentenceCaseLabel: true,
                validator: (v) =>
                    (v ?? '').isEmpty ? 'Enter your current password' : null,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: AppSpacing.md),
              PasswordField(
                controller: _new,
                label: 'New password',
                sentenceCaseLabel: true,
                validator: _validateNew,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.newPassword],
              ),
              const SizedBox(height: AppSpacing.md),
              PasswordField(
                controller: _confirm,
                label: 'Confirm new password',
                sentenceCaseLabel: true,
                validator: Validators.matches(() => _new.text),
                autofillHints: const [AutofillHints.newPassword],
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: AppSpacing.sm),
              const PasswordRules(),
              const SizedBox(height: AppSpacing.xl),
              LoadingButton(
                label: 'Change password',
                loading: _loading,
                onPressed: _submit,
              ),
              const SizedBox(height: AppSpacing.sm),
              Center(
                child: TextButton(
                  onPressed: _sendingLink ? null : _sendResetLink,
                  child: const Text('Forgot your current password?'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Privacy & security → Delete account: what is deleted, an explicit
/// "I understand", typing DELETE, then one final button.
class DeleteAccountScreen extends ConsumerStatefulWidget {
  const DeleteAccountScreen({super.key});

  /// What the user types to confirm.
  static const confirmWord = 'DELETE';

  @override
  ConsumerState<DeleteAccountScreen> createState() =>
      _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends ConsumerState<DeleteAccountScreen> {
  final _password = TextEditingController();
  final _typed = TextEditingController();
  bool _understood = false;
  bool _deleting = false;
  String? _error;

  @override
  void dispose() {
    _password.dispose();
    _typed.dispose();
    super.dispose();
  }

  bool get _canDelete =>
      _understood &&
      _password.text.isNotEmpty &&
      _typed.text.trim().toUpperCase() == DeleteAccountScreen.confirmWord;

  Future<void> _delete() async {
    if (_deleting || !_canDelete) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _deleting = true;
      _error = null;
    });
    final AccountDeletionResult result;
    try {
      result = await ref
          .read(accountRepositoryProvider)
          .requestDeletion(password: _password.text);
    } on WrongPasswordException catch (e) {
      _fail(e.message);
      return;
    } catch (e) {
      // Kept signed in: the server deleted nothing.
      _fail(friendlyErrorMessage(e));
      return;
    }
    // Deleted on the server, which also ended every session: forget the
    // tokens and everything kept for this user; the router then shows the
    // welcome screen.
    if (mounted) {
      AppFeedback.show(
        context,
        result.activeStoreSubscription
            ? 'Your SharkHire account was deleted. Cancel your Premium '
                  'subscription in Google Play or the App Store.'
            : 'Your SharkHire account was deleted',
      );
    }
    await ref.read(sessionProvider.notifier).signOutLocally();
  }

  void _fail(String message) {
    if (mounted) {
      setState(() {
        _error = message;
        _deleting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final email = ref.watch(sessionProvider).user?.email;

    return _AccountPage(
      title: 'Delete account',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Delete your account permanently?', style: text.headlineSmall),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'This can\'t be undone. Deleting ${email ?? 'your account'} '
            'removes:',
            style: text.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.md),
          for (final item in const [
            'Your profile and job preferences',
            'Your uploaded CVs and what was read from them',
            'Your saved jobs and applications',
            'Your sign-in, so you can\'t log in again with it',
          ])
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.remove_circle_outline_rounded,
                    size: 18,
                    color: AppColors.error,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: Text(item, style: text.bodyMedium)),
                ],
              ),
            ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Employers you applied to keep the copy you sent them. An active '
            'Premium subscription isn\'t cancelled by this: cancel it in '
            'Google Play or the App Store.',
            style: text.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.xl),
          if (_error != null) ...[
            InlineBanner(
              tone: BannerTone.error,
              title: 'Couldn\'t delete',
              message: _error!,
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
          CheckboxListTile(
            value: _understood,
            onChanged: _deleting
                ? null
                : (v) => setState(() => _understood = v ?? false),
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            title: const Text(
              'I understand my account and data will be deleted permanently',
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          PasswordField(
            controller: _password,
            label: 'Your password',
            sentenceCaseLabel: true,
            textInputAction: TextInputAction.next,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            label: 'Type ${DeleteAccountScreen.confirmWord} to confirm',
            sentenceCaseLabel: true,
            controller: _typed,
            hint: DeleteAccountScreen.confirmWord,
            textInputAction: TextInputAction.done,
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _delete(),
          ),
          const SizedBox(height: AppSpacing.xl),
          LoadingButton(
            label: 'Delete my account',
            loading: _deleting,
            onPressed: _canDelete ? _delete : null,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Center(
            child: TextButton(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
              ),
              onPressed: _deleting ? null : () => context.pop(),
              child: const Text('Keep my account'),
            ),
          ),
        ],
      ),
    );
  }
}
