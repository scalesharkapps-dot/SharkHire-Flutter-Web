/// App-wide, non-visual constants.
abstract final class AppConstants {
  static const String appName = 'SharkHire';

  /// Shown in Profile and Help. Keep equal to `version:` in pubspec.yaml
  /// (the part before `+`) when releasing.
  static const String appVersion = '1.0.0';
  static const String companyName = 'Scale Shark';
  static const String companyLegalName = 'SCALE SHARK (PRIVATE) LIMITED';
  static const String companyWebsite = 'https://thescaleshark.io/';
  static const String tagline = 'AI-powered hiring, built by Scale Shark';

  // Subscription model (UI only). Prices always come from the store
  // (RevenueCat offering); the trial itself is run by the backend.
  static const int freeTrialDays = 3;
}
