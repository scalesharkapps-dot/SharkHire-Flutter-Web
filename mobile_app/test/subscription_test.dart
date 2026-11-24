// Subscription & app access. RevenueCat and the backend are both mocked:
// these tests check the app only grants access on the backend's word.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:material_ui/material_ui.dart';
import 'package:purchases_flutter/purchases_flutter.dart'
    show PurchasesErrorCode;
import 'package:sharkhire/core/config/app_config.dart';
import 'package:sharkhire/core/network/api_exception.dart';
import 'package:sharkhire/core/network/auth_token_provider.dart';
import 'package:sharkhire/core/network/http_api_client.dart';
import 'package:sharkhire/core/routing/app_routes.dart';
import 'package:sharkhire/core/routing/route_guard.dart';
import 'package:sharkhire/core/theme/app_theme.dart';
import 'package:sharkhire/features/authentication/domain/session.dart';
import 'package:sharkhire/features/authentication/presentation/providers/session_provider.dart';
import 'package:sharkhire/features/subscription/data/billing_service.dart';
import 'package:sharkhire/features/subscription/data/subscription_json.dart';
import 'package:sharkhire/features/subscription/data/subscription_repository.dart';
import 'package:sharkhire/features/subscription/domain/subscription_status.dart';
import 'package:sharkhire/features/subscription/presentation/providers/subscription_providers.dart';
import 'package:sharkhire/features/subscription/presentation/screens/subscription_screen.dart';
import 'package:sharkhire/features/subscription/presentation/widgets/subscription_widgets.dart';
import 'package:sharkhire/shared/models/app_user.dart';
import 'package:sharkhire/shared/models/domain_enums.dart';

import 'helpers.dart';

const _seeker = Session(
  user: AppUser(id: 'user-123', fullName: 'Sara Malik', email: 's@x.test'),
  emailVerified: true,
  onboardingComplete: true,
);

const _trial = SubscriptionStatus(state: AccessState.trialActive);
const _due = SubscriptionStatus(state: AccessState.paymentRequired);
const _active = SubscriptionStatus(state: AccessState.subscriptionActive);

class _FakeBackend implements SubscriptionRepository {
  _FakeBackend(this.status, {this.afterSync, this.afterRestore});

  SubscriptionStatus status;
  SubscriptionStatus? afterSync;
  SubscriptionStatus? afterRestore;
  Object? error;
  final calls = <String>[];

  @override
  Future<SubscriptionStatus> fetchStatus() async {
    calls.add('status');
    if (error != null) throw error!;
    return status;
  }

  @override
  Future<SubscriptionStatus> sync({required String trigger}) async {
    calls.add('sync:$trigger');
    return afterSync ?? status;
  }

  @override
  Future<SubscriptionStatus> restore() async {
    calls.add('restore');
    return afterRestore ?? status;
  }

  @override
  Future<List<SubscriptionHistoryEntry>> fetchHistory() async => const [];

  @override
  Future<List<SubscriptionPlan>> fetchPlans() async => const [];
}

const _package = BillingPackage(
  identifier: r'$rc_monthly',
  productId: 'sharkhire_monthly',
  priceString: 'Rs 499.00',
);

class _FakeBilling implements BillingService {
  _FakeBilling({this.available = true, this.next = PurchaseOutcome.success});

  final bool available;
  PurchaseOutcome next;
  final calls = <String>[];

  @override
  bool get isAvailable => available;
  @override
  String? get unavailableReason => available ? null : 'Use the mobile app.';
  @override
  Future<void> logIn(String appUserId) async => calls.add('logIn:$appUserId');
  @override
  Future<void> logOut() async => calls.add('logOut');
  @override
  Future<List<BillingPackage>> fetchPackages() async =>
      available ? const [_package] : const [];
  @override
  Future<PurchaseAttempt> purchase(BillingPackage package) async {
    calls.add('purchase:${package.productId}');
    return PurchaseAttempt(next, next == PurchaseOutcome.success ? null : 'x');
  }

  @override
  Future<void> restore() async => calls.add('restore');
  @override
  Future<String?> managementUrl() async => null;
}

