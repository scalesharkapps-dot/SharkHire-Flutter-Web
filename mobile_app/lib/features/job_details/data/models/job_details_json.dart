import '../../../../shared/models/domain_enums.dart';
import '../../../../shared/models/json_mappers.dart';
import 'job_details.dart';

/// `GET /api/v1/jobs/{id}` (internal) or the external job detail.
/// All job-summary fields (see `jobSummaryFromJson`) plus:
///
/// ```json
/// {
///   "description": "…", "responsibilities": ["…"], "requirements": ["…"],
///   "required_skills": ["Flutter", "Dart"],
///   "match_reasons": ["Your Flutter and Dart skills match this role"],
///   "experience_level": "senior", "education": "Bachelor's",
///   "vacancies": 2, "application_deadline": "2026-12-30T00:00:00Z",
///   "application_instructions": "…",
///   "apply_url": "https://…", "publisher": "LinkedIn",
///   "last_fetched_at": "2026-11-14T08:00:00Z",
///   "company_about": "…", "verified_employer": true
/// }
/// ```
/// External jobs keep `apply_url` and the provider's id (roadmap phase 4).
JobDetails jobDetailsFromJson(Map<String, Object?> j) => JobDetails(
  summary: jobSummaryFromJson(j),
  description: j['description'] as String? ?? '',
  responsibilities: stringList(j['responsibilities']),
  requirements: stringList(j['requirements']),
  requiredSkills: stringList(j['required_skills']),
  matchReasons: stringList(j['match_reasons']),
  experienceLevel: ApiEnum.parse(
    ExperienceLevel.values,
    j['experience_level'] as String?,
  ),
  education: j['education'] as String?,
  vacancies: (j['vacancies'] as num?)?.toInt(),
  deadline: parseDate(j['application_deadline']),
  applicationInstructions: j['application_instructions'] as String?,
  applyUrl: j['apply_url'] as String?,
  publisher: j['publisher'] as String?,
  lastCheckedAt: parseDate(j['last_fetched_at']),
  companyAbout: j['company_about'] as String?,
  verifiedEmployer: j['verified_employer'] as bool? ?? false,
);
