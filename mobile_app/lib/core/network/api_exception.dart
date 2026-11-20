/// Typed failure surfaced by repositories so the UI can show the right
/// message (offline, session expired, validation, rate limit, server error…).
///
/// The SharkHire API answers errors with
/// `{"success": false, "message": "...", "error": {"code": "...", "message": "...", "details": [...]}}`.
/// [message] is the backend's user-facing message when it sent one, and
/// [code] its machine-readable `error.code` (e.g. `invalid_credentials`).
sealed class ApiException implements Exception {
  const ApiException(this.message, {this.code, this.remainingAttempts});
  final String message;
  final String? code;

  /// The backend's `remaining_attempts`, when the response includes one
  /// (e.g. resend-verification limits). Null when the backend didn't send it.
  final int? remainingAttempts;

  @override
  String toString() => '$runtimeType(${code ?? '-'}): $message';
}

/// No connection.
class NetworkException extends ApiException {
  const NetworkException([
    super.message =
        'No internet connection. Check your connection and try again.',
  ]);
}

/// The server didn't answer in time.
class RequestTimeoutException extends ApiException {
  const RequestTimeoutException([
    super.message = 'This is taking longer than usual. Please try again.',
  ]);
}

/// 401 – missing, expired or invalid token, or wrong login details
/// (`code == "invalid_credentials"`).
class UnauthorizedException extends ApiException {
  const UnauthorizedException([
    super.message = 'Your session has expired. Please log in again.',
    String? code,
  ]) : super(code: code);
}

/// 403 – signed in but not allowed (e.g. wrong role, inactive account).
class ForbiddenException extends ApiException {
  const ForbiddenException([
    super.message = 'You don\'t have access to this.',
    String? code,
  ]) : super(code: code);
}

/// 404 – resource no longer exists (e.g. an expired external listing).
class NotFoundException extends ApiException {
  const NotFoundException([
    super.message = 'This item is no longer available.',
    String? code,
  ]) : super(code: code);
}

/// 400 / 409 / 422 – the backend rejected the input; [fieldErrors] maps
/// field → message.
class ValidationException extends ApiException {
  const ValidationException(
    super.message, {
    this.fieldErrors = const {},
    super.code,
    super.remainingAttempts,
  });
  final Map<String, String> fieldErrors;
}

/// 429 – too many requests (e.g. the job search provider's plan limit).
/// [retryAfter] comes from the `Retry-After` header.
class RateLimitedException extends ApiException {
  const RateLimitedException({
    this.retryAfter,
    String message =
        'Job search is busy right now. Please try again in a minute.',
    String? code,
    int? remainingAttempts,
  }) : super(message, code: code, remainingAttempts: remainingAttempts);
  final Duration? retryAfter;
}

/// The backend has no endpoint for this action yet.
class FeatureUnavailableException extends ApiException {
  const FeatureUnavailableException(super.message);
}

/// 5xx or anything unexpected.
class ServerException extends ApiException {
  const ServerException([
    super.message = 'Something went wrong on our side. Please try again.',
    String? code,
  ]) : super(code: code);
}

/// Plain-language message for any error shown in the UI.
String friendlyErrorMessage(Object error) => error is ApiException
    ? error.message
    : 'We couldn\'t load this right now. Check your connection and try again.';
