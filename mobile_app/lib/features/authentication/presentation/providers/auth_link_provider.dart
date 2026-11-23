import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/auth_link.dart';

/// Holds the email link (confirmation or password recovery) that opened the
/// app until its screen picks it up.
///
/// Links arrive through the router: on Android and iOS Flutter hands the
/// deep link to GoRouter whether the app was closed, in the background or
/// running; on the web the page itself was opened at the link. [capture]
/// stores the link and returns a clean in-app path, so tokens never stay in
/// the address bar, the route history or logs.
class AuthLinkController extends Notifier<AuthLink?> {
  bool _checkedBrowserUrl = false;
  String? _lastFingerprint;

  @override
  AuthLink? build() => null;

  /// The URL the web page was loaded with. Overridable in tests.
  @visibleForTesting
  Uri Function()? browserUrl;

  /// Called from the router's redirect for every navigation. Returns the
  /// path to show the link's screen, or null when [location] isn't a link.
  String? capture(Uri location) {
    Uri? source;
    if (AuthLink.isAuthPath(location.path) &&
        (location.hasQuery ||
            location.fragment.isNotEmpty ||
            (location.path != AuthLink.callbackPath &&
                location.path != AuthLink.resetPasswordPath))) {
      source = location;
    } else if (!_checkedBrowserUrl && (kIsWeb || browserUrl != null)) {
      // Web: the app uses hash routing, so the link's path, query and
      // fragment are only in the page URL, not in the route.
      _checkedBrowserUrl = true;
      final page = (browserUrl ?? () => Uri.base)();
      if (AuthLink.isAuthPath(page.path)) source = page;
    }
    if (source == null) return null;

    final link = AuthLink.fromUri(source);
    if (link == null) return null;
    // The same link delivered twice (e.g. resume + cold start) is handled
    // once; the screen keeps its own state.
    if (link.fingerprint != _lastFingerprint) {
      _lastFingerprint = link.fingerprint;
      state = link;
    }
    return link.kind == AuthLinkKind.recovery
        ? AuthLink.resetPasswordPath
        : AuthLink.callbackPath;
  }

  /// Hands the link to its screen and forgets it, so tokens don't linger.
  AuthLink? take() {
    final link = state;
    state = null;
    return link;
  }
}

final authLinkProvider = NotifierProvider<AuthLinkController, AuthLink?>(
  AuthLinkController.new,
);
