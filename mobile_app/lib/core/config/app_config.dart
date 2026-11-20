import 'package:flutter/foundation.dart' show kIsWeb;

/// Build-time environment configuration.
///
/// Every value comes from `--dart-define` (or `--dart-define-from-file`),
/// so no server address is written in the source code. The app needs no
/// Supabase keys: the SharkHire API handles sign-in and issues the tokens. Example files
/// live in `mobile_app/config/` (`*.example.json`); the real ones are
/// git-ignored.
///
/// ```bash
/// flutter run   --dart-define-from-file=config/development.json
/// flutter build appbundle --release --dart-define-from-file=config/production.json
/// ```
enum AppEnvironment { development, staging, production }

abstract final class AppConfig {
  static const String _env = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'development',
  );

  static AppEnvironment get environment => switch (_env) {
    'production' => AppEnvironment.production,
    'staging' => AppEnvironment.staging,
    _ => AppEnvironment.development,
  };

  static bool get isProduction => environment == AppEnvironment.production;

  /// Sample data instead of the real backend. On by default for development
  /// so the app runs without a server; OFF by default for production, so a
  /// store build never shows demo accounts or sample jobs.
  static const bool useMockData = bool.fromEnvironment(
    'USE_MOCK_DATA',
    defaultValue: _env != 'production',
  );

  /// Base URL of the SharkHire API (FastAPI), e.g. `https://api.example.com`.
  ///
  /// Web only: [sameOrigin] means "the site's own address". The web host
  /// (Render) forwards `/api/*` to the backend, so the browser never makes a
  /// cross-site request and no CORS setup is needed.
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  static const String sameOrigin = 'same-origin';

  /// [apiBaseUrl] with [sameOrigin] resolved to the page's origin on web.
  static String get resolvedApiBaseUrl =>
      apiBaseUrl == sameOrigin ? (kIsWeb ? Uri.base.origin : '') : apiBaseUrl;

  /// Paid app access (RevenueCat + backend subscription API).
  ///
  /// OFF by default: while it is off nobody is sent to the paywall. Turn it
  /// on (`--dart-define=SUBSCRIPTIONS_ENABLED=true`) only once the backend's
  /// `/api/v1/subscriptions/*` endpoints are live, the store products exist
  /// and RevenueCat is configured (see SUBSCRIPTIONS.md).
  static const bool subscriptionsEnabled = bool.fromEnvironment(
    'SUBSCRIPTIONS_ENABLED',
  );

  /// RevenueCat **public** SDK keys (Project settings > API keys > App
  /// specific). Google Play keys start with `goog_`, App Store keys with
  /// `appl_`. Never put a secret key (`sk_...`) here: it would ship inside
  /// the app.
  static const String revenueCatAndroidKey = String.fromEnvironment(
    'REVENUECAT_ANDROID_KEY',
  );
  static const String revenueCatIosKey = String.fromEnvironment(
    'REVENUECAT_IOS_KEY',
  );

  /// RevenueCat entitlement that unlocks the app, and the offering shown on
  /// the paywall.
  static const String entitlementId = 'app_access';
  static const String offeringId = 'default';

  /// Google sign-in is connected through Supabase OAuth. Until it is, the
  /// button cannot sign anyone in, so production builds hide it. Note: Apple
  /// then also requires Sign in with Apple (App Review guideline 4.8).
  static const bool googleSignInReady = false;

  /// Subscription screens are reachable in development, and in production
  /// once [subscriptionsEnabled] is on.
  static bool get showPremium => !isProduction || subscriptionsEnabled;
  static bool get showGoogleSignIn => !isProduction || googleSignInReady;

  /// Why this build must not run as a production app, or null when it is
  /// correctly configured. Checked at startup for production builds only.
  static String? get productionConfigProblem => checkProductionConfig(
    useMockData: useMockData,
    apiBaseUrl: apiBaseUrl,
    isWeb: kIsWeb,
    revenueCatKeys: [revenueCatAndroidKey, revenueCatIosKey],
  );

  /// Pure check behind [productionConfigProblem]; public for tests.
  static String? checkProductionConfig({
    required bool useMockData,
    required String apiBaseUrl,
    bool isWeb = false,
    List<String> revenueCatKeys = const [],
  }) {
    if (useMockData) return 'USE_MOCK_DATA must be false in production.';
    for (final key in revenueCatKeys) {
      if (isRevenueCatSecretKey(key)) {
        return 'A RevenueCat secret key was supplied. Use the public SDK key.';
      }
    }
    if (apiBaseUrl == sameOrigin) {
      return isWeb ? null : 'API_BASE_URL "same-origin" only works on web.';
    }
    final api = Uri.tryParse(apiBaseUrl);
    if (api == null || api.scheme != 'https' || api.host.isEmpty) {
      return 'API_BASE_URL must be an https:// address.';
    }
    if (const {'localhost', '127.0.0.1', '10.0.2.2'}.contains(api.host)) {
      return 'API_BASE_URL must not point to a local machine.';
    }
    return null;
  }

  /// RevenueCat secret (server) keys must never be built into the app.
  static bool isRevenueCatSecretKey(String key) =>
      key.startsWith('sk_') || key.startsWith('atk_');
}
