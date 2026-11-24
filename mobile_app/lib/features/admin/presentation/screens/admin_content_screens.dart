import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/feedback.dart';
import '../../../../shared/widgets/app_surface.dart';
import '../../../../shared/widgets/company_logo.dart';
import '../../../../shared/widgets/form_fields.dart';
import '../../data/models/admin_models.dart';
import '../providers/admin_providers.dart';
import '../widgets/admin_widgets.dart';

/// Asks for one short value in a bottom sheet.
Future<String?> _askValue(BuildContext context, String title, String hint) {
  final c = TextEditingController();
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    builder: (sheet) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(sheet).bottom),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenHorizontal,
            0,
            AppSpacing.screenHorizontal,
            AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(title, style: Theme.of(sheet).textTheme.headlineSmall),
              const SizedBox(height: AppSpacing.lg),
              TextField(
                controller: c,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(hintText: hint),
              ),
              const SizedBox(height: AppSpacing.lg),
              FilledButton(
                onPressed: () {
                  if (c.text.trim().isNotEmpty) {
                    Navigator.of(sheet).pop(c.text.trim());
                  }
                },
                child: const Text('Add'),
              ),
            ],
          ),
        ),
      ),
    ),
  ).whenComplete(c.dispose);
}

/// Job categories and skills used by onboarding, search and matching.
class AdminCategoriesScreen extends ConsumerWidget {
  const AdminCategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final categories = ref.watch(adminCategoriesProvider);
    return AdminPage(
      title: 'Categories and skills',
      intro:
          'Categories appear in onboarding and search. Skills help match CVs to jobs.',
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.ink,
        foregroundColor: AppColors.onInk,
        onPressed: () async {
          final name = await _askValue(
            context,
            'New category',
            'e.g. Healthcare',
          );
          if (name != null) {
            ref.read(adminCategoriesProvider.notifier).addCategory(name);
          }
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('Category'),
      ),
      children: [
        for (final c in categories)
          AppSurface(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(c.name, style: text.titleMedium)),
                    Text('${c.skills.length} skills', style: text.bodySmall),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    for (final s in c.skills)
                      InfoPill(
                        label: s,
                        background: AppColors.surfaceMuted,
                        foreground: AppColors.ink,
                      ),
                    ActionChip(
                      avatar: const Icon(Icons.add_rounded, size: 16),
                      label: const Text('Skill'),
                      tooltip: 'Add a skill to ${c.name}',
                      onPressed: () async {
                        final skill = await _askValue(
                          context,
                          'Add skill to ${c.name}',
                          'e.g. Kotlin',
                        );
                        if (skill != null) {
                          ref
                              .read(adminCategoriesProvider.notifier)
                              .addSkill(c.name, skill);
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Platform announcements (guide §3.7 "Notifications").
class AdminAnnouncementsScreen extends ConsumerStatefulWidget {
  const AdminAnnouncementsScreen({super.key});

  @override
  ConsumerState<AdminAnnouncementsScreen> createState() =>
      _AdminAnnouncementsScreenState();
}

class _AdminAnnouncementsScreenState
    extends ConsumerState<AdminAnnouncementsScreen> {
  final _title = TextEditingController();
  final _message = TextEditingController();
  Audience _audience = Audience.everyone;
  bool _sending = false;
  String? _error;

  @override
  void dispose() {
    _title.dispose();
    _message.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_title.text.trim().isEmpty || _message.text.trim().isEmpty) {
      setState(() => _error = 'Add a title and a message.');
      return;
    }
    setState(() {
      _sending = true;
      _error = null;
    });
    await ref
        .read(announcementsProvider.notifier)
        .send(_title.text.trim(), _message.text.trim(), _audience);
    if (!mounted) return;
    setState(() => _sending = false);
    _title.clear();
    _message.clear();
    AppFeedback.show(
      context,
      'Announcement sent to ${_audience.label.toLowerCase()}',
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final sent = ref.watch(announcementsProvider);
    return AdminPage(
      title: 'Announcements',
      intro: 'Sent as in-app and push notifications.',
      children: [
        AppSurface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_error != null) ...[
                InlineBanner(message: _error!, tone: BannerTone.error),
                const SizedBox(height: AppSpacing.md),
              ],
              AppTextField(
                label: 'Title',
                controller: _title,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                label: 'Message',
                controller: _message,
                maxLines: 4,
                maxLength: 280,
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.newline,
                textCapitalization: TextCapitalization.sentences,
              ),
              const FieldLabel('Send to'),
              ChoiceChipGroup<Audience>(
                options: Audience.values,
                selected: {_audience},
                multiSelect: false,
                labelOf: (a) => a.label,
                onChanged: (s) => setState(() => _audience = s.first),
              ),
              const SizedBox(height: AppSpacing.lg),
              LoadingButton(
                label: 'Send announcement',
                icon: Icons.send_rounded,
                loading: _sending,
                onPressed: _send,
              ),
            ],
          ),
        ),
        const GroupLabel('Sent'),
        for (final a in sent)
          AppSurface(
            elevated: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(a.title, style: text.titleSmall),
                Text(a.message, style: text.bodyMedium),
                const SizedBox(height: 4),
                Text(
                  '${a.audience.label} · ${formatAgo(a.sentAt)}',
                  style: text.bodySmall,
                ),
              ],
            ),
          ),
      ],
    );
  }
}
