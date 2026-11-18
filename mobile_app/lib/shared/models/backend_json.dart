// Mapping between the deployed SharkHire API (OpenAPI, 17 Nov 2026) and the
// app's UI models. Screens never see backend JSON; if the API changes, only
// this file and the feature `*_api.dart` mappers change.

import 'app_user.dart';
import 'job_summary.dart';

DateTime? apiDate(Object? raw) =>
    raw is String ? DateTime.tryParse(raw)?.toLocal() : null;

List<String> apiStrings(Object? raw) => [
  for (final e in (raw as List? ?? const [])) '$e',
];

/// `{items: [...]}` from list endpoints, or a bare list.
List<Map<String, Object?>> apiItems(Object? data) {
  final list = data is Map
      ? (data['items'] ?? data['results'] ?? data['jobs'] ?? const [])
      : (data ?? const []);
  return [for (final e in list as List) e as Map<String, Object?>];
}

// ── Enums ───────────────────────────────────────────────────────────────────

/// JSearch employment types: FULLTIME, PARTTIME, CONTRACTOR, INTERN.
EmploymentType employmentTypeFromApi(Object? raw) =>
    switch ('${raw ?? ''}'.toUpperCase().replaceAll(RegExp('[^A-Z]'), '')) {
      'PARTTIME' => EmploymentType.partTime,
      'CONTRACTOR' || 'CONTRACT' => EmploymentType.contract,
      'INTERN' || 'INTERNSHIP' => EmploymentType.internship,
      'TEMPORARY' => EmploymentType.temporary,
      'FREELANCE' => EmploymentType.freelance,
      _ => EmploymentType.fullTime,
    };

String employmentTypeToApi(EmploymentType t) => switch (t) {
  EmploymentType.fullTime => 'FULLTIME',
  EmploymentType.partTime => 'PARTTIME',
  EmploymentType.internship => 'INTERN',
  EmploymentType.contract ||
  EmploymentType.temporary ||
  EmploymentType.freelance => 'CONTRACTOR',
};

/// Backend application statuses (12) shown with the app's 7 stages.
ApplicationStatus applicationStatusFromApi(Object? raw) => switch ('$raw') {
  'application_viewed' => ApplicationStatus.underReview,
  'shortlisted' => ApplicationStatus.shortlisted,
  'interview_scheduled' ||
  'interview_completed' ||
  'assessment' => ApplicationStatus.interview,
  'offer_received' || 'hired' => ApplicationStatus.accepted,
  'rejected' => ApplicationStatus.rejected,
  'withdrawn' => ApplicationStatus.withdrawn,
  // interested, saved, applied
  _ => ApplicationStatus.submitted,
};

/// API value used when the app changes an application's status.
String applicationStatusToApi(ApplicationStatus s) => switch (s) {
  ApplicationStatus.submitted => 'applied',
  ApplicationStatus.underReview => 'application_viewed',
  ApplicationStatus.shortlisted => 'shortlisted',
  ApplicationStatus.interview => 'interview_scheduled',
  ApplicationStatus.rejected => 'rejected',
  ApplicationStatus.accepted => 'offer_received',
  ApplicationStatus.withdrawn => 'withdrawn',
};

AppRole appRoleFromApi(Object? raw) =>
    ApiEnum.parse(AppRole.values, raw as String?, fallback: AppRole.jobSeeker)!;

// ── Jobs ────────────────────────────────────────────────────────────────────

/// "PKR 150K – 220K / month" from the backend's salary fields.
String? salaryLabelFromApi(Map<String, Object?> j) {
  final text = j['job_salary_text'];
  if (text is String && text.trim().isNotEmpty) return text.trim();
  final min = (j['job_min_salary'] as num?)?.toDouble();
  final max = (j['job_max_salary'] as num?)?.toDouble();
  if (min == null && max == null) return null;
  String k(double v) => v >= 1000
      ? '${(v / 1000).toStringAsFixed(v % 1000 == 0 ? 0 : 1)}K'
      : v.toStringAsFixed(0);
  final currency = (j['job_currency'] as String?) ?? '';
  final period = switch ('${j['job_salary_period'] ?? ''}'.toUpperCase()) {
    'YEAR' => ' / year',
    'MONTH' => ' / month',
    'WEEK' => ' / week',
    'HOUR' => ' / hour',
    _ => '',
  };
  final range = min != null && max != null && min != max
      ? '${k(min)} – ${k(max)}'
      : k((min ?? max)!);
  return '${currency.isEmpty ? '' : '$currency '}$range$period';
}

/// `JobSummaryOut` / `JobOut` → [JobSummary].
JobSummary jobSummaryFromApi(Map<String, Object?> j, {int? matchScore}) {
  final country = (j['job_country'] as String?)?.toUpperCase();
  final location =
      (j['job_location'] as String?) ??
      [
        j['job_city'],
        j['job_state'],
        j['job_country'],
      ].whereType<String>().where((s) => s.isNotEmpty).join(', ');
  final remote = j['job_is_remote'] == true;
  final internal =
      j['is_external'] == false ||
      '${j['source']}'.toLowerCase() == 'sharkhire';
  return JobSummary(
    id: '${j['id']}',
    title: (j['job_title'] as String?) ?? 'Untitled job',
    companyName: (j['employer_name'] as String?) ?? 'Company',
    location: location.isEmpty
        ? (remote ? 'Remote' : 'Location not listed')
        : location,
    source: internal ? JobSource.internal : JobSource.external,
    workMode: remote ? WorkMode.remote : WorkMode.onsite,
    employmentType: employmentTypeFromApi(
      j['job_employment_type'] ??
          (j['job_employment_types'] as List?)?.firstOrNull,
    ),
    postedAt:
        apiDate(j['job_posted_at']) ??
        apiDate(j['created_at']) ??
        DateTime.now(),
    isInternational: country != null && country != 'PK',
    salaryLabel: salaryLabelFromApi(j),
    matchScore: matchScore,
  );
}

// ── User ────────────────────────────────────────────────────────────────────

/// `MeOut` + `ProfileOut` → [AppUser].
AppUser appUserFromApi(
  Map<String, Object?> me,
  Map<String, Object?>? profile, {
  bool hasCv = false,
}) {
  final p = profile ?? const <String, Object?>{};
  final location =
      (p['location'] as String?) ??
      [
        p['city'],
        p['country'],
      ].whereType<String>().where((s) => s.isNotEmpty).join(', ');
  return AppUser(
    fullName: (p['full_name'] as String?) ?? (me['full_name'] as String?) ?? '',
    email: (me['email'] as String?) ?? (p['email'] as String?) ?? '',
    roles: {appRoleFromApi(me['role'] ?? p['role'])},
    headline: (p['headline'] as String?) ?? (p['current_job_title'] as String?),
    location: location.isEmpty ? null : location,
    phone: p['phone'] as String?,
    profileCompletion:
        ((p['profile_completion'] as num?)?.toDouble() ?? 0) / 100,
    hasCv: hasCv,
  );
}

/// [AppUser] edits → `ProfilePatch`.
Map<String, Object?> profilePatchToApi(AppUser u) => {
  'full_name': u.fullName,
  'headline': u.headline,
  'phone': u.phone,
  'location': u.location,
};
