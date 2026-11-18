// JSON ⇄ model mapping for data shared across features.
//
// Field names follow the database (Appendix A, snake_case). These are the
// shapes the app EXPECTS; final request/response schemas are to be agreed
// with the backend team before integration (guide §3.13). Unknown enum
// values fall back safely instead of crashing.

import 'app_user.dart';
import 'job_summary.dart';

T? _enum<T extends ApiEnum>(List<T> values, Object? raw, {T? fallback}) =>
    ApiEnum.parse(values, raw as String?, fallback: fallback);

DateTime? parseDate(Object? raw) =>
    raw is String ? DateTime.tryParse(raw)?.toLocal() : null;

List<String> stringList(Object? raw) => [
  for (final e in (raw as List? ?? const [])) '$e',
];

/// Job list item – internal (`jobs`) or external (`external_job_cache`).
///
/// ```json
/// {
///   "id": "uuid", "source": "internal" | "external",
///   "title": "Senior Flutter Developer", "company_name": "Indus Ledger",
///   "company_rating": 4.4, "location_text": "Lahore, Pakistan",
///   "is_international": false, "work_mode": "hybrid",
///   "employment_type": "full_time", "category": "Software",
///   "salary_label": "PKR 450K – 600K / month",
///   "posted_at": "2026-11-12T09:00:00Z", "match_score": 92
/// }
/// ```
JobSummary jobSummaryFromJson(Map<String, Object?> j) => JobSummary(
  id: '${j['id']}',
  title: j['title'] as String? ?? 'Untitled job',
  companyName: j['company_name'] as String? ?? 'Company',
  companyRating: (j['company_rating'] as num?)?.toDouble(),
  location:
      j['location_text'] as String? ??
      [j['city'], j['country']].whereType<String>().join(', '),
  isInternational: j['is_international'] as bool? ?? false,
  source: j['source'] == 'internal' ? JobSource.internal : JobSource.external,
  workMode: _enum(WorkMode.values, j['work_mode'], fallback: WorkMode.onsite)!,
  employmentType: _enum(
    EmploymentType.values,
    j['employment_type'],
    fallback: EmploymentType.fullTime,
  )!,
  category: j['category'] as String?,
  salaryLabel: j['salary_label'] as String?,
  matchScore: (j['match_score'] as num?)?.round(),
  postedAt: parseDate(j['posted_at']) ?? DateTime.now(),
);

/// `GET /api/v1/auth/me` – the signed-in user's profile and roles.
///
/// ```json
/// {
///   "full_name": "Ayesha Khan", "email": "ayesha@example.com",
///   "roles": ["job_seeker"], "headline": "Flutter Developer",
///   "city": "Lahore", "country": "Pakistan", "phone": "+92…",
///   "profile_completion": 0.45, "has_active_resume": false, "is_premium": false
/// }
/// ```
AppUser appUserFromJson(Map<String, Object?> j) => AppUser(
  fullName: j['full_name'] as String? ?? '',
  email: j['email'] as String? ?? '',
  roles: {
    for (final r in stringList(j['roles'])) ?ApiEnum.parse(AppRole.values, r),
  }.ifEmpty({AppRole.jobSeeker}),
  headline: j['headline'] as String?,
  location: [
    j['city'],
    j['country'],
  ].whereType<String>().join(', ').nullIfEmpty,
  phone: j['phone'] as String?,
  profileCompletion: (j['profile_completion'] as num?)?.toDouble() ?? 0,
  hasCv: j['has_active_resume'] as bool? ?? false,
  isPremium: j['is_premium'] as bool? ?? false,
);

/// `PUT /api/v1/profiles/me` body.
Map<String, Object?> profileUpdateToJson(AppUser u) {
  final parts = (u.location ?? '').split(',').map((s) => s.trim()).toList();
  return {
    'full_name': u.fullName,
    'headline': u.headline,
    'phone': u.phone,
    'city': parts.isNotEmpty && parts.first.isNotEmpty ? parts.first : null,
    'country': parts.length > 1 ? parts.last : null,
  };
}

extension<T> on Set<T> {
  Set<T> ifEmpty(Set<T> fallback) => isEmpty ? fallback : this;
}

extension on String {
  String? get nullIfEmpty => isEmpty ? null : this;
}
