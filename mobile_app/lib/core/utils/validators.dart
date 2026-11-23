/// Form validators. Each returns an error message, or null when valid.
/// Messages say what to fix, in plain words.
abstract final class Validators {
  static final _email = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$');

  static String? required(String? value, {String field = 'This field'}) =>
      (value == null || value.trim().isEmpty) ? '$field is required' : null;

  static String? email(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Enter your email address';
    if (!_email.hasMatch(v)) {
      return 'Enter a valid email, like name@example.com';
    }
    return null;
  }

  static String? password(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return 'Enter a password';
    if (v.length < 8) return 'Use at least 8 characters';
    return null;
  }

  /// A new password, checked against the SharkHire password policy (the
  /// backend checks it again): 8–72 characters with a lowercase letter, an
  /// uppercase letter and a number, and not a common password.
  static String? newPassword(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return 'Enter a new password';
    if (v.length < 8) return 'Use at least 8 characters';
    if (v.length > 72) return 'Use 72 characters or fewer';
    if (!RegExp(r'[a-z]').hasMatch(v)) return 'Add a lowercase letter';
    if (!RegExp(r'[A-Z]').hasMatch(v)) return 'Add an uppercase letter';
    if (!RegExp(r'\d').hasMatch(v)) return 'Add a number';
    if (_commonPasswords.contains(v.toLowerCase())) {
      return 'This password is too common. Choose another.';
    }
    return null;
  }

  static const _commonPasswords = {
    'password',
    'password1',
    'password123',
    '12345678',
    '123456789',
    'qwerty123',
  };

  /// The confirmation must repeat [original].
  static String? Function(String?) matches(
    String Function() original, {
    String message = "Passwords don't match",
  }) =>
      (v) => (v ?? '').isEmpty
      ? 'Repeat the password'
      : v != original()
      ? message
      : null;

  static String? fullName(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Enter your full name';
    if (v.length < 2) return 'Name looks too short';
    return null;
  }

  /// Password strength 0–3 for the registration hint.
  static int passwordStrength(String value) {
    var score = 0;
    if (value.length >= 8) score++;
    if (RegExp(r'[A-Z]').hasMatch(value) && RegExp(r'[a-z]').hasMatch(value)) {
      score++;
    }
    if (RegExp(r'[0-9]').hasMatch(value) &&
        RegExp(r'[^A-Za-z0-9]').hasMatch(value)) {
      score++;
    }
    return score;
  }
}
