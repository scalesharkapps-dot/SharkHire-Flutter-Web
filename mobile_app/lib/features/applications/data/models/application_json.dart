import '../../../../shared/models/domain_enums.dart';
import '../../../../shared/models/json_mappers.dart';
import 'application.dart';

/// `GET /api/v1/applications/me` item (`applications` +
/// `application_status_history`).
///
/// ```json
/// {
///   "id": "uuid",
///   "job": { …job summary… },
///   "cv_file_name": "Ayesha_Khan_CV.pdf",
///   "cover_letter": "…",
///   "status_history": [
///     {"status": "submitted", "created_at": "2026-11-01T10:00:00Z"},
///     {"status": "shortlisted", "created_at": "…", "note": "…"}
///   ]
/// }
/// ```
JobApplication applicationFromJson(Map<String, Object?> j) {
  final history = [
    for (final h in (j['status_history'] as List? ?? const []))
      if (h is Map<String, Object?>)
        StatusChange(
          ApiEnum.parse(
            ApplicationStatus.values,
            h['status'] as String?,
            fallback: ApplicationStatus.submitted,
          )!,
          parseDate(h['created_at']) ?? DateTime.now(),
          note: h['note'] as String?,
        ),
  ];
  return JobApplication(
    id: '${j['id']}',
    job: jobSummaryFromJson(j['job'] as Map<String, Object?>),
    cvFileName: j['cv_file_name'] as String?,
    coverLetter: j['cover_letter'] as String?,
    history: history.isEmpty
        ? [StatusChange(ApplicationStatus.submitted, DateTime.now())]
        : history,
  );
}

/// `POST /api/v1/applications` body.
Map<String, Object?> applicationRequestToJson({
  required String jobId,
  required String resumeId,
  String? coverLetter,
}) => {'job_id': jobId, 'resume_id': resumeId, 'cover_letter': coverLetter};
