import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_config.dart';
import '../../../../core/network/api_exception.dart';

/// Account-level requests the stores require: deleting the account from
/// inside the app (Apple guideline 5.1.1(v), Google Play account deletion
/// policy) and asking for a copy of your data.
abstract interface class AccountRepository {
  /// Starts account deletion on the server. The backend deletes the profile,
  /// CVs, saved jobs and applications and the Supabase user.
  Future<void> requestDeletion();

  /// Asks the server to email the user a copy of their data.
  Future<void> requestDataExport();
}

/// REAL – the deployed API (OpenAPI, 17 Nov 2026) has **no** endpoint for
/// account deletion or data export yet, so these report that honestly
/// instead of pretending. Store blocker: see MOBILE_RELEASE_CHECKLIST.md.
class ApiAccountRepository implements AccountRepository {
  const ApiAccountRepository();

  @override
  Future<void> requestDeletion() async =>
      throw const FeatureUnavailableException(
        "Deleting your account from the app isn't available yet. "
        "Please contact SharkHire support and we'll delete it for you.",
      );

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
  Future<void> requestDeletion() =>
      Future<void>.delayed(const Duration(milliseconds: 600));

  @override
  Future<void> requestDataExport() =>
      Future<void>.delayed(const Duration(milliseconds: 600));
}

final accountRepositoryProvider = Provider<AccountRepository>(
  (ref) => ApiConfig.isConfigured
      ? const ApiAccountRepository()
      : const MockAccountRepository(),
);
