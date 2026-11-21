// Captures the Subscription screens in their main states (documentation
// tool, not part of `flutter test`). Run:
//   flutter test tool/showcase/capture_subscription_states_test.dart
//   (add --dart-define=DARK=true for the dark theme)
// Output: ../frontend_showcase/screenshots/09_subscription/*.png
//
// RevenueCat and the backend are faked here: the prices and statuses are
// illustrations of what the app shows, not real store data.

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sharkhire/core/network/api_exception.dart';
import 'package:sharkhire/core/theme/app_theme.dart';
import 'package:sharkhire/features/authentication/domain/session.dart';
import 'package:sharkhire/features/authentication/presentation/providers/session_provider.dart';
import 'package:sharkhire/features/subscription/data/billing_service.dart';
import 'package:sharkhire/features/subscription/data/subscription_repository.dart';
import 'package:sharkhire/features/subscription/domain/subscription_status.dart';
import 'package:sharkhire/features/subscription/presentation/providers/subscription_providers.dart';
import 'package:sharkhire/features/subscription/presentation/screens/subscription_history_screen.dart';
import 'package:sharkhire/features/subscription/presentation/screens/subscription_screen.dart';
import 'package:sharkhire/shared/models/app_user.dart';

const _dark = bool.fromEnvironment('DARK');
const _out = _dark
    ? '../frontend_showcase/screenshots/10_dark_theme/subscription'
    : '../frontend_showcase/screenshots/09_subscription';
final _frame = GlobalKey();

class _Backend implements SubscriptionRepository {
  _Backend(this.status, {this.history = const []});
  final Object status;
  final List<SubscriptionHistoryEntry> history;

  @override
  Future<SubscriptionStatus> fetchStatus() async {
    final s = status;
    if (s is SubscriptionStatus) return s;
    throw s;
  }

  @override
  Future<SubscriptionStatus> sync({required String trigger}) => fetchStatus();
  @override
  Future<SubscriptionStatus> restore() => fetchStatus();
  @override
  Future<List<SubscriptionHistoryEntry>> fetchHistory() async => history;
  @override
  Future<List<SubscriptionPlan>> fetchPlans() async => const [];
}

class _Store implements BillingService {
  const _Store({this.available = true});
  final bool available;

  @override
  bool get isAvailable => available;
  @override
  String? get unavailableReason => available
      ? null
      : 'Subscribe in the SharkHire app for Android or iOS. Your '
            'subscription then works here too.';
  @override
  Future<void> logIn(String appUserId) async {}
  @override
  Future<void> logOut() async {}
  @override
  Future<List<BillingPackage>> fetchPackages() async => available
      ? const [
          BillingPackage(
            identifier: r'$rc_monthly',
            productId: 'sharkhire_monthly',
            priceString: 'Rs 499.00',
          ),
        ]
      : const [];
  @override
  Future<PurchaseAttempt> purchase(BillingPackage package) async =>
      const PurchaseAttempt(PurchaseOutcome.cancelled);
  @override
  Future<void> restore() async {}
  @override
  Future<String?> managementUrl() async => null;
}

Future<void> _loadFonts() async {
  Future<ByteData> a(String p) => rootBundle.load('assets/fonts/$p');
  final icons = File(
    'C:/src/flutter/bin/cache/artifacts/material_fonts/materialicons-regular.otf',
  );
  await Future.wait([
    (FontLoader('ArchivoBlack')..addFont(a('ArchivoBlack-Regular.ttf'))).load(),
    (FontLoader('Archivo')
          ..addFont(a('Archivo-Medium.ttf'))
          ..addFont(a('Archivo-SemiBold.ttf'))
          ..addFont(a('Archivo-Bold.ttf')))
        .load(),
    (FontLoader('Hind')
          ..addFont(a('Hind-Regular.ttf'))
          ..addFont(a('Hind-Medium.ttf'))
          ..addFont(a('Hind-SemiBold.ttf'))
          ..addFont(a('Hind-Bold.ttf')))
        .load(),
    (FontLoader(
          'MaterialIcons',
        )..addFont(Future.value(ByteData.sublistView(icons.readAsBytesSync()))))
        .load(),
  ]);
}

