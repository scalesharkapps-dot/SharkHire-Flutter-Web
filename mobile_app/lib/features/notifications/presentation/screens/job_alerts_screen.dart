import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/feedback.dart';
import '../../../../shared/widgets/app_surface.dart';
import '../../../../shared/widgets/form_fields.dart';
import '../../../../shared/widgets/state_views.dart';
import '../providers/notifications_provider.dart';

/// Saved search alerts (guide §3.5 "job alerts", `job_alerts`).
class JobAlertsScreen extends ConsumerWidget {
  const JobAlertsScreen({super.key});

  Future<void> _create(BuildContext context, WidgetRef ref) async {
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      builder: (_) => const _NewAlertSheet(),
    );
    if ((created ?? false) && context.mounted) {
      AppFeedback.show(context, 'Job alert created');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alerts = ref.watch(jobAlertsProvider);
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Job alerts')),
      floatingActionButton: alerts.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _create(context, ref),
              backgroundColor: AppColors.ink,
              foregroundColor: AppColors.onInk,
              icon: const Icon(Icons.add_rounded),
              label: const Text('New alert'),
            ),
      body: alerts.isEmpty
          ? EmptyStateView(
              icon: Icons.notifications_active_outlined,
              title: 'No job alerts yet',
              message:
                  'Create an alert and we\'ll tell you when new jobs match it.',
              actionLabel: 'Create alert',
              onAction: () => _create(context, ref),
            )
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screenHorizontal,
                    0,
                    AppSpacing.screenHorizontal,
                    96,
                  ),
                  children: [
                    Text(
                      'We check for new jobs and notify you.',
                      style: text.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    for (final a in alerts)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: AppSurface(
                          child: Row(
                            children: [
                              Icon(
                                a.isActive
                                    ? Icons.notifications_none_rounded
                                    : Icons.notifications_off_outlined,
                                color: a.isActive
                                    ? AppColors.textSecondary
                                    : AppColors.textTertiary,
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(a.name, style: text.titleSmall),
                                    Text(
                                      [
                                        '"${a.query}"',
                                        if (a.filtersLabel != null)
                                          a.filtersLabel!,
                                        a.frequency == AlertFrequency.daily
                                            ? 'Daily'
                                            : 'Weekly',
                                      ].join(' · '),
                                      style: text.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                              Switch(
                                value: a.isActive,
                                activeTrackColor: AppColors.ocean,
                                onChanged: (_) => ref
                                    .read(jobAlertsProvider.notifier)
                                    .toggle(a.id),
                              ),
                              PopupMenuButton<String>(
                                tooltip: 'More options for ${a.name}',
                                onSelected: (_) {
                                  ref
                                      .read(jobAlertsProvider.notifier)
                                      .remove(a.id);
                                  AppFeedback.show(context, 'Alert deleted');
                                },
                                itemBuilder: (_) => const [
                                  PopupMenuItem(
                                    value: 'delete',
                                    child: Text('Delete alert'),
                                  ),
                                ],
                              ),
                            ],
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

class _NewAlertSheet extends ConsumerStatefulWidget {
  const _NewAlertSheet();

  @override
  ConsumerState<_NewAlertSheet> createState() => _NewAlertSheetState();
}

class _NewAlertSheetState extends ConsumerState<_NewAlertSheet> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _query = TextEditingController();
  AlertFrequency _frequency = AlertFrequency.daily;

  @override
  void dispose() {
    _name.dispose();
    _query.dispose();
    super.dispose();
  }

  void _save() {
    if (!(_form.currentState?.validate() ?? false)) return;
    ref
        .read(jobAlertsProvider.notifier)
        .add(_name.text.trim(), _query.text.trim(), _frequency);
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenHorizontal,
            0,
            AppSpacing.screenHorizontal,
            AppSpacing.lg,
          ),
          child: Form(
            key: _form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('New job alert', style: text.headlineSmall),
                const SizedBox(height: AppSpacing.lg),
                AppTextField(
                  label: 'Alert name',
                  controller: _name,
                  hint: 'e.g. Remote Flutter jobs',
                  textCapitalization: TextCapitalization.sentences,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Give the alert a name'
                      : null,
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  label: 'Keywords',
                  controller: _query,
                  hint: 'Job title or skill',
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Enter a job title or skill'
                      : null,
                ),
                const SizedBox(height: AppSpacing.lg),
                const FieldLabel('How often'),
                ChoiceChipGroup<AlertFrequency>(
                  options: AlertFrequency.values,
                  selected: {_frequency},
                  multiSelect: false,
                  labelOf: (f) =>
                      f == AlertFrequency.daily ? 'Daily' : 'Weekly',
                  onChanged: (s) => setState(() => _frequency = s.first),
                ),
                const SizedBox(height: AppSpacing.xl),
                FilledButton(
                  onPressed: _save,
                  child: const Text('Create alert'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
