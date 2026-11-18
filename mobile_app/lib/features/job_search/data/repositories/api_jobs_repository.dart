import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../shared/models/backend_json.dart';
import '../../../../shared/models/job_summary.dart';
import 'jobs_repository.dart';

/// REAL – jobs from the SharkHire API.
///
/// * The default list combines published SharkHire jobs
///   (`GET /jobs/sharkhire`) with the user's recommendations
///   (`GET /recommendations/for-me`). Neither uses the job-search quota.
/// * A typed search calls JSearch (`GET /jobs/search`, uses the RapidAPI
///   quota) together with SharkHire jobs matching the same text.
class ApiJobsRepository implements JobsRepository {
  const ApiJobsRepository(this._api);

  final ApiClient _api;

  @override
  Future<List<JobSummary>> fetchJobs() async {
    final results = await Future.wait([_recommendations(), _sharkHire(null)]);
    return _merge(results);
  }

  @override
  Future<List<JobSummary>> search(String query) async {
    final results = await Future.wait([
      _api
          .get(
            ApiEndpoints.jobSearch,
            query: {'query': query.trim(), 'num_pages': 1},
          )
          .then(
            (data) => [for (final j in apiItems(data)) jobSummaryFromApi(j)],
          ),
      _sharkHire(query.trim()),
    ]);
    return _merge(results);
  }

  Future<List<JobSummary>> _sharkHire(String? q) async {
    final data = await _api.get(
      ApiEndpoints.sharkHireJobs,
      query: {'q': q, 'page': 1, 'page_size': 20},
    );
    return [for (final j in apiItems(data)) jobSummaryFromApi(j)];
  }

  /// Recommendations need a CV or job titles; without them the API answers
  /// 422 `insufficient_profile`, which simply means "no recommendations yet".
  Future<List<JobSummary>> _recommendations() async {
    try {
      final data = await _api.get(
        ApiEndpoints.recommendationsForMe,
        query: {'page': 1, 'page_size': 20},
      );
      return [
        for (final item in apiItems(data))
          jobSummaryFromApi(
            item['job']! as Map<String, Object?>,
            matchScore: ((item['match'] as Map?)?['match_percentage'] as num?)
                ?.round(),
          ),
      ];
    } on ValidationException {
      return const [];
    }
  }

  /// Keeps the first copy of each job (recommendations carry match scores).
  List<JobSummary> _merge(List<List<JobSummary>> lists) {
    final seen = <String>{};
    return [
      for (final list in lists)
        for (final job in list)
          if (seen.add(job.id)) job,
    ];
  }
}
