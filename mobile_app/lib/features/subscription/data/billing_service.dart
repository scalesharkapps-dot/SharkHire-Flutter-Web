import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../../../core/config/app_config.dart';
import '../../../core/network/api_config.dart';
import 'subscription_repository.dart';

/// A purchasable subscription package with its store-localized price
/// (e.g. "$10.00" or "Rs 499.00"); prices are never written in the app.
@immutable
class BillingPackage {
  const BillingPackage({
    required this.identifier,
    required this.productId,
    required this.priceString,
    this.title,
    this.description,
    this.period,
    this.native,
  });

  final String identifier;
  final String productId;
  final String priceString;
  final String? title;
  final String? description;

  /// ISO 8601 period, e.g. `P1M`.
  final String? period;

  /// The SDK's own package object (RevenueCat [Package]).
  final Object? native;
}

enum PurchaseOutcome { success, cancelled, pending, failed }

@immutable
class PurchaseAttempt {
  const PurchaseAttempt(this.outcome, [this.message]);
  final PurchaseOutcome outcome;
  final String? message;
}

/// Store billing. Purchases only *start* here: access is granted when the
/// backend confirms the purchase after a sync.
abstract interface class BillingService {
  /// False on web and when no store key is configured.
  bool get isAvailable;

  /// Why purchases are unavailable (null when [isAvailable]).
  String? get unavailableReason;

  /// Identifies the signed-in user (backend / Supabase user ID).
  Future<void> logIn(String appUserId);
  Future<void> logOut();
  Future<List<BillingPackage>> fetchPackages();
  Future<PurchaseAttempt> purchase(BillingPackage package);

  /// Asks the store for previous purchases. The backend restore that
  /// follows decides access.
  Future<void> restore();

  /// Store page where the user manages or cancels the subscription.
  Future<String?> managementUrl();
}

const _webReason =
    'Subscribe in the SharkHire app for Android or iOS. Your subscription '
    'then works here too.';
const _notConfiguredReason =
    'Purchases aren\'t set up in this version of the app yet.';

/// Used on web (no store) and on builds without a RevenueCat key.
class UnavailableBillingService implements BillingService {
  const UnavailableBillingService(this.unavailableReason);

  @override
  final String unavailableReason;

  @override
  bool get isAvailable => false;
  @override
  Future<void> logIn(String appUserId) async {}
  @override
  Future<void> logOut() async {}
  @override
  Future<List<BillingPackage>> fetchPackages() async => const [];
  @override
  Future<PurchaseAttempt> purchase(BillingPackage package) async =>
      PurchaseAttempt(PurchaseOutcome.failed, unavailableReason);
  @override
  Future<void> restore() async {}
  @override
  Future<String?> managementUrl() async => null;
}

/// RevenueCat (Google Play Billing on Android, StoreKit on iOS).
class RevenueCatBillingService implements BillingService {
  RevenueCatBillingService(this._apiKey);

  /// RevenueCat public SDK key for this platform.
  final String _apiKey;
  Future<void>? _configured;
  String? _pendingUserId;

  Future<void> _ensureConfigured() => _configured ??= () async {
    final config = PurchasesConfiguration(_apiKey)..appUserID = _pendingUserId;
    await Purchases.setLogLevel(kReleaseMode ? LogLevel.warn : LogLevel.debug);
    await Purchases.configure(config);
  }();

  @override
  bool get isAvailable => true;
  @override
  String? get unavailableReason => null;

  @override
  Future<void> logIn(String appUserId) async {
    if (_configured == null) {
      // Configure straight away as this user: no anonymous ID is created.
      _pendingUserId = appUserId;
      await _ensureConfigured();
      return;
    }
    await _ensureConfigured();
    await Purchases.logIn(appUserId);
  }

  @override
  Future<void> logOut() async {
    if (_configured == null) return;
    await _ensureConfigured();
    if (!await Purchases.isAnonymous) await Purchases.logOut();
  }

  @override
  Future<List<BillingPackage>> fetchPackages() async {
    await _ensureConfigured();
    final offerings = await Purchases.getOfferings();
    final offering =
        offerings.getOffering(AppConfig.offeringId) ?? offerings.current;
    return [
      for (final p in offering?.availablePackages ?? const <Package>[])
        BillingPackage(
          identifier: p.identifier,
          productId: p.storeProduct.identifier,
          priceString: p.storeProduct.priceString,
          title: p.storeProduct.title,
          description: p.storeProduct.description,
          period: p.storeProduct.subscriptionPeriod,
          native: p,
        ),
    ];
  }

