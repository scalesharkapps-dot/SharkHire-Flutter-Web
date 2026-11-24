import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_config.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/http_api_client.dart';

/// What the server reported after deleting an account.
class AccountDeletionResult {
  const AccountDeletionResult({this.activeStoreSubscription = false});

  /// A Google Play / App Store subscription is still active: it is billed by
  /// the store and must be cancelled there.
  final bool activeStoreSubscription;
}

/// The password didn't match, so nothing was deleted.
class WrongPasswordException implements Exception {
  const WrongPasswordException();
  String get message => 'That password is incorrect. Nothing was deleted.';

  @override
  String toString() => message;
}

/// Account-level requests the stores require: deleting the account from
/// inside the app (Apple guideline 5.1.1(v), Google Play account deletion
/// policy) and asking for a copy of your data.
abstract interface class AccountRepository {
  /// Permanently deletes the signed-in account: profile, CVs (files and
  /// data), saved jobs, applications and the Supabase user. Needs the
  /// current [password]. Throws [WrongPasswordException] when it's wrong.
  Future<AccountDeletionResult> requestDeletion({required String password});

  /// Asks the server to email the user a copy of their data.
  Future<void> requestDataExport();
}

/// REAL – `POST /api/v1/auth/delete-account` with
/// `{password, confirmation: "DELETE"}` (OpenAPI checked 24 Nov 2026).
/// Data export still has no endpoint, so it says so honestly.
class ApiAccountRepository implements AccountRepository {
  const ApiAccountRepository(this._api);

  final ApiClient _api;

  static const confirmation = 'DELETE';

  @override
  Future<AccountDeletionResult> requestDeletion({
    required String password,
  }) async {
    final Object? out;
    try {
      out = await _api.post(
        ApiEndpoints.authDeleteAccount,
        body: {'password': password, 'confirmation': confirmation},
      );
    } on ForbiddenException catch (e) {
      if (e.code == 'invalid_password') throw const WrongPasswordException();
      rethrow;
    }
    return AccountDeletionResult(
      activeStoreSubscription:
          out is Map && out['active_store_subscription'] == true,
    );
  }

  @override
  Future<void> requestDataExport() async =>
      throw const FeatureUnavailableException(
        "Data requests aren't available in the app yet. "
        'Please contact SharkHire support.',
      );
}

/// Development only – succeeds after a short delay.
class MockAccountRepository implements AccountRepository {
  const MockAccountRepository();

  @override
  Future<AccountDeletionResult> requestDeletion({
    required String password,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    return const AccountDeletionResult();
  }

  @override
  Future<void> requestDataExport() =>
      Future<void>.delayed(const Duration(milliseconds: 600));
}

final accountRepositoryProvider = Provider<AccountRepository>(
  (ref) => ApiConfig.isConfigured
      ? ApiAccountRepository(ref.watch(apiClientProvider))
      : const MockAccountRepository(),
);
