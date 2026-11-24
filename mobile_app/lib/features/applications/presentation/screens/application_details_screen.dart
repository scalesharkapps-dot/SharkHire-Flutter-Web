import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/feedback.dart';
import '../../../../shared/models/job_summary.dart';
import '../../../../shared/widgets/app_surface.dart';
import '../../../../shared/widgets/form_fields.dart';
import '../../../../shared/widgets/state_views.dart';
import '../../../../shared/widgets/status_chip.dart';
import '../../data/models/application.dart';
import '../providers/applications_provider.dart';

/// One application: progress, history and withdraw (guide §3.5).
class ApplicationDetailsScreen extends ConsumerStatefulWidget {
  const ApplicationDetailsScreen({super.key, required this.applicationId});

  final String applicationId;

  @override
  ConsumerState<ApplicationDetailsScreen> createState() =>
      _ApplicationDetailsScreenState();
}

class _ApplicationDetailsScreenState
    extends ConsumerState<ApplicationDetailsScreen> {
  bool _withdrawing = false;

  Future<void> _withdraw(JobApplication a) async {
    final ok = await showModalBottomSheet<bool>(
      context: context,
      useRootNavigator: true,
      builder: (sheet) {
        final text = Theme.of(sheet).textTheme;
        return SafeArea(
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
                Text('Withdraw this application?', style: text.headlineSmall),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  '${a.job.companyName} will be told you\'re no longer interested in ${a.job.title}. '
                  'You can\'t undo this.',
                  style: text.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.error,
                  ),
                  onPressed: () => Navigator.of(sheet).pop(true),
                  child: const Text('Withdraw application'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(sheet).pop(false),
                  child: const Text('Keep it'),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (!(ok ?? false) || !mounted) return;
    setState(() => _withdrawing = true);
    try {
      await ref.read(applicationsProvider.notifier).withdraw(a.id);
      if (!mounted) return;
      AppFeedback.show(context, 'Application withdrawn');
    } catch (e) {
      if (!mounted) return;
      AppFeedback.show(context, friendlyErrorMessage(e));
    } finally {
      if (mounted) setState(() => _withdrawing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final a = ref.watch(
      applicationsProvider.select(
        (apps) => apps.where((x) => x.id == widget.applicationId).firstOrNull,
      ),
    );

    if (a == null) {
      return Scaffold(
        appBar: AppBar(),
        body: EmptyStateView(
          icon: Icons.search_off_rounded,
          title: 'Application not found',
          message: 'It may have been removed.',
          actionLabel: 'See my applications',
          onAction: () => context.pushReplacement(AppRoutes.applications),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Application')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenHorizontal,
              AppSpacing.sm,
              AppSpacing.screenHorizontal,
              AppSpacing.xxxl,
            ),
            children: [
              AppSurface(
                onTap: () => context.push(AppRoutes.jobDetails(a.job.id)),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(a.job.title, style: text.titleMedium),
                          Text(
                            '${a.job.companyName} · ${a.job.location}',
                            style: text.bodySmall,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          StatusChip.application(a.status),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.textTertiary,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              _Progress(application: a),
              const SizedBox(height: AppSpacing.xxl),
              Text('History', style: text.titleMedium),
              const SizedBox(height: AppSpacing.md),
              _Timeline(history: a.history.reversed.toList()),
              const SizedBox(height: AppSpacing.xl),
              Text('What you sent', style: text.titleMedium),
              const SizedBox(height: AppSpacing.md),
              AppSurface(
                elevated: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.description_outlined,
                          size: 20,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            a.cvFileName ?? 'CV',
                            style: text.titleSmall,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Cover letter',
                      style: text.labelMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      a.coverLetter ?? 'No cover letter',
                      style: text.bodyMedium,
                    ),
                  ],
                ),
              ),
              if (a.canWithdraw) ...[
                const SizedBox(height: AppSpacing.xxl),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: BorderSide(color: AppColors.errorTint, width: 1.4),
                  ),
                  onPressed: _withdrawing ? null : () => _withdraw(a),
                  child: Text(
                    _withdrawing ? 'Withdrawing…' : 'Withdraw application',
                  ),
                ),
              ] else if (a.status == ApplicationStatus.withdrawn) ...[
                const SizedBox(height: AppSpacing.xl),
                const InlineBanner(message: 'You withdrew this application.'),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Segmented tracker: Submitted → Review → Shortlist → Interview → Accepted.
class _Progress extends StatelessWidget {
  const _Progress({required this.application});

  final JobApplication application;

  static const _short = [
    'Submitted',
    'Review',
    'Shortlist',
    'Interview',
    'Accepted',
  ];

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final ended =
        application.status == ApplicationStatus.rejected ||
        application.status == ApplicationStatus.withdrawn;
    final reached = application.history.map((h) => h.status).toSet();
    final index = applicationFlow.indexOf(application.status);
    // When the application ended, the last step it reached stays marked.
    final last = index >= 0
        ? index
        : [
            for (var i = 0; i < applicationFlow.length; i++)
              if (reached.contains(applicationFlow[i])) i,
          ].fold<int>(-1, (a, b) => b > a ? b : a);
    final done = AppColors.isDark ? const Color(0xFF5A6B7C) : AppColors.navy;
    final empty = AppColors.isDark ? const Color(0xFF1E2833) : AppColors.tonal;
    final now = AppColors.isDark ? AppColors.teal : const Color(0xFF0B8496);
    final note = application.history.last.note;
    final next = index >= 0 && index < applicationFlow.length - 1
        ? applicationFlow[index + 1].label
        : null;

    Color segment(int i) => ended
        ? (i <= last ? done : empty)
        : i < last
        ? done
        : i == last
        ? now
        : empty;

    return AppSurface(
      elevated: false,
      padding: const EdgeInsets.all(AppSpacing.lg + 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(
                child: Text(
                  ended
                      ? (application.status == ApplicationStatus.rejected
                            ? 'Not successful'
                            : 'Withdrawn')
                      : application.status.label,
                  style: text.titleMedium,
                ),
              ),
              if (!ended && index >= 0)
                Text(
                  'Step ${index + 1} of ${applicationFlow.length}',
                  style: text.labelMedium?.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              for (var i = 0; i < applicationFlow.length; i++) ...[
                if (i > 0) const SizedBox(width: 4),
                Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    height: 6,
                    decoration: BoxDecoration(
                      color: segment(i),
                      borderRadius: AppRadius.pillAll,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              for (var i = 0; i < applicationFlow.length; i++) ...[
                if (i > 0) const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    i < _short.length ? _short[i] : applicationFlow[i].label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.labelSmall?.copyWith(
                      fontSize: 11,
                      fontWeight: !ended && i == last
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: !ended && i == last
                          ? now
                          : i <= last
                          ? AppColors.textSecondary
                          : AppColors.textTertiary,
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (ended || note != null || next != null) ...[
            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Text.rich(
              TextSpan(
                children: ended
                    ? [
                        TextSpan(
                          text: application.status == ApplicationStatus.rejected
                              ? 'This application wasn\'t successful.'
                              : 'You withdrew this application.',
                        ),
                      ]
                    : [
                        const TextSpan(text: 'Next: '),
                        TextSpan(
                          text: note ?? next,
                          style: TextStyle(
                            color: AppColors.ink,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
              ),
              style: text.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ],
      ),
    );
  }
}

class _Timeline extends StatelessWidget {
  const _Timeline({required this.history});

  final List<StatusChange> history;

  static String _date(DateTime d) {
    const m = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${d.day} ${m[d.month - 1]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      children: [
        for (var i = 0; i < history.length; i++)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: 24,
                  child: Column(
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: i == 0
                              ? toneOfApplication(history[i].status).fg
                              : AppColors.borderStrong,
                          shape: BoxShape.circle,
                        ),
                      ),
                      if (i < history.length - 1)
                        Expanded(
                          child: Container(width: 2, color: AppColors.border),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(history[i].status.label, style: text.titleSmall),
                        Text(_date(history[i].at), style: text.bodySmall),
                        if (history[i].note != null) ...[
                          const SizedBox(height: 4),
                          Text(history[i].note!, style: text.bodyMedium),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