  @override
  Future<PurchaseAttempt> purchase(BillingPackage package) async {
    final native = package.native;
    if (native is! Package) {
      return const PurchaseAttempt(
        PurchaseOutcome.failed,
        'This plan is not available right now.',
      );
    }
    await _ensureConfigured();
    try {
      await Purchases.purchase(PurchaseParams.package(native));
      // The store took the payment. Access still waits for the backend.
      return const PurchaseAttempt(PurchaseOutcome.success);
    } on PlatformException catch (e) {
      return purchaseAttemptFromError(PurchasesErrorHelper.getErrorCode(e));
    }
  }

  @override
  Future<void> restore() async {
    await _ensureConfigured();
    await Purchases.restorePurchases();
  }

  @override
  Future<String?> managementUrl() async {
    await _ensureConfigured();
    return (await Purchases.getCustomerInfo()).managementURL;
  }
}

/// Store error → what the user sees. Public for tests.
PurchaseAttempt purchaseAttemptFromError(PurchasesErrorCode code) =>
    switch (code) {
      PurchasesErrorCode.purchaseCancelledError => const PurchaseAttempt(
        PurchaseOutcome.cancelled,
      ),
      PurchasesErrorCode.paymentPendingError => const PurchaseAttempt(
        PurchaseOutcome.pending,
        'Your payment is pending. You\'ll get access as soon as the store '
        'confirms it.',
      ),
      // Already subscribed in the store: the sync that follows will show it.
      PurchasesErrorCode.productAlreadyPurchasedError => const PurchaseAttempt(
        PurchaseOutcome.success,
      ),
      PurchasesErrorCode.networkError => const PurchaseAttempt(
        PurchaseOutcome.failed,
        'No internet connection. You haven\'t been charged. Please try again.',
      ),
      PurchasesErrorCode.purchaseNotAllowedError => const PurchaseAttempt(
        PurchaseOutcome.failed,
        'Purchases aren\'t allowed on this device or account.',
      ),
      PurchasesErrorCode.productNotAvailableForPurchaseError =>
        const PurchaseAttempt(
          PurchaseOutcome.failed,
          'This plan is not available in your country yet.',
        ),
      _ => const PurchaseAttempt(
        PurchaseOutcome.failed,
        'The purchase didn\'t go through. You haven\'t been charged.',
      ),
    };

/// Development-only demo billing (`USE_MOCK_DATA`). Its "purchase" only
/// tells the demo backend; it never reaches a store. The price is labelled
/// as a demo so it can't be mistaken for the real one.
class DemoBillingService implements BillingService {
  DemoBillingService(this._backend);
  final MockSubscriptionRepository _backend;

  @override
  bool get isAvailable => true;
  @override
  String? get unavailableReason => null;
  @override
  Future<void> logIn(String appUserId) async {}
  @override
  Future<void> logOut() async {}

  @override
  Future<List<BillingPackage>> fetchPackages() async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return const [
      BillingPackage(
        identifier: r'$rc_monthly',
        productId: 'demo_monthly',
        priceString: r'$10.00 (demo)',
        title: 'SharkHire monthly',
        period: 'P1M',
      ),
    ];
  }

  @override
  Future<PurchaseAttempt> purchase(BillingPackage package) async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    _backend.demoPurchaseMade = true;
    return const PurchaseAttempt(PurchaseOutcome.success);
  }

  @override
  Future<void> restore() async {}
  @override
  Future<String?> managementUrl() async => null;
}

/// Picks the billing service for this build and platform.
BillingService createBillingService({
  required bool isWeb,
  required TargetPlatform platform,
  required String androidKey,
  required String iosKey,
}) {
  if (isWeb) return const UnavailableBillingService(_webReason);
  final key = switch (platform) {
    TargetPlatform.android => androidKey,
    TargetPlatform.iOS => iosKey,
    _ => '',
  };
  if (key.isEmpty || AppConfig.isRevenueCatSecretKey(key)) {
    return const UnavailableBillingService(_notConfiguredReason);
  }
  return RevenueCatBillingService(key);
}

final billingServiceProvider = Provider<BillingService>((ref) {
  if (!ApiConfig.isConfigured) {
    final backend = ref.watch(subscriptionRepositoryProvider);
    if (backend is MockSubscriptionRepository) {
      return DemoBillingService(backend);
    }
  }
  return createBillingService(
    isWeb: kIsWeb,
    platform: defaultTargetPlatform,
    androidKey: AppConfig.revenueCatAndroidKey,
    iosKey: AppConfig.revenueCatIosKey,
  );
});
