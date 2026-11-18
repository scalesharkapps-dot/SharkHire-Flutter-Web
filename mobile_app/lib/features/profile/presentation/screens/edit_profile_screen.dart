import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/feedback.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/bottom_action_bar.dart';
import '../../../../shared/widgets/form_fields.dart';
import '../../../authentication/presentation/providers/session_provider.dart';
import '../providers/current_user_provider.dart';
import '../../data/repositories/profile_repository.dart';

/// Edit personal details (guide §3.10 "edit personal details").
class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _form = GlobalKey<FormState>();
  late final _user = ref.read(currentUserProvider);
  late final _name = TextEditingController(text: _user.fullName);
  late final _headline = TextEditingController(text: _user.headline ?? '');
  late final _location = TextEditingController(text: _user.location ?? '');
  late final _phone = TextEditingController(text: _user.phone ?? '');
  bool _saving = false;

  @override
  void dispose() {
    for (final c in [_name, _headline, _location, _phone]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    final updated = _user.copyWith(
      fullName: _name.text.trim(),
      headline: _headline.text.trim(),
      location: _location.text.trim(),
      phone: _phone.text.trim(),
    );
    try {
      await ref.read(profileRepositoryProvider).updateProfile(updated);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      AppFeedback.show(context, friendlyErrorMessage(e));
      return;
    }
    ref
        .read(sessionProvider.notifier)
        .updateUser(
          (u) => u.copyWith(
            fullName: updated.fullName,
            headline: updated.headline,
            location: updated.location,
            phone: updated.phone,
          ),
        );
    if (!mounted) return;
    AppFeedback.show(context, 'Profile updated');
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit profile')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Form(
            key: _form,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenHorizontal,
                AppSpacing.sm,
                AppSpacing.screenHorizontal,
                AppSpacing.xxl,
              ),
              children: [
                AppTextField(
                  label: 'Full name',
                  controller: _name,
                  prefixIcon: Icons.badge_outlined,
                  textCapitalization: TextCapitalization.words,
                  validator: Validators.fullName,
                ),
                const SizedBox(height: AppSpacing.lg),
                AppTextField(
                  label: 'Headline',
                  controller: _headline,
                  optional: true,
                  hint: 'e.g. Flutter Developer',
                  prefixIcon: Icons.work_outline_rounded,
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: AppSpacing.lg),
                AppTextField(
                  label: 'Location',
                  controller: _location,
                  optional: true,
                  hint: 'City, Country',
                  prefixIcon: Icons.location_on_outlined,
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: AppSpacing.lg),
                AppTextField(
                  label: 'Phone',
                  controller: _phone,
                  optional: true,
                  hint: '+92 300 1234567',
                  prefixIcon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.done,
                ),
                const SizedBox(height: AppSpacing.lg),
                AppTextField(
                  label: 'Email',
                  initialValue: _user.email,
                  enabled: false,
                  prefixIcon: Icons.mail_outline_rounded,
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomActionBar(
        child: LoadingButton(
          label: 'Save changes',
          loading: _saving,
          onPressed: _save,
        ),
      ),
    );
  }
}
