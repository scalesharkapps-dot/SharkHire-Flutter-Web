import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// "Remember me" choice and the remembered email, kept on this device.
///
/// The password is never stored by the app: when "Remember me" is on, the
/// device's own password manager (Google Password Manager, iCloud Keychain,
/// the browser) is asked to save it, in its own secure storage.
@immutable
class LoginPreferences {
  const LoginPreferences({this.rememberMe = true, this.email});

  final bool rememberMe;
  final String? email;
}

abstract interface class LoginPreferencesStore {
  Future<LoginPreferences> read();
  Future<void> write(LoginPreferences prefs);
}

class SecureLoginPreferencesStore implements LoginPreferencesStore {
  const SecureLoginPreferencesStore([
    this._storage = const FlutterSecureStorage(),
  ]);

  final FlutterSecureStorage _storage;
  static const _rememberKey = 'sharkhire.remember_me';
  static const _emailKey = 'sharkhire.remembered_email';

  @override
  Future<LoginPreferences> read() async {
    try {
      final remember = await _storage.read(key: _rememberKey);
      final email = await _storage.read(key: _emailKey);
      return LoginPreferences(rememberMe: remember != 'false', email: email);
    } catch (_) {
      return const LoginPreferences();
    }
  }

  @override
  Future<void> write(LoginPreferences prefs) async {
    try {
      await _storage.write(
        key: _rememberKey,
        value: prefs.rememberMe ? 'true' : 'false',
      );
      final email = prefs.email;
      if (prefs.rememberMe && email != null && email.isNotEmpty) {
        await _storage.write(key: _emailKey, value: email);
      } else {
        await _storage.delete(key: _emailKey);
      }
    } catch (_) {
      // Not saved: the user just types their email next time.
    }
  }
}

final loginPreferencesStoreProvider = Provider<LoginPreferencesStore>(
  (ref) => const SecureLoginPreferencesStore(),
);
