import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import 'brand_logo.dart';

/// One bottom-navigation tab.
class ShellTab {
  const ShellTab(this.label, this.icon, this.selectedIcon);
  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

/// Job seeker tabs (guide §3.10 A): Home | Explore | Saved | Profile.
const seekerTabs = [
  ShellTab('Home', Icons.home_outlined, Icons.home_rounded),
  ShellTab('Explore', Icons.explore_outlined, Icons.explore_rounded),
  ShellTab('Saved', Icons.bookmark_border_rounded, Icons.bookmark_rounded),
  ShellTab('Profile', Icons.person_outline_rounded, Icons.person_rounded),
];

/// Employer tabs (mockup 4.5): Overview | Jobs | Applicants | Company.
const employerTabs = [
  ShellTab(
    'Overview',
    Icons.space_dashboard_outlined,
    Icons.space_dashboard_rounded,
  ),
  ShellTab('Jobs', Icons.work_outline_rounded, Icons.work_rounded),
  ShellTab('Applicants', Icons.groups_outlined, Icons.groups_rounded),
  ShellTab('Company', Icons.apartment_outlined, Icons.apartment_rounded),
];

/// Admin tabs (guide §3.7, on mobile): Overview | Jobs | Users | More.
const adminTabs = [
  ShellTab(
    'Overview',
    Icons.space_dashboard_outlined,
    Icons.space_dashboard_rounded,
  ),
  ShellTab('Jobs', Icons.fact_check_outlined, Icons.fact_check_rounded),
  ShellTab('Users', Icons.people_outline_rounded, Icons.people_rounded),
  ShellTab('More', Icons.grid_view_rounded, Icons.grid_view_rounded),
];

/// Scaffold with a persistent bottom navigation bar. Each tab keeps its own
/// navigation stack (GoRouter `StatefulShellRoute`).
class MainNavigationShell extends StatelessWidget {
  const MainNavigationShell({
    super.key,
    required this.navigationShell,
    this.tabs = seekerTabs,
  });

  final StatefulNavigationShell navigationShell;
  final List<ShellTab> tabs;

  void _onTap(int index) {
    navigationShell.goBranch(
      index,
      // Tapping the active tab again returns it to its first screen.
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  /// From this width the app uses a side rail instead of a bottom bar.
  static const double railBreakpoint = 900;

  /// From this width the rail shows labels (sidebar).
  static const double sidebarBreakpoint = 1200;

  /// Content never stretches wider than this on large screens.
  static const double maxContentWidth = 1080;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < railBreakpoint) {
      return Scaffold(
        body: navigationShell,
        bottomNavigationBar: DecoratedBox(
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: NavigationBar(
            selectedIndex: navigationShell.currentIndex,
            onDestinationSelected: _onTap,
            destinations: [
              for (final t in tabs)
                NavigationDestination(
                  icon: Icon(t.icon),
                  selectedIcon: Icon(t.selectedIcon),
                  label: t.label,
                ),
            ],
          ),
        ),
      );
    }

    // Tablet and desktop: side navigation, centred content column.
    final extended = width >= sidebarBreakpoint;
    return Scaffold(
      body: Row(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border(right: BorderSide(color: AppColors.border)),
            ),
            child: SafeArea(
              right: false,
              child: NavigationRail(
                extended: extended,
                minExtendedWidth: 232,
                selectedIndex: navigationShell.currentIndex,
                onDestinationSelected: _onTap,
                labelType: extended
                    ? NavigationRailLabelType.none
                    : NavigationRailLabelType.all,
                leading: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.lg,
                    AppSpacing.lg,
                    AppSpacing.xxl,
                  ),
                  child: extended
                      ? const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SharkMark(size: 30),
                            SizedBox(width: AppSpacing.sm),
                            SharkHireWordmark(fontSize: 19),
                          ],
                        )
                      : const SharkMark(size: 32),
                ),
                destinations: [
                  for (final t in tabs)
                    NavigationRailDestination(
                      icon: Icon(t.icon),
                      selectedIcon: Icon(t.selectedIcon),
                      label: Text(t.label),
                    ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: maxContentWidth),
                child: navigationShell,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
