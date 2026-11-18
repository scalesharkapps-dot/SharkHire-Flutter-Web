import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_config.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/http_api_client.dart';
import '../../../../shared/models/app_user.dart';
import '../../../../shared/models/backend_json.dart';
import '../../../../shared/models/domain_enums.dart';
import '../models/job_preferences.dart';

/// Profile edits and job preferences.
abstract interface class ProfileRepository {
  /// `PATCH /api/v1/profile/me`
  Future<void> updateProfile(AppUser user);

  /// `GET /api/v1/recommendations/preferences`; null when never saved.
  Future<JobPreferences?> fetchPreferences();

  /// `PUT /api/v1/recommendations/preferences`
  Future<void> savePreferences(JobPreferences prefs);
}

class ApiProfileRepository implements ProfileRepository {
  const ApiProfileRepository(this._api);

  final ApiClient _api;

  @override
  Future<void> updateProfile(AppUser user) =>
      _api.patch(ApiEndpoints.profileMe, body: profilePatchToApi(user));

  @override
  Future<JobPreferences?> fetchPreferences() async {
    final j = await _api.get(ApiEndpoints.preferences) as Map<String, Object?>?;
    if (j == null || j['updated_at'] == null) return null;
    return preferencesFromApi(j);
  }

  @override
  Future<void> savePreferences(JobPreferences prefs) =>
      _api.put(ApiEndpoints.preferences, body: preferencesToApi(prefs));
}

/// Development only.
class MockProfileRepository implements ProfileRepository {
  const MockProfileRepository();

  @override
  Future<void> updateProfile(AppUser user) async {}

  @override
  Future<JobPreferences?> fetchPreferences() async => null;

  @override
  Future<void> savePreferences(JobPreferences prefs) async {}
}

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => ApiConfig.isConfigured
      ? ApiProfileRepository(ref.watch(apiClientProvider))
      : const MockProfileRepository(),
);

// ── Mapping (`PreferencesIn` / `PreferencesOut`) ────────────────────────────

/// The app's job categories are sent as preferred job titles, the closest
/// field the API offers for matching.
Map<String, Object?> preferencesToApi(JobPreferences p) {
  final modes = p.workModes;
  return {
    'preferred_job_titles': p.categories.toList(),
    'preferred_locations': const <String>[],
    'preferred_countries': p.includePakistan && !p.includeInternational
        ? const ['pk']
        : const <String>[],
    'employment_types': {
      for (final t in p.employmentTypes) employmentTypeToApi(t),
    }.toList(),
    'remote_preference': modes.length == 1
        ? switch (modes.first) {
            WorkMode.remote => 'remote_only',
            WorkMode.hybrid => 'hybrid',
            WorkMode.onsite => 'onsite',
          }
        : 'any',
    'experience_level': switch (p.experienceLevel) {
      ExperienceLevel.any => null,
      ExperienceLevel.executive => 'manager',
      final l => l.apiValue,
    },
  };
}

JobPreferences preferencesFromApi(Map<String, Object?> j) {
  final countries = apiStrings(j['preferred_countries']);
  final pkOnly = countries.length == 1 && countries.first.toLowerCase() == 'pk';
  final remote = '${j['remote_preference'] ?? 'any'}';
  return JobPreferences(
    includePakistan: true,
    includeInternational: !pkOnly,
    categories: apiStrings(j['preferred_job_titles']).toSet(),
    employmentTypes: {
      for (final t in apiStrings(j['employment_types']))
        employmentTypeFromApi(t),
    },
    workModes: switch (remote) {
      'remote_only' => {WorkMode.remote},
      'hybrid' => {WorkMode.hybrid},
      'onsite' => {WorkMode.onsite},
      _ => const <WorkMode>{},
    },
    experienceLevel: j['experience_level'] == 'manager'
        ? ExperienceLevel.executive
        : ApiEnum.parse(
            ExperienceLevel.values,
            j['experience_level'] as String?,
            fallback: ExperienceLevel.any,
          )!,
  );
}
