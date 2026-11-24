import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/models/job_summary.dart';
import '../../../../shared/widgets/bold_kit.dart';
import '../../../profile/presentation/providers/current_user_provider.dart';
import '../providers/explore_providers.dart';

/// "Your roles" (Bold concept): job titles ranked by your best CV fit;
/// pick one, then open Explore filtered to it.
class RolesScreen extends ConsumerStatefulWidget {
  const RolesScreen({super.key});

  /// Shown when no job titles are loaded yet.
  static const fallbackRoles = [
    'Product Manager',
    'Python Developer',
    'Flutter Developer',
    'Data Analyst',
    'QA Engineer',
    'UI/UX Designer',
    'DevOps Engineer',
  ];

  /// Turns a long posting title into a short role name for the wheel, e.g.
  /// "Python Developers Hiring - Lahore | Urgent" → "Python Developers".
  static String shortRole(String title) {
    var t = title.trim();
    // Drop a leading "Hiring:" / "Urgent" style prefix.
    t = t.replaceFirst(
      RegExp(
        r'^(urgent(ly)?|now|we are|we.re)?\s*(hiring|wanted|required)\b[\s:!\-–—|]*',
        caseSensitive: false,
      ),
      '',
    );
    // Keep the part before separators, locations and "hiring" tails.
    t = t.split(RegExp(r'\s[-–—|]\s|[|(\[,:;!]|\s[-–—]')).first;
    t = t
        .split(
          RegExp(
            r'\s(hiring|wanted|required|needed|urgent(ly)?|at|for|in|with|job|jobs|opportunity)\b',
            caseSensitive: false,
          ),
        )
        .first;
    final words = t.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
    final short = words.take(4).join(' ');
    return short.isEmpty ? title.trim() : short;
  }

  @override
  ConsumerState<RolesScreen> createState() => _RolesScreenState();
}

class _RolesScreenState extends ConsumerState<RolesScreen> {
  /// Starts a little down the list, like the mockup.
  static const _start = 2;
  int _selected = _start;

  List<String> _roles(List<String> loaded) {
    final seen = <String>{};
    final roles = [
      for (final t in [...loaded, ...RolesScreen.fallbackRoles])
        if (RolesScreen.shortRole(t) case final r
            when r.isNotEmpty && seen.add(r.toLowerCase()))
          r,
    ];
    return roles;
  }

  void _open(String role) {
    ref.read(exploreControllerProvider.notifier)
      ..reset()
      ..setQuery(role);
    context.go(AppRoutes.explore);
  }

  @override
  Widget build(BuildContext context) {
    final jobs = ref.watch(allJobsProvider).value ?? const [];
    final roles = _roles([for (final j in jobs) j.title]);
    final selectedIndex = _selected.clamp(0, roles.length - 1);
    final selected = roles[selectedIndex];
    final prefs = ref.watch(jobPreferencesProvider);
    final chips = <String>[
      if (prefs.includePakistan) 'Pakistan',
      if (prefs.includeInternational) 'Worldwide',
      for (final m in prefs.workModes) m.label,
      for (final e in prefs.employmentTypes) e.label,
    ];

    final stats = _stats(roles, jobs);
    final count = stats[selected]?.count ?? 0;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Bold.ground,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xs,
                  AppSpacing.xs,
                  AppSpacing.xs,
                  0,
                ),
                child: Row(
                  children: [
                    IconButton(
                      tooltip: 'Back',
                      onPressed: () => context.canPop()
                          ? context.pop()
                          : context.go(AppRoutes.explore),
                      icon: const Icon(
                        Icons.arrow_back_rounded,
                        color: Bold.muted,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      tooltip: 'Search jobs',
                      onPressed: () => context.go(AppRoutes.explore),
                      icon: const Icon(Icons.search_rounded, color: Bold.muted),
                    ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.xl,
                  AppSpacing.sm,
                  AppSpacing.xl,
                  0,
                ),
                child: BoldHeadline(
                  semanticsLabel: 'Your roles',
                  fontSize: 56,
                  spans: [('Your\nroles', false), ('.', true)],
                ),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.xl,
                  AppSpacing.sm,
                  AppSpacing.xl,
                  0,
                ),
                child: Text(
                  'Ranked by your best fit in each role',
                  style: TextStyle(
                    fontFamily: AppFonts.body,
                    fontSize: 15,
                    color: Bold.muted,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                  ),
                  itemCount: roles.length,
                  itemBuilder: (context, i) => _RoleRow(
                    label: roles[i],
                    score: stats[roles[i]]?.best,
                    active: i == selectedIndex,
                    onTap: () {
                      if (i == selectedIndex) {
                        _open(roles[i]);
                      } else {
                        HapticFeedback.selectionClick();
                        setState(() => _selected = i);
                      }
                    },
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.sm,
                  AppSpacing.lg,
                  AppSpacing.lg,
                ),
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: Bold.raised,
                    borderRadius: const BorderRadius.all(Radius.circular(20)),
                    border: Border.all(color: Bold.raisedLine),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Selected · matched to your CV',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: AppFonts.label,
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                          color: Bold.muted,
                        ),
                      ),
                      if (chips.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.sm),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            for (final c in chips.take(4)) BoldChip(c),
                          ],
                        ),
                      ],
                      const SizedBox(height: AppSpacing.md),
                      BoldPrimaryButton(
                        label: count > 0
                            ? 'Show $count ${count == 1 ? 'job' : 'jobs'}'
                            : 'Show these jobs',
                        trailingArrow: true,
                        onPressed: () => _open(selected),
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

/// How many loaded jobs match a role, and the best CV fit among them.
typedef _RoleStats = ({int count, int? best});

Map<String, _RoleStats> _stats(List<String> roles, List<JobSummary> jobs) {
  final out = <String, _RoleStats>{};
  for (final role in roles) {
    final r = role.toLowerCase();
    var count = 0;
    int? best;
    for (final j in jobs) {
      if (!j.title.toLowerCase().contains(r)) continue;
      count++;
      final s = j.matchScore;
      if (s != null && (best == null || s > best)) best = s;
    }
    out[role] = (count: count, best: best);
  }
  return out;
}

/// One role in the list: name on the left, best fit on the right. The
/// selected row is a raised surface with a thin teal outline.
class _RoleRow extends StatelessWidget {
  const _RoleRow({
    required this.label,
    required this.score,
    required this.active,
    required this.onTap,
  });

  final String label;
  final int? score;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final score = this.score;
    final fit = score == null ? '' : ', $score% fit';
    return Semantics(
      button: true,
      selected: active,
      label: '$label$fit',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Material(
          color: active ? Bold.chip : Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: const BorderRadius.all(Radius.circular(12)),
            side: active
                ? BorderSide(color: Bold.accent.withValues(alpha: 0.45))
                : BorderSide.none,
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: const BorderRadius.all(Radius.circular(12)),
            child: SizedBox(
              height: 56,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: AppFonts.label,
                          fontWeight: active
                              ? FontWeight.w600
                              : FontWeight.w500,
                          fontSize: active ? 17 : 16,
                          color: active ? Bold.ink : Bold.muted,
                        ),
                      ),
                    ),
                    if (score != null) ...[
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        '$score',
                        style: TextStyle(
                          fontFamily: AppFonts.display,
                          fontSize: 16,
                          color: active ? Bold.accent : Bold.faint,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
