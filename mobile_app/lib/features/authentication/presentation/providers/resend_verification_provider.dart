import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../data/repositories/auth_repository.dart';

/// Shown (exactly) once the backend reports the resend limit is reached.
const resendLimitMessage =
    "You've reached the maximum resend limit. Please try again later.";

enum ResendNoticeTone { success, info, error }

/// Resend-verification state for one email address.
///
/// The backend is the source of truth for the limit: [remainingAttempts]
/// and [limitReached] only ever come from its responses (its
/// `remaining_attempts`, or HTTP 429). The app never counts resends itself.
@immutable
class ResendVerificationState {
  const ResendVerificationState({
    this.sending = false,
    this.remainingAttempts,
    this.limitReached = false,
    this.alreadyVerified = false,
    this.notice,
    this.noticeTone = ResendNoticeTone.success,
    this.lastSentAt,
  });

  /// A request is in flight; further taps are ignored.
  final bool sending;

  /// Resends left according to the backend, or null when it doesn't say.
  final int? remainingAttempts;

  /// The backend refused further resends (429 or `remaining_attempts: 0`).
  final bool limitReached;

  /// The backend reported the address is already confirmed.
  final bool alreadyVerified;

  /// Message to show under the button (the backend's own wording when
  /// available).
  final String? notice;
  final ResendNoticeTone noticeTone;

  /// When the backend last confirmed a resend (for the short cooldown).
  final DateTime? lastSentAt;

  bool get canResend => !sending && !limitReached && !alreadyVerified;

  ResendVerificationState copyWith({
    bool? sending,
    int? Function()? remainingAttempts,
    bool? limitReached,
    bool? alreadyVerified,
    String? Function()? notice,
    ResendNoticeTone? noticeTone,
    DateTime? lastSentAt,
  }) => ResendVerificationState(
    sending: sending ?? this.sending,
    remainingAttempts: remainingAttempts != null
        ? remainingAttempts()
        : this.remainingAttempts,
    limitReached: limitReached ?? this.limitReached,
    alreadyVerified: alreadyVerified ?? this.alreadyVerified,
    notice: notice != null ? notice() : this.notice,
    noticeTone: noticeTone ?? this.noticeTone,
    lastSentAt: lastSentAt ?? this.lastSentAt,
  );
}

/// Sends "resend verification email" requests for one address and keeps the
/// result for as long as the app runs (so leaving and reopening the screen
/// shows the same state).
class ResendVerificationController extends Notifier<ResendVerificationState> {
  ResendVerificationController(this.email);

  final String email;

  @override
  ResendVerificationState build() => const ResendVerificationState();

  Future<void> resend() async {
    // One request at a time; no requests once the backend has said no.
    if (!state.canResend) return;
    state = state.copyWith(sending: true, notice: () => null);
    try {
      final result = await ref
          .read(authRepositoryProvider)
          .resendVerificationEmail(email);
      if (!ref.mounted) return;
      final noneLeft = result.remainingAttempts == 0;
      state = state.copyWith(
        sending: false,
        remainingAttempts: () => result.remainingAttempts,
        limitReached: noneLeft,
        notice: () => result.message,
        noticeTone: ResendNoticeTone.success,
        lastSentAt: DateTime.now(),
      );
    } on RateLimitedException catch (e) {
      if (!ref.mounted) return;
      state = state.copyWith(
        sending: false,
        remainingAttempts: () => e.remainingAttempts ?? 0,
        limitReached: true,
        notice: () => null,
      );
    } on ApiException catch (e) {
      if (!ref.mounted) return;
      if (_isAlreadyVerified(e)) {
        state = state.copyWith(
          sending: false,
          alreadyVerified: true,
          notice: () =>
              'Your email is already confirmed. Tap "I\'ve confirmed my '
              'email" to continue.',
          noticeTone: ResendNoticeTone.info,
        );
      } else if (e.remainingAttempts == 0) {
        state = state.copyWith(
          sending: false,
          remainingAttempts: () => 0,
          limitReached: true,
          notice: () => null,
        );
      } else {
        // Network, timeout, server, expired or other Supabase errors: the
        // backend's (or our friendly) message; the user can try again.
        state = state.copyWith(
          sending: false,
          notice: () => friendlyErrorMessage(e),
          noticeTone: ResendNoticeTone.error,
        );
      }
    } catch (e) {
      if (!ref.mounted) return;
      state = state.copyWith(
        sending: false,
        notice: () => friendlyErrorMessage(e),
        noticeTone: ResendNoticeTone.error,
      );
    }
  }

  static bool _isAlreadyVerified(ApiException e) {
    final text = '${e.code ?? ''} ${e.message}'.toLowerCase();
    return text.contains('already') &&
        (text.contains('confirm') || text.contains('verif'));
  }
}

/// Keyed by the (lower-case) email address.
final resendVerificationProvider =
    NotifierProvider.family<
      ResendVerificationController,
      ResendVerificationState,
      String
    >(ResendVerificationController.new);
