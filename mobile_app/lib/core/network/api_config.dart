import '../config/app_config.dart';

/// Network settings shared by every API call (project guide §3.17).
///
/// The base URL comes from a build-time define so no environment is
/// hard-coded in source:
/// `flutter run --dart-define=API_BASE_URL=https://<backend-host>`
/// A production build must never point at localhost.
abstract final class ApiConfig {
  static String get baseUrl => AppConfig.resolvedApiBaseUrl;

  /// True once a backend URL has been supplied. Until then the app runs on
  /// mock repositories.
  static bool get isConfigured => baseUrl.isNotEmpty && !AppConfig.useMockData;

  static const Duration connectTimeout = Duration(seconds: 15);

  /// 60 s: the current backend host sleeps when idle and its first answer
  /// can take ~30–50 s ("cold start"). Lower this once it runs on an
  /// always-on plan.
  static const Duration receiveTimeout = Duration(seconds: 60);

  /// CV uploads (up to 5 MB) on slow mobile networks need longer.
  static const Duration uploadTimeout = Duration(minutes: 2);

  /// Header carrying the Supabase access token, verified by FastAPI
  /// (`Authorization: Bearer <token>`, guide §3.4).
  static const String authHeader = 'Authorization';
  static String bearer(String accessToken) => 'Bearer $accessToken';
}
