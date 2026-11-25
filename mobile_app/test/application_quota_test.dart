import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sharkhire/core/theme/app_theme.dart';
import 'package:sharkhire/features/subscription/presentation/widgets/application_quota_widgets.dart';
import 'package:sharkhire/features/subscription/presentation/providers/application_quota.dart';

void main() {
  test('5 applications per plan, counted down to zero', () {
    const fresh = ApplicationQuota(used: 0, isPremium: false);
    expect(fresh.limit, 5);
    expect(fresh.left, 5);
    expect(fresh.isUsedUp, isFalse);

    const three = ApplicationQuota(used: 3, isPremium: true);
    expect(three.left, 2);
    expect(three.isUsedUp, isFalse);

    const done = ApplicationQuota(used: 5, isPremium: false);
    expect(done.left, 0);
    expect(done.isUsedUp, isTrue);

    // More applications than the limit never shows a negative count.
    const over = ApplicationQuota(used: 7, isPremium: true);
    expect(over.left, 0);
    expect(over.isUsedUp, isTrue);
  });

  Future<void> openSheet(WidgetTester tester, ApplicationQuota quota) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showQuotaUsedUpSheet(
                  context,
                  quota: quota,
                  jobId: 'job-01',
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
  }

  testWidgets('trial used up offers Premium', (tester) async {
    await openSheet(tester, const ApplicationQuota(used: 5, isPremium: false));
    expect(find.text("You've used your 5 trial applications"), findsOneWidget);
    expect(find.text('See Premium'), findsOneWidget);
    expect(find.text('Save this job for later'), findsOneWidget);
  });

  testWidgets('Premium used up offers buying again', (tester) async {
    await openSheet(tester, const ApplicationQuota(used: 5, isPremium: true));
    expect(
      find.text("You've used your 5 Premium applications"),
      findsOneWidget,
    );
    expect(find.text('Buy Premium again'), findsOneWidget);
  });

  testWidgets('counter reads how many are left', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(
          body: QuotaLine(quota: ApplicationQuota(used: 2, isPremium: false)),
        ),
      ),
    );
    expect(find.textContaining('3 of 5'), findsOneWidget);
    expect(find.textContaining('trial applications left'), findsOneWidget);
  });
}
