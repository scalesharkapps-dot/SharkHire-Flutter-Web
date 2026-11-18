import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/http_api_client.dart';
import '../../../../shared/models/backend_json.dart';
import '../../../../shared/models/job_summary.dart';

/// Bookmarked jobs (`/api/v1/saved-jobs`).
class SavedJobsRepository {
  const SavedJobsRepository(this._api);

  final ApiClient _api;

  /// Most recently saved first.
  Future<List<JobSummary>> list() async {
    final data = await _api.get(
      ApiEndpoints.savedJobs,
      query: {'sort': 'saved_at', 'page': 1, 'page_size': 50},
    );
    return [
      for (final s in apiItems(data))
        jobSummaryFromApi(
          s['job']! as Map<String, Object?>,
          matchScore: (s['match_percentage'] as num?)?.round(),
        ),
    ];
  }

  Future<void> save(String jobId) =>
      _api.post(ApiEndpoints.savedJob(jobId), body: const <String, Object?>{});

  Future<void> remove(String jobId) =>
      _api.delete(ApiEndpoints.savedJob(jobId));
}

final savedJobsRepositoryProvider = Provider<SavedJobsRepository>(
  (ref) => SavedJobsRepository(ref.watch(apiClientProvider)),
);
