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

/// "Your roles" (Bold concept): spin a wheel of job titles, each with its
/// best CV fit, then open Explore filtered to the chosen role.
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
  late final FixedExtentScrollController _wheel;

  /// Opens in the middle of the wheel so roles show above and below.
  static const _start = 2;
  int _selected = _start;

  @override
  void initState() {
    super.initState();
    _wheel = FixedExtentScrollController(initialItem: _start);
  }

  @override
  void dispose() {
    _wheel.dispose();
    super.dispose();
  }

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
    final selected = roles[_selected.clamp(0, roles.length - 1)];
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
                  AppSpacing.md,
                  AppSpacing.sm,
                  AppSpacing.xl,
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
                        color: Bold.ink,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    const Expanded(
                      child: Text(
                        'PICK YOUR NEXT ROLE',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: AppFonts.label,
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                          letterSpacing: 2,
                          color: Bold.muted,
                        ),
                      ),
                    ),
                    _RoundButton(
                      icon: Icons.search_rounded,
                      tooltip: 'Search jobs',
                      onTap: () => context.go(AppRoutes.explore),
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
              const SizedBox(height: AppSpacing.sm),
              Expanded(
                child: Stack(
                  children: [
                    // Solid accent band behind the selected role.
                    Center(
                      child: Container(
                        height: _itemExtent,
                        margin: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                        ),
                        decoration: const BoxDecoration(
                          color: Bold.accent,
                          borderRadius: BorderRadius.all(Radius.circular(18)),
                        ),
                      ),
                    ),
                    ListWheelScrollView.useDelegate(
                      controller: _wheel,
                      itemExtent: _itemExtent,
                      diameterRatio: 2.4,
                      perspective: 0.003,
                      overAndUnderCenterOpacity: 0.55,
                      physics: const FixedExtentScrollPhysics(),
                      onSelectedItemChanged: (i) {
                        HapticFeedback.selectionClick();
                        setState(() => _selected = i);
                      },
                      childDelegate: ListWheelChildBuilderDelegate(
                        childCount: roles.length,
                        builder: (context, i) => _RoleItem(
                          label: roles[i],
                          score: stats[roles[i]]?.best,
                          active: i == _selected,
                          onTap: () {
                            if (i == _selected) {
                              _open(roles[i]);
                            } else {
                              _wheel.animateToItem(
                                i,
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeOutCubic,
                              );
                            }
                          },
                        ),
                      ),
                    ),
                  ],
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
                  padding: const EdgeInsets.all(AppSpacing.lg + 2),
                  decoration: BoxDecoration(
                    color: Bold.raised,
                    borderRadius: const BorderRadius.all(Radius.circular(26)),
                    border: Border.all(color: Bold.raisedLine),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(text: 'SELECTED · '),
                            TextSpan(
                              text: 'MATCHED TO YOUR CV',
                              style: TextStyle(color: Bold.accent),
                            ),
                          ],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: AppFonts.label,
                          fontWeight: FontWeight.w800,
                          fontSize: 10,
                          letterSpacing: 1.8,
                          color: Bold.faint,
                        ),
                      ),
                      if (chips.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.md),
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
                        accent: true,
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

const double _itemExtent = 60;

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

class _RoleItem extends StatelessWidget {
  const _RoleItem({
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
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg + 16),
          child: Row(
            children: [
              Expanded(
                // Stays readable: wraps to two lines, never shrinks.
                child: Text(
                  active ? label.toUpperCase() : label,
                  maxLines: active ? 2 : 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: active ? AppFonts.display : AppFonts.label,
                    fontWeight: active ? FontWeight.w400 : FontWeight.w600,
                    fontSize: active ? 19 : 17,
                    height: 1.05,
                    letterSpacing: active ? 0.2 : 0,
                    color: active ? Bold.onLight : Bold.ink,
                  ),
                ),
              ),
              if (score != null) ...[
                const SizedBox(width: AppSpacing.sm),
                if (active)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: const BoxDecoration(
                      color: Bold.onLight,
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                    ),
                    child: Text(
                      '$score% fit',
                      style: const TextStyle(
                        fontFamily: AppFonts.label,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        color: Bold.accent,
                      ),
                    ),
                  )
                else
                  Text(
                    '$score%',
                    style: const TextStyle(
                      fontFamily: AppFonts.label,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: Bold.muted,
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: tooltip,
    child: Material(
      color: Bold.raised,
      shape: const CircleBorder(side: BorderSide(color: Bold.raisedLine)),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox.square(
          dimension: 48,
          child: Icon(icon, size: 20, color: Bold.ink),
        ),
      ),
    ),
  );
}
