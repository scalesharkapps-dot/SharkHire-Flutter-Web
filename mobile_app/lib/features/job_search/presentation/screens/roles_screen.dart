import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/bold_kit.dart';
import '../../../profile/presentation/providers/current_user_provider.dart';
import '../providers/explore_providers.dart';

/// "Your roles" (Bold concept): spin a curved wheel of job titles, then open
/// Explore filtered to the chosen role.
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
        if (seen.add(t.toLowerCase())) t,
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
                        style: TextStyle(
                          fontFamily: AppFonts.label,
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                          letterSpacing: 2,
                          color: Bold.accent,
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
              Expanded(
                child: LayoutBuilder(
                  builder: (context, c) => Stack(
                    children: [
                      Positioned.fill(
                        child: CustomPaint(painter: _RingsPainter()),
                      ),
                      // Selection band and teal capsule.
                      Center(
                        child: Container(
                          height: 58,
                          decoration: const BoxDecoration(
                            color: Color(0xFF0B141D),
                            border: Border.symmetric(
                              horizontal: BorderSide(color: Color(0xFF142130)),
                            ),
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Container(
                          width: 8,
                          height: 40,
                          decoration: const BoxDecoration(
                            color: Bold.accent,
                            borderRadius: BorderRadius.horizontal(
                              left: Radius.circular(4),
                            ),
                          ),
                        ),
                      ),
                      ListWheelScrollView.useDelegate(
                        controller: _wheel,
                        itemExtent: 58,
                        diameterRatio: 1.6,
                        perspective: 0.004,
                        offAxisFraction: -0.55,
                        overAndUnderCenterOpacity: 0.45,
                        physics: const FixedExtentScrollPhysics(),
                        onSelectedItemChanged: (i) {
                          HapticFeedback.selectionClick();
                          setState(() => _selected = i);
                        },
                        childDelegate: ListWheelChildBuilderDelegate(
                          childCount: roles.length,
                          builder: (context, i) => _RoleItem(
                            label: roles[i],
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
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'SELECTED · MATCHED TO YOUR CV',
                                  style: TextStyle(
                                    fontFamily: AppFonts.label,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 10,
                                    letterSpacing: 1.8,
                                    color: Bold.faint,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    selected,
                                    maxLines: 1,
                                    style: const TextStyle(
                                      fontFamily: AppFonts.display,
                                      fontSize: 22,
                                      color: Bold.ink,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: 34,
                            height: 34,
                            decoration: const BoxDecoration(
                              color: Bold.accent,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check_rounded,
                              size: 18,
                              color: Bold.onLight,
                            ),
                          ),
                        ],
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
                        label: 'Show these jobs',
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

class _RoleItem extends StatelessWidget {
  const _RoleItem({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = active ? Bold.accent : Bold.ink;
    return Semantics(
      button: true,
      selected: active,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.only(left: 24, right: 34),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Flexible(
                // The selected role shrinks to fit instead of being cut off.
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(
                    active ? label.toUpperCase() : label,
                    maxLines: 1,
                    style: TextStyle(
                      fontFamily: active ? AppFonts.display : AppFonts.label,
                      fontWeight: active ? FontWeight.w400 : FontWeight.w600,
                      fontSize: active ? 28 : 19,
                      color: color,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                size: active ? 26 : 18,
                color: color,
              ),
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

/// Two arcs curving with the wheel on the right edge.
class _RingsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width + size.height * 0.18, size.height / 2);
    final inner = Paint()
      ..color = const Color(0xFF1A2531)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    final outer = Paint()
      ..color = const Color(0xFF121B25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawCircle(center, size.height * 0.48, inner);
    canvas.drawCircle(center, size.height * 0.8, outer);
    // Small mark at the selected position.
    final mark = Offset(center.dx - size.height * 0.48, center.dy);
    canvas.drawCircle(
      mark,
      math.max(2.5, size.height * 0.008),
      Paint()..color = Bold.accent,
    );
  }

  @override
  bool shouldRepaint(_RingsPainter old) => false;
}