ProviderContainer _container(
  _FakeBackend backend,
  _FakeBilling billing, {
  Session session = _seeker,
  bool enabled = true,
}) {
  final c = ProviderContainer(
    overrides: [
      initialSessionProvider.overrideWithValue(session),
      subscriptionsEnabledProvider.overrideWithValue(enabled),
      subscriptionRepositoryProvider.overrideWithValue(backend),
      billingServiceProvider.overrideWithValue(billing),
    ],
  );
  addTearDown(c.dispose);
  // Keep the controller alive, as the app's router does.
  c.listen(subscriptionProvider, (_, _) {});
  return c;
}

Future<void> _settle() async {
  for (var i = 0; i < 5; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  group('Status mapping (proposed backend shape)', () {
    test('every documented status maps to its state', () {
      const map = {
        'trial_active': AccessState.trialActive,
        'subscription_active': AccessState.subscriptionActive,
        'payment_required': AccessState.paymentRequired,
        'subscription_expired': AccessState.subscriptionExpired,
        'subscription_cancelled_but_active':
            AccessState.subscriptionCancelledButActive,
        'billing_issue': AccessState.billingIssue,
      };
      map.forEach((raw, state) {
        expect(subscriptionStatusFromJson({'status': raw}).state, state);
      });
    });

    test('unknown or missing status fails closed', () {
      for (final json in [
        null,
        'x',
        <String, Object?>{},
        {'status': 'premium_forever'},
      ]) {
        final s = subscriptionStatusFromJson(json);
        expect(s.state, AccessState.error);
        expect(s.hasAccess, isFalse);
      }
    });

    test('backend has_access always wins; dates are read', () {
      final s = subscriptionStatusFromJson({
        'status': 'trial_active',
        'has_access': false,
        'trial_ends_at': '2026-11-23T10:00:00Z',
      });
      expect(s.hasAccess, isFalse);
      expect(s.trialEndsAt, DateTime.utc(2026, 11, 23, 10));
    });

    test('access rules: loading and errors never grant access', () {
      expect(SubscriptionStatus.loading.hasAccess, isFalse);
      expect(SubscriptionStatus.failure('x').hasAccess, isFalse);
      expect(_trial.hasAccess, isTrue);
      expect(_due.hasAccess, isFalse);
      expect(
        const SubscriptionStatus(
          state: AccessState.subscriptionExpired,
        ).hasAccess,
        isFalse,
      );
      // Billing issue: only during the store's grace period.
      expect(
        SubscriptionStatus(
          state: AccessState.billingIssue,
          currentPeriodEndsAt: DateTime.now().add(const Duration(days: 2)),
        ).hasAccess,
        isTrue,
      );
      expect(
        const SubscriptionStatus(state: AccessState.billingIssue).hasAccess,
        isFalse,
      );
    });

    test('trial days left come from the backend end date', () {
      final now = DateTime(2026, 11, 20, 12);
      final s = SubscriptionStatus(
        state: AccessState.trialActive,
        trialEndsAt: now.add(const Duration(days: 2, hours: 3)),
      );
      expect(s.trialDaysLeft(now), 3);
      expect(s.trialDaysLeft(now.add(const Duration(days: 3))), 0);
    });

    test('history and plans lists', () {
      final h = subscriptionHistoryFromJson({
        'items': [
          {'id': 'a', 'event': 'renewal', 'price': 'Rs 499.00'},
        ],
      });
      expect(h.single.event, 'renewal');
      expect(h.single.price, 'Rs 499.00');
      expect(
        subscriptionPlansFromJson([
          {'id': 'monthly', 'product_id': 'sharkhire_monthly'},
        ]).single.productId,
        'sharkhire_monthly',
      );
    });
  });

  group('Backend API', () {
    ApiSubscriptionRepository repo(int code, String body) =>
        ApiSubscriptionRepository(
          HttpApiClient(
            baseUrl: 'https://api.example.test',
            tokens: const NoTokenProvider(),
            client: MockClient((_) async => http.Response(body, code)),
          ),
        );

    test('404 (endpoint not deployed) is an integration dependency', () {
      expect(
        repo(
          404,
          '{"success":false,"message":"Not Found","data":null,"error":{"code":"not_found","message":"Not Found"}}',
        ).fetchStatus(),
        throwsA(isA<FeatureUnavailableException>()),
      );
    });

    test('status envelope is unwrapped and mapped', () async {
      final s = await repo(
        200,
        '{"success":true,"message":"ok","data":{"status":"subscription_active","will_renew":true},"error":null}',
      ).fetchStatus();
      expect(s.state, AccessState.subscriptionActive);
      expect(s.willRenew, isTrue);
    });
  });

  group('Billing service selection', () {
    BillingService pick({
      bool web = false,
      TargetPlatform p = TargetPlatform.android,
      String android = '',
      String ios = '',
    }) => createBillingService(
      isWeb: web,
      platform: p,
      androidKey: android,
      iosKey: ios,
    );

    test('web never uses RevenueCat', () {
      expect(pick(web: true, android: 'goog_x').isAvailable, isFalse);
    });
    test('missing or secret keys disable purchases', () {
      expect(pick().isAvailable, isFalse);
      expect(pick(android: 'sk_secret').isAvailable, isFalse);
    });
    test('public platform key enables RevenueCat', () {
      expect(pick(android: 'goog_abc'), isA<RevenueCatBillingService>());
      expect(
        pick(p: TargetPlatform.iOS, ios: 'appl_abc'),
        isA<RevenueCatBillingService>(),
      );
    });
    test('production config refuses a secret RevenueCat key', () {
      expect(
        AppConfig.checkProductionConfig(
          useMockData: false,
          apiBaseUrl: 'https://api.example.com',
          revenueCatKeys: ['sk_live_123'],
        ),
        contains('secret key'),
      );
    });
    test('store errors map to purchase outcomes', () {
      expect(
        purchaseAttemptFromError(
          PurchasesErrorCode.purchaseCancelledError,
        ).outcome,
        PurchaseOutcome.cancelled,
      );
      expect(
        purchaseAttemptFromError(
          PurchasesErrorCode.paymentPendingError,
        ).outcome,
        PurchaseOutcome.pending,
      );
      expect(
        purchaseAttemptFromError(PurchasesErrorCode.storeProblemError).outcome,
        PurchaseOutcome.failed,
      );
    });
  });

  group('Subscription controller', () {
    test(
      'sign-in loads status and logs RevenueCat in with the user ID',
      () async {
        final backend = _FakeBackend(_trial);
        final billing = _FakeBilling();
        final c = _container(backend, billing);
        expect(c.read(subscriptionProvider).isLoading, isTrue);
        await _settle();
        expect(c.read(subscriptionProvider).state, AccessState.trialActive);
        expect(billing.calls, ['logIn:user-123']);
        expect(backend.calls, ['status']);
      },
    );

    test('sign-out logs RevenueCat out', () async {
      final billing = _FakeBilling();
      final c = _container(_FakeBackend(_trial), billing);
      await _settle();
      await c.read(sessionProvider.notifier).signOut();
      c.read(subscriptionProvider);
      await _settle();
      expect(billing.calls, ['logIn:user-123', 'logOut']);
    });

    test('employers are not subscribers', () async {
      final backend = _FakeBackend(_due);
      final c = _container(
        backend,
        _FakeBilling(),
        session: const Session(
          user: AppUser(
            id: 'e1',
            fullName: 'Bilal',
            email: 'e@x.test',
            roles: {AppRole.employer},
          ),
          emailVerified: true,
          onboardingComplete: true,
        ),
      );
      c.read(subscriptionProvider);
      await _settle();
      expect(backend.calls, isEmpty);
    });

    test('purchase success is verified by the backend before access', () async {
      final backend = _FakeBackend(_due, afterSync: _active);
      final billing = _FakeBilling();
      final c = _container(backend, billing);
      await _settle();
      final r = await c.read(subscriptionProvider.notifier).purchase(_package);
      expect(billing.calls.last, 'purchase:sharkhire_monthly');
      expect(backend.calls.last, 'sync:purchase');
      expect(c.read(subscriptionProvider).hasAccess, isTrue);
      expect(r.message, contains('subscribed'));
    });

    test('store success but backend not confirmed: no access yet', () async {
      final backend = _FakeBackend(_due); // sync still says payment_required
      final c = _container(backend, _FakeBilling());
      await _settle();
      final r = await c.read(subscriptionProvider.notifier).purchase(_package);
      expect(c.read(subscriptionProvider).hasAccess, isFalse);
      expect(r.message, confirmingPurchaseMessage);
    });

    for (final outcome in [
      PurchaseOutcome.cancelled,
      PurchaseOutcome.pending,
      PurchaseOutcome.failed,
    ]) {
      test('purchase $outcome does not sync or grant access', () async {
        final backend = _FakeBackend(_due, afterSync: _active);
        final c = _container(backend, _FakeBilling(next: outcome));
        await _settle();
        final r = await c
            .read(subscriptionProvider.notifier)
            .purchase(_package);
        expect(backend.calls, ['status']);
        expect(c.read(subscriptionProvider).hasAccess, isFalse);
        expect(r.message == null, outcome == PurchaseOutcome.cancelled);
        expect(r.isError, outcome == PurchaseOutcome.failed);
      });
    }

    test('restore asks the store, then the backend decides', () async {
      final backend = _FakeBackend(_due, afterRestore: _active);
      final billing = _FakeBilling();
      final c = _container(backend, billing);
      await _settle();
      final r = await c.read(subscriptionProvider.notifier).restore();
      expect(billing.calls.last, 'restore');
      expect(backend.calls.last, 'restore');
      expect(r.message, contains('restored'));
      expect(c.read(subscriptionProvider).hasAccess, isTrue);
    });

    test('restore with nothing to restore', () async {
      final c = _container(_FakeBackend(_due), _FakeBilling());
      await _settle();
      final r = await c.read(subscriptionProvider.notifier).restore();
      expect(r.message, contains('No active subscription'));
    });

    test('missing backend endpoint becomes a clear error state', () async {
      final backend = _FakeBackend(_trial)
        ..error = const FeatureUnavailableException(
          subscriptionServiceUnavailableMessage,
        );
      final c = _container(backend, _FakeBilling());
      await _settle();
      final s = c.read(subscriptionProvider);
      expect(s.state, AccessState.error);
      expect(s.serviceUnavailable, isTrue);
      expect(s.hasAccess, isFalse);
    });

    test('network error, then retry succeeds', () async {
      final backend = _FakeBackend(_trial)..error = const NetworkException();
      final c = _container(backend, _FakeBilling());
      await _settle();
      expect(c.read(subscriptionProvider).state, AccessState.error);
      backend.error = null;
      await c.read(subscriptionProvider.notifier).refresh();
      expect(c.read(subscriptionProvider).state, AccessState.trialActive);
    });

    test('no automatic calls while subscriptions are disabled', () async {
      final backend = _FakeBackend(_trial);
      final c = _container(backend, _FakeBilling(), enabled: false);
      c.read(subscriptionProvider);
      await _settle();
      expect(backend.calls, isEmpty);
    });
  });

  group('Access guard', () {
    String? guard(SubscriptionStatus? s, String loc, {Session? session}) =>
        routeGuard(session ?? _seeker, loc, subscription: s);

    test('disabled: no paywall', () {
      expect(guard(null, AppRoutes.home), isNull);
    });
    test('trial and paid users pass', () {
      expect(guard(_trial, AppRoutes.home), isNull);
      expect(guard(_active, '/jobs/42'), isNull);
    });
    test(
      'no access (or not known yet) goes to the paywall, keeping the link',
      () {
        expect(guard(_due, '/jobs/42'), '/subscription?next=%2Fjobs%2F42');
        expect(
          guard(SubscriptionStatus.loading, AppRoutes.home),
          AppRoutes.paywall(next: AppRoutes.home),
        );
        expect(
          guard(SubscriptionStatus.failure('x'), AppRoutes.saved),
          startsWith(AppRoutes.subscription),
        );
      },
    );
    test('account, support and legal routes stay open', () {
      for (final r in AppRoutes.subscriptionFreeRoutes) {
        expect(guard(_due, r), isNull, reason: r);
      }
    });
    test('employers are never gated', () {
      expect(
        guard(_due, AppRoutes.employerOverview, session: employerSession),
        isNull,
      );
    });
    test('next must be an in-app path', () {
      expect(AppRoutes.safeNext('/jobs/1'), '/jobs/1');
      expect(AppRoutes.safeNext('//evil.example'), isNull);
      expect(AppRoutes.safeNext('https://evil.example'), isNull);
    });
  });

  group('Screens', () {
    Future<void> pump(
      WidgetTester tester,
      Widget child, {
      required _FakeBackend backend,
      required _FakeBilling billing,
    }) async {
      usePhone(tester);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            initialSessionProvider.overrideWithValue(_seeker),
            subscriptionsEnabledProvider.overrideWithValue(true),
            subscriptionRepositoryProvider.overrideWithValue(backend),
            billingServiceProvider.overrideWithValue(billing),
          ],
          child: MaterialApp(theme: AppTheme.light, home: child),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('paywall shows the store price, not a hard-coded one', (
      tester,
    ) async {
      await pump(
        tester,
        const SubscriptionScreen(),
        backend: _FakeBackend(_due),
        billing: _FakeBilling(),
      );
      expect(find.text('Your free trial has ended'), findsOneWidget);
      expect(
        find.textContaining('Rs 499.00 / month', findRichText: true),
        findsWidgets,
      );
      expect(find.text('Subscribe for Rs 499.00 / month'), findsOneWidget);
    });

    testWidgets('web: no purchase button, explains where to subscribe', (
      tester,
    ) async {
      await pump(
        tester,
        const SubscriptionScreen(),
        backend: _FakeBackend(_due),
        billing: _FakeBilling(available: false),
      );
      expect(find.textContaining('Subscribe for'), findsNothing);
      expect(find.text('Use the mobile app.'), findsOneWidget);
      await scrollTo(tester, find.text('Restore purchases'));
      expect(find.text('Restore purchases'), findsOneWidget);
    });

    testWidgets('backend endpoint missing: clear message, no purchase', (
      tester,
    ) async {
      await pump(
        tester,
        const SubscriptionScreen(),
        backend: _FakeBackend(_trial)
          ..error = const FeatureUnavailableException(
            subscriptionServiceUnavailableMessage,
          ),
        billing: _FakeBilling(),
      );
      expect(find.text(subscriptionServiceUnavailableMessage), findsOneWidget);
      expect(find.textContaining('Subscribe for'), findsNothing);
    });

    testWidgets('trial banner counts days from the backend', (tester) async {
      await pump(
        tester,
        const Scaffold(body: TrialBanner()),
        backend: _FakeBackend(
          SubscriptionStatus(
            state: AccessState.trialActive,
            trialEndsAt: DateTime.now().add(const Duration(days: 1, hours: 5)),
          ),
        ),
        billing: _FakeBilling(),
      );
      expect(find.textContaining('2 days left'), findsOneWidget);
    });

    testWidgets('paywall fits a small phone', (tester) async {
      await expectNoOverflowOnSmallPhone(
        tester,
        const SubscriptionScreen(),
        session: _seeker,
        overrides: [
          subscriptionsEnabledProvider.overrideWithValue(true),
          subscriptionRepositoryProvider.overrideWithValue(_FakeBackend(_due)),
          billingServiceProvider.overrideWithValue(_FakeBilling()),
        ],
      );
    });
  });

  testWidgets('gated user subscribes and returns to where they were going', (
    tester,
  ) async {
    usePhone(tester);
    final backend = _FakeBackend(_due, afterSync: _active);
    await launchApp(
      tester,
      session: _seeker,
      overrides: [
        subscriptionsEnabledProvider.overrideWithValue(true),
        subscriptionRepositoryProvider.overrideWithValue(backend),
        billingServiceProvider.overrideWithValue(_FakeBilling()),
      ],
    );
    await pumpUntil(
      tester,
      () => isShown(find.text('Subscribe for Rs 499.00 / month')),
    );
    await tester.tap(find.text('Subscribe for Rs 499.00 / month'));
    await pumpUntil(
      tester,
      () =>
          isShown(find.text('Explore')) &&
          !isShown(find.text('Restore purchases')),
    );
    expect(backend.calls, contains('sync:purchase'));
    await tester.pumpAndSettle();
  });
}
