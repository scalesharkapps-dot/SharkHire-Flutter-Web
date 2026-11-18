import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../shared/models/backend_json.dart';
import '../models/job_details.dart';
import 'job_details_repository.dart';

/// REAL – `GET /api/v1/jobs/{id}` (SharkHire and JSearch jobs) plus the
/// user's match from `GET /api/v1/recommendations/jobs/{id}/match`.
class ApiJobDetailsRepository implements JobDetailsRepository {
  const ApiJobDetailsRepository(this._api);

  final ApiClient _api;

  @override
  Future<JobDetails> fetch(String jobId) async {
    final results =
        await Future.wait<Object?>([
          _api.get(ApiEndpoints.job(jobId)),
          // Match needs a CV or profile; a missing match isn't an error.
          _api.get(ApiEndpoints.jobMatch(jobId)).catchError((_) => null),
        ]).catchError((Object e) {
          if (e is NotFoundException) throw const JobNotFound();
          throw e;
        });
    final out = results[0]! as Map<String, Object?>;
    final job = out['job']! as Map<String, Object?>;
    final match =
        (results[1] as Map<String, Object?>?)?['match']
            as Map<String, Object?>?;
    if (job['listing_unavailable'] == true && job['job_apply_link'] == null) {
      throw const JobNotFound();
    }
    return jobDetailsFromApi(job, match);
  }

  /// The API has no click-tracking endpoint: external applications are
  /// recorded with `POST /applications` instead. Nothing is sent here.
  @override
  Future<void> recordExternalApplyClick(String jobId) async {}
}

/// `JobOut` (+ optional `MatchOut`) → [JobDetails].
JobDetails jobDetailsFromApi(
  Map<String, Object?> job,
  Map<String, Object?>? match,
) {
  final summary = jobSummaryFromApi(
    job,
    matchScore: (match?['match_percentage'] as num?)?.round(),
  );
  final highlights = job['job_highlights'] is Map
      ? job['job_highlights']! as Map
      : const {};
  List<String> highlight(String key) => apiStrings(highlights[key]);
  final description =
      (job['job_description'] as String?) ??
      (job['job_description_snippet'] as String?) ??
      '';
  return JobDetails(
    summary: summary,
    description: description.trim(),
    responsibilities: highlight('Responsibilities'),
    requirements: highlight('Qualifications'),
    requiredSkills: apiStrings(job['job_required_skills']),
    matchReasons: apiStrings(match?['reasons']),
    applyUrl: summary.isInternal ? null : job['job_apply_link'] as String?,
    publisher: job['job_publisher'] as String?,
    lastCheckedAt:
        apiDate(job['details_refreshed_at']) ?? apiDate(job['last_seen_at']),
    verifiedEmployer: summary.isInternal,
  );
}
