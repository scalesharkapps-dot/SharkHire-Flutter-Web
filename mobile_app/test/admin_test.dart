import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sharkhire/core/routing/app_routes.dart';
import 'package:sharkhire/core/routing/route_guard.dart';
import 'package:sharkhire/core/theme/app_theme.dart';
import 'package:sharkhire/features/admin/presentation/screens/admin_content_screens.dart';
import 'package:sharkhire/features/admin/presentation/screens/admin_jobs_screen.dart';
import 'package:sharkhire/features/admin/presentation/screens/admin_moderation_screens.dart';
import 'package:sharkhire/features/admin/presentation/screens/admin_more_screen.dart';
import 'package:sharkhire/features/admin/presentation/screens/admin_overview_screen.dart';
import 'package:sharkhire/features/admin/presentation/screens/admin_system_screens.dart';
import 'package:sharkhire/features/admin/presentation/screens/admin_users_screen.dart';
import 'package:sharkhire/features/authentication/domain/session.dart';
import 'package:sharkhire/features/authentication/presentation/providers/session_provider.dart';
import 'package:sharkhire/shared/models/app_user.dart';
import 'package:sharkhire/shared/models/domain_enums.dart';

import 'helpers.dart';

const adminSession = Session(
  user: AppUser(
    fullName: 'Sana Iqbal',
    email: 'admin@sharkhire.app',
    roles: {AppRole.admin},
  ),
  emailVerified: true,
  onboardingComplete: true,
);

Future<void> tapText(WidgetTester tester, String label) async {
  final f = find.text(label).last;
  await tester.ensureVisible(f);
  await tester.pumpAndSettle();
  await tester.tap(f);
  await tester.pumpAndSettle();
}

Future<void> launchAdmin(WidgetTester tester) async {
  usePhone(tester);
  await launchApp(tester, session: adminSession);
  await pumpUntil(tester, () => isShown(find.text('Overview')));
  await tester.pumpAndSettle();
}

final _screens = <String, Widget>{
  'overview': const AdminOverviewScreen(),
  'jobs': const AdminJobsScreen(),
  'users': const AdminUsersScreen(),
  'more': const AdminMoreScreen(),
  'employers': const AdminEmployersScreen(),
  'applications': const AdminApplicationsScreen(),
  'external listings': const AdminExternalJobsScreen(),
  'cv reports': const AdminCvReportsScreen(),
  'categories': const AdminCategoriesScreen(),
  'announcements': const AdminAnnouncementsScreen(),
  'api monitoring': const AdminApiMonitoringScreen(),
  'analytics': const AdminAnalyticsScreen(),
  'audit logs': const AdminAuditLogsScreen(),
  'settings': const AdminSettingsScreen(),
};

void main() {
  test('admins stay in the admin app; other roles can\'t enter it', () {
    expect(routeGuard(adminSession, AppRoutes.home), AppRoutes.adminOverview);
    expect(
      routeGuard(adminSession, AppRoutes.employerJobs),
      AppRoutes.adminOverview,
    );
    expect(routeGuard(adminSession, AppRoutes.adminAuditLogs), isNull);
    expect(routeGuard(seekerSession, AppRoutes.adminOverview), AppRoutes.home);
    expect(
      routeGuard(employerSession, AppRoutes.adminUsers),
      AppRoutes.employerOverview,
    );
  });

  testWidgets('Admin demo account logs in to the admin app', (tester) async {
    usePhone(tester);
    await launchApp(tester);
    await pumpUntil(
      tester,
      () => isShown(find.bySemanticsLabel('Find work that fits you.')),
    );
    await tapText(tester, 'Log in');
    await tapText(tester, 'Admin');
    final login = find.ancestor(
      of: find.text('Log in'),
      matching: find.byType(FilledButton),
    );
    await tester.ensureVisible(login);
    await tester.tap(login);
    await pumpUntil(tester, () => isShown(find.text('Overview')));
    expect(find.text('More'), findsOneWidget);
    expect(find.text('Explore'), findsNothing);
  });

  testWidgets('Approve and reject jobs; both appear in the audit log', (
    tester,
  ) async {
    await launchAdmin(tester);
    await tester.tap(find.text('Jobs').last);
    await tester.pumpAndSettle();
    expect(find.text('Pending (3)'), findsOneWidget);

    await tapText(tester, 'Approve');
    expect(find.text('Pending (2)'), findsOneWidget);

    await tapText(tester, 'Reject');
    expect(find.textContaining('Reject "'), findsOneWidget);
    // A reason is required.
    await tapText(tester, 'Reject job');
    expect(find.textContaining('Add a reason'), findsOneWidget);
    await tester.enterText(find.byType(TextField).last, 'Add a salary range');
    await tapText(tester, 'Reject job');
    expect(find.text('Pending (1)'), findsOneWidget);
    await tester.pump(const Duration(seconds: 4));

    await tester.tap(find.text('More').last);
    await tester.pumpAndSettle();
    await tapText(tester, 'Audit logs');
    expect(find.text('Approved job'), findsWidgets);
    expect(find.text('Add a salary range'), findsOneWidget);
  });

  testWidgets('Verify an employer and block a user', (tester) async {
    await launchAdmin(tester);
    await tester.tap(find.text('More').last);
    await tester.pumpAndSettle();
    await tapText(tester, 'Employers');
    await tapText(tester, 'Verify');
    expect(find.textContaining('is now verified'), findsOneWidget);
    await tester.pump(const Duration(seconds: 4));
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Users').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Actions for Ali Raza'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Block').last);
    await tester.pumpAndSettle();
    expect(find.text('Ali Raza: blocked'), findsOneWidget);
    await tester.pump(const Duration(seconds: 4));
  });

  group('Admin screens fit small and large phones', () {
    for (final (label, size, dpr) in const [
      ('320px', Size(320, 568), 2.0),
      ('430px', Size(430, 932), 3.0),
    ]) {
      for (final MapEntry(key: name, value: screen) in _screens.entries) {
        testWidgets('$name · $label', (tester) async {
          usePhone(tester, logical: size, dpr: dpr);
          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                initialSessionProvider.overrideWithValue(adminSession),
              ],
              child: MaterialApp(theme: AppTheme.light, home: screen),
            ),
          );
          await tester.pump(const Duration(seconds: 1));
          await tester.pumpAndSettle();
          final s = find.byType(Scrollable);
          if (isShown(s)) {
            await tester.fling(s.first, const Offset(0, -2000), 3000);
            await tester.pumpAndSettle();
          }
          expect(
            tester.takeException(),
            isNull,
            reason: '$name overflowed at $label',
          );
        });
      }
    }
  });

  group('Admin accessibility', () {
    for (final name in const [
      'overview',
      'jobs',
      'users',
      'more',
      'employers',
      'settings',
    ]) {
      testWidgets(name, (tester) async {
        final handle = tester.ensureSemantics();
        usePhone(tester);
        await tester.pumpWidget(
          ProviderScope(
            overrides: [initialSessionProvider.overrideWithValue(adminSession)],
            child: MaterialApp(theme: AppTheme.light, home: _screens[name]!),
          ),
        );
        await tester.pump(const Duration(seconds: 1));
        await tester.pumpAndSettle();
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        await expectLater(tester, meetsGuideline(textContrastGuideline));
        handle.dispose();
      });
    }
  });
}
