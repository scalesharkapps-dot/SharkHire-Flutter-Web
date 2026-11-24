import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sharkhire/features/notifications/presentation/screens/job_alerts_screen.dart';
import 'package:sharkhire/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:sharkhire/features/profile/presentation/screens/edit_profile_screen.dart';
import 'package:sharkhire/features/settings/presentation/screens/settings_screens.dart';
import 'package:sharkhire/features/subscription/presentation/screens/subscription_screen.dart';

import 'helpers.dart';

final _unreadDots = find.byWidgetPredicate(
  (w) => w is Semantics && w.properties.label == 'Unread',
);

Future<void> tapText(WidgetTester tester, String label) async {
  final f = find.text(label).last;
  await tester.ensureVisible(f);
  await tester.pumpAndSettle();
  await tester.tap(f);
  await tester.pump();
}

Future<void> openProfileItem(WidgetTester tester, String label) async {
  await tester.tap(find.text('Profile').last);
  await tester.pumpAndSettle();
  await scrollTo(tester, find.text(label));
  await tapText(tester, label);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Notifications: open one, mark all read, swipe to remove', (
    tester,
  ) async {
    usePhone(tester);
    await launchToSeekerHome(tester);

    await tester.tap(find.byTooltip('Notifications'));
    await tester.pumpAndSettle();
    expect(find.text('3 new jobs match your CV'), findsOneWidget);
    expect(_unreadDots, findsNWidgets(2));

    await tapText(tester, 'Mark all as read');
    await tester.pumpAndSettle();
    expect(_unreadDots, findsNothing);
    expect(find.text('Mark all as read'), findsNothing);

    await tester.drag(
      find.text('A saved job closes soon'),
      const Offset(-500, 0),
    );
    await tester.pumpAndSettle();
    expect(find.text('A saved job closes soon'), findsNothing);
    await tapText(tester, 'Undo');
    await tester.pumpAndSettle();
    expect(find.text('A saved job closes soon'), findsOneWidget);

    await tapText(tester, 'You\'re shortlisted');
    await tester.pumpAndSettle();
    expect(find.text('Junior FastAPI Developer'), findsOneWidget);
  });

  testWidgets('Create a job alert', (tester) async {
    usePhone(tester);
    await launchToSeekerHome(tester);
    await openProfileItem(tester, 'Job alerts');
    expect(find.text('Flutter jobs'), findsOneWidget);

    await tapText(tester, 'New alert');
    await tester.pumpAndSettle();
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Data roles');
    await tester.enterText(fields.at(1), 'Data analyst');
    await tapText(tester, 'Create alert');
    await tester.pumpAndSettle();
    expect(find.text('Data roles'), findsOneWidget);
  });

  testWidgets('Subscription: demo trial, restore and subscribe', (
    tester,
  ) async {
    usePhone(tester);
    await launchToSeekerHome(tester);
    await openProfileItem(tester, 'Subscription');

    // Status and price come from the (demo) backend and store.
    await pumpUntil(tester, () => isShown(find.textContaining('Free trial')));
    await pumpUntil(
      tester,
      () => isShown(
        find.textContaining(r'$10.00 (demo) / month', findRichText: true),
      ),
    );

    await scrollTo(tester, find.text('Restore purchases'));
    await tapText(tester, 'Restore purchases');
    await pumpUntil(
      tester,
      () => isShown(find.textContaining('No active subscription was found')),
    );

    await tapText(tester, r'Subscribe for $10.00 (demo) / month');
    await pumpUntil(tester, () => isShown(find.text('Manage subscription')));
    expect(find.textContaining('Subscribe for'), findsNothing);
  });

  testWidgets('Edit profile updates the name everywhere', (tester) async {
    usePhone(tester);
    await launchToSeekerHome(tester);
    await tester.tap(find.text('Profile').last);
    await tester.pumpAndSettle();
    await tapText(tester, 'Ayesha Khan');
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'Ayesha Malik');
    await tapText(tester, 'Save changes');
    await pumpUntil(tester, () => isShown(find.text('Ayesha Malik')));
    await tester.pump(const Duration(seconds: 4)); // let the snackbar finish
  });

  group('Account screens fit a 320px phone', () {
    testWidgets(
      'notifications',
      (t) => expectNoOverflowOnSmallPhone(t, const NotificationsScreen()),
    );
    testWidgets(
      'job alerts',
      (t) => expectNoOverflowOnSmallPhone(t, const JobAlertsScreen()),
    );
    testWidgets(
      'subscription',
      (t) => expectNoOverflowOnSmallPhone(t, const SubscriptionScreen()),
    );
    testWidgets(
      'settings',
      (t) => expectNoOverflowOnSmallPhone(t, const SettingsScreen()),
    );
    testWidgets(
      'privacy',
      (t) => expectNoOverflowOnSmallPhone(t, const PrivacyScreen()),
    );
    testWidgets(
      'help',
      (t) => expectNoOverflowOnSmallPhone(t, const HelpScreen()),
    );
    testWidgets(
      'edit profile',
      (t) => expectNoOverflowOnSmallPhone(t, const EditProfileScreen()),
    );
  });
}
