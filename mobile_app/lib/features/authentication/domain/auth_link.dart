/// What an email link from Supabase is for.
enum AuthLinkKind {
  /// Sign-up confirmation (also email change, invite, magic link).
  confirmEmail,

  /// "Reset your password" link.
  recovery,
}

/// A link from a SharkHire email (sign-up confirmation or password
/// recovery) after Supabase has handled it and sent the user back to the
/// app.
///
/// Supabase puts its result in the query string or in the URL fragment:
/// * implicit flow: `#access_token=…&refresh_token=…&expires_in=…&type=signup`
/// * token-hash flow: `?token_hash=…&type=recovery`
/// * PKCE flow: `?code=…` (the email is already confirmed by then)
/// * failure: `#error=access_denied&error_code=otp_expired&error_description=…`
///
/// Tokens are kept in memory only and never printed: [toString] leaves
/// them out.
class AuthLink {
  const AuthLink({
    required this.kind,
    this.accessToken,
    this.refreshToken,
    this.expiresIn,
    this.expiresAt,
    this.tokenHash,
    this.error,
    this.errorCode,
    this.errorDescription,
    this.fingerprint = '',
  });

  /// In-app path for confirmation links.
  static const callbackPath = '/auth/callback';

  /// In-app path for password-recovery links.
  static const resetPasswordPath = '/auth/reset-password';

  /// Custom-scheme links (`sharkhire://auth/callback`) reach the router as
  /// `/callback`, because `auth` is the URI host.
  static const _schemeCallback = '/callback';
  static const _schemeReset = '/reset-password';

  /// Whether [path] is where Supabase sends users back to.
  static bool isAuthPath(String path) => const {
    callbackPath,
    resetPasswordPath,
    _schemeCallback,
    _schemeReset,
  }.contains(_trimSlash(path));

  static String _trimSlash(String p) =>
      p.length > 1 && p.endsWith('/') ? p.substring(0, p.length - 1) : p;

  /// Reads a link, or returns null when [uri] isn't an auth link.
  static AuthLink? fromUri(Uri uri) {
    final path = _trimSlash(uri.path);
    if (!isAuthPath(path)) return null;
    final p = <String, String>{...uri.queryParameters};
    final fragment = uri.fragment;
    if (fragment.contains('=')) {
      try {
        p.addAll(Uri.splitQueryString(fragment));
      } on FormatException {
        // A malformed fragment carries nothing we can use.
      }
    }
    final type = p['type']?.toLowerCase();
    final recovery =
        type == 'recovery' || path == resetPasswordPath || path == _schemeReset;
    return AuthLink(
      kind: recovery ? AuthLinkKind.recovery : AuthLinkKind.confirmEmail,
      accessToken: _nonEmpty(p['access_token']),
      refreshToken: _nonEmpty(p['refresh_token']),
      expiresIn: int.tryParse(p['expires_in'] ?? ''),
      expiresAt: int.tryParse(p['expires_at'] ?? ''),
      tokenHash: _nonEmpty(p['token_hash']),
      error: _nonEmpty(p['error']),
      errorCode: _nonEmpty(p['error_code']),
      errorDescription: _nonEmpty(p['error_description']),
      fingerprint: '$path?${uri.query}#$fragment'.hashCode.toString(),
    );
  }

  static String? _nonEmpty(String? v) => v == null || v.isEmpty ? null : v;

  final AuthLinkKind kind;
  final String? accessToken;
  final String? refreshToken;
  final int? expiresIn;
  final int? expiresAt;
  final String? tokenHash;
  final String? error;
  final String? errorCode;
  final String? errorDescription;

  /// Identifies this exact link so a repeated delivery isn't handled twice.
  /// A hash, so it never holds a token.
  final String fingerprint;

  bool get hasError => error != null || errorCode != null;

  /// Supabase reports expired and already-used links the same way.
  bool get isExpired =>
      errorCode == 'otp_expired' ||
      (errorDescription?.toLowerCase().contains('expired') ?? false);

  /// The link carries a signed-in session (implicit flow).
  bool get hasSession => accessToken != null;

  /// Enough to set a new password: a recovery token or a token hash.
  bool get canResetPassword =>
      !hasError && (accessToken != null || tokenHash != null);

  /// The session in the shape of the backend's `SessionOut`.
  Map<String, Object?> get sessionJson => {
    'access_token': accessToken,
    'refresh_token': refreshToken,
    'expires_in': expiresIn,
    'expires_at': expiresAt,
  };

  @override
  String toString() =>
      'AuthLink(${kind.name}, session: $hasSession, '
      'tokenHash: ${tokenHash != null}, error: ${errorCode ?? error})';
}
