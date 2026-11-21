import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/feedback.dart';
import '../../../../shared/widgets/app_surface.dart';
import '../../../../shared/widgets/bottom_action_bar.dart';
import '../../../../shared/widgets/form_fields.dart';
import '../../../../shared/widgets/menu_group.dart';
import '../../../../shared/widgets/appearance_picker.dart';
import '../../../../shared/widgets/status_chip.dart';
import '../../data/models/admin_models.dart';
import '../providers/admin_providers.dart';
import '../widgets/admin_widgets.dart';

/// External job provider usage and errors (guide §3.7, §3.9). The API key
/// lives only on the backend and is never shown in the app.
class AdminApiMonitoringScreen extends ConsumerWidget {
  const AdminApiMonitoringScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final logs = ref.watch(apiLogsProvider);
    final errors = logs.where((l) => !l.ok).length;
    final avg = logs.isEmpty
        ? 0
        : logs.map((l) => l.latencyMs).reduce((a, b) => a + b) ~/ logs.length;
    return AdminPage(
      title: 'API monitoring',
      intro:
          'Results are cached, so opening dashboards doesn\'t spend requests.',
      children: [
        AppSurface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('JSearch requests this month', style: text.titleMedium),
              const SizedBox(height: AppSpacing.lg),
              UsageMeter(
                used: ref.watch(jsearchUsageProvider),
                limit: ref.watch(platformSettingsProvider).jsearchMonthlyLimit,
              ),
            ],
          ),
        ),
        StatGrid(
          tiles: [
            StatTile(
              label: 'Error rate',
              value: logs.isEmpty
                  ? '0%'
                  : '${(errors / logs.length * 100).round()}%',
              icon: Icons.error_outline_rounded,
            ),
            StatTile(
              label: 'Avg. response',
              value: '${avg}ms',
              icon: Icons.speed_rounded,
            ),
          ],
        ),
        const GroupLabel('Recent requests'),
        for (final l in logs)
          AppSurface(
            elevated: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(l.endpoint, style: text.titleSmall)),
                    StatusChip(
                      label: l.ok
                          ? '${l.statusCode} OK'
                          : (l.statusCode == 429
                                ? '429 Rate limited'
                                : '${l.statusCode} Error'),
                      tone: l.ok ? StatusTone.positive : StatusTone.negative,
                    ),
                  ],
                ),
                Text(
                  l.query,
                  style: text.bodyMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${formatAgo(l.at)} · ${l.results} ${l.results == 1 ? 'result' : 'results'} · ${l.latencyMs}ms',
                  style: text.bodySmall,
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Reports and analytics (example figures until the analytics API exists).
class AdminAnalyticsScreen extends StatelessWidget {
  const AdminAnalyticsScreen({super.key});

  static const _weeks = ['W1', 'W2', 'W3', 'W4', 'W5', 'W6'];
  static const _top = [
    ('Software', 46),
    ('Data / AI', 28),
    ('Design', 14),
    ('Marketing', 8),
    ('Finance', 4),
  ];

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    Widget chart(String title, String sub, List<int> values) => AppSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: text.titleMedium),
          Text(sub, style: text.bodySmall),
          const SizedBox(height: AppSpacing.lg),
          BarChart(values: values, labels: _weeks),
        ],
      ),
    );
    return AdminPage(
      title: 'Analytics',
      intro:
          'Last six weeks. Figures are example data until the analytics API is connected.',
      children: [
        const StatGrid(
          tiles: [
            StatTile(
              label: 'Weekly active users',
              value: '1,284',
              icon: Icons.people_alt_outlined,
            ),
            StatTile(
              label: 'New CVs this month',
              value: '418',
              icon: Icons.upload_file_rounded,
            ),
            StatTile(
              label: 'Jobs published',
              value: '96',
              icon: Icons.work_outline_rounded,
            ),
            StatTile(
              label: 'External apply clicks',
              value: '2,310',
              icon: Icons.open_in_new_rounded,
            ),
          ],
        ),
        chart('New sign-ups', 'Job seekers and employers per week', const [
          120,
          160,
          148,
          210,
          240,
          286,
        ]),
        chart('Applications', 'In-app applications per week', const [
          58,
          74,
          69,
          92,
          118,
          136,
        ]),
        AppSurface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Top categories', style: text.titleMedium),
              Text('Share of job views this month', style: text.bodySmall),
              const SizedBox(height: AppSpacing.lg),
              for (final (name, pct) in _top)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 96,
                        child: Text(
                          name,
                          style: text.bodyMedium,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: AppRadius.pillAll,
                          child: LinearProgressIndicator(
                            value: pct / 100,
                            minHeight: 10,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 44,
                        child: Text(
                          '$pct%',
                          textAlign: TextAlign.right,
                          style: text.labelMedium,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Every admin action (`admin_audit_logs`). Read-only.
class AdminAuditLogsScreen extends ConsumerStatefulWidget {
  const AdminAuditLogsScreen({super.key});

  @override
  ConsumerState<AdminAuditLogsScreen> createState() =>
      _AdminAuditLogsScreenState();
}

class _AdminAuditLogsScreenState extends ConsumerState<AdminAuditLogsScreen> {
  String? _type;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final all = ref.watch(auditLogProvider);
    final types = {for (final e in all) e.entityType}.toList()..sort();
    final shown = _type == null
        ? all
        : all.where((e) => e.entityType == _type).toList();
    return AdminPage(
      title: 'Audit logs',
      intro:
          'Every admin action is recorded. Entries can\'t be edited or deleted.',
      children: [
        ChoiceChipGroup<String?>(
          options: [null, ...types],
          selected: {_type},
          multiSelect: false,
          labelOf: (t) => t ?? 'All',
          onChanged: (s) => setState(() => _type = s.first),
        ),
        for (final e in shown)
          AppSurface(
            elevated: false,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: Icon(
                    Icons.history_rounded,
                    color: AppColors.ocean,
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(e.action, style: text.titleSmall),
                      Text(
                        '${e.entityType}: ${e.entityLabel}',
                        style: text.bodyMedium,
                      ),
                      if (e.details != null)
                        Text(e.details!, style: text.bodySmall),
                      const SizedBox(height: 2),
                      Text(
                        '${e.admin} · ${formatDate(e.at)} · ${formatAgo(e.at)}',
                        style: text.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Platform preferences (guide §3.7 "Settings").
class AdminSettingsScreen extends ConsumerStatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  ConsumerState<AdminSettingsScreen> createState() =>
      _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends ConsumerState<AdminSettingsScreen> {
  late PlatformSettings _s = ref.read(platformSettingsProvider);

  Widget _stepper(
    String label,
    String help,
    int value,
    ValueChanged<int> onChanged, {
    int min = 1,
    int max = 60,
    int step = 1,
  }) {
    final text = Theme.of(context).textTheme;
    return AppSurface(
      elevated: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: text.titleSmall),
          Text(help, style: text.bodySmall),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              IconButton.outlined(
                tooltip: 'Decrease $label',
                onPressed: value - step >= min
                    ? () => onChanged(value - step)
                    : null,
                icon: const Icon(Icons.remove_rounded),
              ),
              Expanded(
                child: Text(
                  '$value',
                  textAlign: TextAlign.center,
                  style: text.headlineSmall,
                ),
              ),
              IconButton.outlined(
                tooltip: 'Increase $label',
                onPressed: value + step <= max
                    ? () => onChanged(value + step)
                    : null,
                icon: const Icon(Icons.add_rounded),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final saved = ref.watch(platformSettingsProvider);
    final dirty = !identical(_s, saved);
    return Scaffold(
      appBar: AppBar(title: const Text('Platform settings')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenHorizontal,
              AppSpacing.xs,
              AppSpacing.screenHorizontal,
              AppSpacing.xxl,
            ),
            children: [
              const AppearancePicker(),
              const SizedBox(height: AppSpacing.xl),
              MenuGroup(
                title: 'Moderation',
                items: [
                  MenuItem(
                    Icons.fact_check_outlined,
                    'Approve employer jobs',
                    subtitle: 'New and edited jobs stay Pending until approved',
                    switchValue: _s.requireJobApproval,
                    onSwitch: (v) =>
                        setState(() => _s = _s.copyWith(requireJobApproval: v)),
                  ),
                  MenuItem(
                    Icons.construction_outlined,
                    'Maintenance banner',
                    subtitle:
                        'Tell users some features may be briefly unavailable',
                    switchValue: _s.maintenanceBanner,
                    onSwitch: (v) =>
                        setState(() => _s = _s.copyWith(maintenanceBanner: v)),
                  ),
                ],
              ),
              const GroupLabel('Data and limits'),
              const SizedBox(height: AppSpacing.sm),
              _stepper(
                'External listing lifetime (days)',
                'How long imported jobs stay visible.',
                _s.externalListingDays,
                (v) => setState(() => _s = _s.copyWith(externalListingDays: v)),
              ),
              const SizedBox(height: AppSpacing.md),
              _stepper(
                'CV retention (months)',
                'Inactive CVs are deleted after this.',
                _s.cvRetentionMonths,
                (v) => setState(() => _s = _s.copyWith(cvRetentionMonths: v)),
              ),
              const SizedBox(height: AppSpacing.md),
              _stepper(
                'JSearch monthly limit',
                'Match your RapidAPI plan so usage alerts are right.',
                _s.jsearchMonthlyLimit,
                (v) => setState(() => _s = _s.copyWith(jsearchMonthlyLimit: v)),
                min: 50,
                max: 100000,
                step: 50,
              ),
              const SizedBox(height: AppSpacing.lg),
              const InlineBanner(
                message:
                    'Changes apply to the whole platform and are recorded in the audit log.',
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomActionBar(
        child: LoadingButton(
          label: 'Save changes',
          onPressed: dirty
              ? () {
                  ref.read(platformSettingsProvider.notifier).save(_s);
                  setState(() {});
                  AppFeedback.show(context, 'Settings saved');
                }
              : null,
        ),
      ),
    );
  }
}