Future<void> _shoot(
  WidgetTester tester,
  String name,
  Widget screen,
  SubscriptionRepository backend,
  BillingService store, {
  double height = 844,
}) async {
  tester.view.physicalSize = Size(390, height) * 3;
  tester.view.devicePixelRatio = 3;
  tester.view.padding = const FakeViewPadding(top: 47 * 3, bottom: 34 * 3);
  tester.view.viewPadding = const FakeViewPadding(top: 47 * 3, bottom: 34 * 3);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    RepaintBoundary(
      key: _frame,
      child: ProviderScope(
        overrides: [
          initialSessionProvider.overrideWithValue(
            const Session(
              user: AppUser(
                id: 'demo-user',
                fullName: 'Sara Malik',
                email: 'sara.malik@example.com',
              ),
              emailVerified: true,
              onboardingComplete: true,
            ),
          ),
          subscriptionsEnabledProvider.overrideWithValue(true),
          subscriptionRepositoryProvider.overrideWithValue(backend),
          billingServiceProvider.overrideWithValue(store),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.build(dark: _dark),
          home: screen,
        ),
      ),
    ),
  );
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  final boundary =
      _frame.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  final bytes = await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 2);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    return data!.buffer.asUint8List();
  });
  File('$_out/$name.png')
    ..createSync(recursive: true)
    ..writeAsBytesSync(bytes!);
}

void main() {
  setUpAll(_loadFonts);
  const tall = 990.0;

  testWidgets('trial active', (t) async {
    await _shoot(
      t,
      '01_paywall_trial_active',
      const SubscriptionScreen(),
      _Backend(
        SubscriptionStatus(
          state: AccessState.trialActive,
          trialEndsAt: DateTime.now().add(const Duration(days: 2, hours: 5)),
        ),
      ),
      const _Store(),
      height: tall,
    );
  });

  testWidgets('trial ended', (t) async {
    await _shoot(
      t,
      '02_paywall_trial_ended',
      const SubscriptionScreen(),
      _Backend(const SubscriptionStatus(state: AccessState.paymentRequired)),
      const _Store(),
      height: tall,
    );
  });

  testWidgets('subscription active', (t) async {
    await _shoot(
      t,
      '03_subscription_active',
      const SubscriptionScreen(),
      _Backend(
        SubscriptionStatus(
          state: AccessState.subscriptionActive,
          currentPeriodEndsAt: DateTime.now().add(const Duration(days: 30)),
          willRenew: true,
        ),
      ),
      const _Store(),
      height: tall,
    );
  });

  testWidgets('payment problem', (t) async {
    await _shoot(
      t,
      '04_payment_problem',
      const SubscriptionScreen(),
      _Backend(
        SubscriptionStatus(
          state: AccessState.billingIssue,
          currentPeriodEndsAt: DateTime.now().add(const Duration(days: 3)),
        ),
      ),
      const _Store(),
      height: tall,
    );
  });

  testWidgets('website today: backend API not ready', (t) async {
    await _shoot(
      t,
      '05_website_today_backend_not_ready',
      const SubscriptionScreen(),
      _Backend(
        const FeatureUnavailableException(
          subscriptionServiceUnavailableMessage,
        ),
      ),
      const _Store(available: false),
      height: tall,
    );
  });

  testWidgets('billing history', (t) async {
    final now = DateTime.now();
    await _shoot(
      t,
      '06_billing_history',
      const SubscriptionHistoryScreen(),
      _Backend(
        const SubscriptionStatus(state: AccessState.subscriptionActive),
        history: [
          SubscriptionHistoryEntry(
            id: '3',
            event: 'renewal',
            store: 'play_store',
            price: 'Rs 499.00',
            occurredAt: now,
            expiresAt: now.add(const Duration(days: 30)),
          ),
          SubscriptionHistoryEntry(
            id: '2',
            event: 'initial_purchase',
            store: 'play_store',
            price: 'Rs 499.00',
            occurredAt: now.subtract(const Duration(days: 30)),
            expiresAt: now,
          ),
          SubscriptionHistoryEntry(
            id: '1',
            event: 'trial_started',
            occurredAt: now.subtract(const Duration(days: 33)),
            expiresAt: now.subtract(const Duration(days: 30)),
          ),
        ],
      ),
      const _Store(),
    );
  });
}
