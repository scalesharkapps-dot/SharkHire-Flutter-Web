import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Counts "session expired" signals (HTTP 401). The session controller
/// listens to it and signs the user out, so the router returns to login.
/// Kept in core so the network layer does not depend on a feature.
class SessionExpiry extends Notifier<int> {
  @override
  int build() => 0;

  void expired() => state++;
}

final sessionExpiryProvider = NotifierProvider<SessionExpiry, int>(
  SessionExpiry.new,
);
