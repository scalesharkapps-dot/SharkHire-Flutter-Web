import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/http_api_client.dart';
import '../../../../shared/models/backend_json.dart';
import '../../../../shared/models/job_summary.dart';
import '../models/application.dart';

/// The job seeker's applications (`/api/v1/applications`).
class ApplicationsRepository {
  const ApplicationsRepository(this._api);

  final ApiClient _api;

  Future<List<JobApplication>> list() async {
    final data = await _api.get(
      ApiEndpoints.applications,
      query: {'sort': 'updated_at', 'page': 1, 'page_size': 50},
    );
    return [for (final a in apiItems(data)) applicationFromApi(a)];
  }

  /// Applies to [job] with the user's CV. For SharkHire jobs the employer
  /// receives it; external jobs are only recorded (the backend never
  /// submits anything to an external employer).
  Future<JobApplication> apply(
    JobSummary job, {
    String? cvId,
    String? coverLetter,
  }) async {
    final out =
        await _api.post(
              ApiEndpoints.applications,
              body: {
                'job_id': job.id,
                'status': 'applied',
                'discovered_via': 'search',
                'selected_cv_id': ?cvId,
                'cover_letter': ?coverLetter,
              },
            )
            as Map<String, Object?>;
    return applicationFromApi(out, fallbackJob: job);
  }

  Future<JobApplication> withdraw(String id) async {
    final out =
        await _api.patch(
              ApiEndpoints.applicationStatus(id),
              body: {'status': 'withdrawn', 'notes': 'Withdrawn by you'},
            )
            as Map<String, Object?>;
    return applicationFromApi(out);
  }
}

final applicationsRepositoryProvider = Provider<ApplicationsRepository>(
  (ref) => ApplicationsRepository(ref.watch(apiClientProvider)),
);

/// `ApplicationDetailOut` → [JobApplication].
JobApplication applicationFromApi(
  Map<String, Object?> j, {
  JobSummary? fallbackJob,
}) {
  final job = j['job'] is Map<String, Object?>
      ? jobSummaryFromApi(
          j['job']! as Map<String, Object?>,
          matchScore: (j['match_percentage'] as num?)?.round(),
        )
      : fallbackJob ??
            JobSummary(
              id: '${j['job_id'] ?? j['id']}',
              title: (j['job_title'] as String?) ?? 'Job',
              companyName: (j['company_name'] as String?) ?? 'Company',
              location: (j['job_location'] as String?) ?? '',
              source: j['source'] == 'sharkhire'
                  ? JobSource.internal
                  : JobSource.external,
              workMode: WorkMode.onsite,
              employmentType: employmentTypeFromApi(j['employment_type']),
              postedAt: apiDate(j['created_at']) ?? DateTime.now(),
            );

  final created =
      apiDate(j['applied_at']) ??
      apiDate(j['submitted_at']) ??
      apiDate(j['created_at']) ??
      DateTime.now();
  final history = <StatusChange>[
    for (final h in (j['history'] as List? ?? const []))
      if (h is Map)
        StatusChange(
          applicationStatusFromApi(h['new_status']),
          apiDate(h['changed_at']) ?? created,
          note: h['notes'] as String?,
        ),
  ]..sort((a, b) => a.at.compareTo(b.at));
  final current = applicationStatusFromApi(j['status']);
  if (history.isEmpty || history.first.status != ApplicationStatus.submitted) {
    history.insert(0, StatusChange(ApplicationStatus.submitted, created));
  }
  if (history.last.status != current) {
    history.add(
      StatusChange(current, apiDate(j['updated_at']) ?? DateTime.now()),
    );
  }
  return JobApplication(
    id: '${j['id']}',
    job: job,
    history: history,
    cvFileName: j['selected_cv_id'] == null ? null : 'Your CV',
    coverLetter: j['cover_letter'] as String?,
  );
}
