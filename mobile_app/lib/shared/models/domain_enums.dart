/// Shared domain enums.
///
/// Each `apiValue` mirrors a PostgreSQL enum value from the backend schema
/// (project guide, Appendix A), so API JSON maps to these types directly via
/// [ApiEnum.parse]. Frontend-only labels live alongside for display.
library;

/// Common shape of enums that round-trip to the API.
abstract interface class ApiEnum {
  String get apiValue;
  String get label;

  /// Parses [raw] (as sent by the API) into one of [values].
  /// Unknown or null values return [fallback], so a new backend value
  /// never crashes the app.
  static T? parse<T extends ApiEnum>(
    List<T> values,
    String? raw, {
    T? fallback,
  }) {
    if (raw == null) return fallback;
    for (final v in values) {
      if (v.apiValue == raw) return v;
    }
    return fallback;
  }
}

/// `public.app_role`
enum AppRole implements ApiEnum {
  jobSeeker('job_seeker', 'Job seeker'),
  employer('employer', 'Employer'),
  admin('admin', 'Admin');

  const AppRole(this.apiValue, this.label);
  @override
  final String apiValue;
  @override
  final String label;
}

/// `public.resume_status`
enum ResumeStatus implements ApiEnum {
  uploaded('uploaded', 'Uploaded'),
  processing('processing', 'Processing'),
  processed('processed', 'Processed'),
  failed('failed', 'Failed');

  const ResumeStatus(this.apiValue, this.label);
  @override
  final String apiValue;
  @override
  final String label;
}

/// `public.experience_level`
enum ExperienceLevel implements ApiEnum {
  internship('internship', 'Internship'),
  entry('entry', 'Entry'),
  junior('junior', 'Junior'),
  mid('mid', 'Mid'),
  senior('senior', 'Senior'),
  lead('lead', 'Lead'),
  executive('executive', 'Executive'),
  any('any', 'All levels');

  const ExperienceLevel(this.apiValue, this.label);
  @override
  final String apiValue;
  @override
  final String label;
}

/// `public.work_mode`
enum WorkMode implements ApiEnum {
  remote('remote', 'Remote'),
  hybrid('hybrid', 'Hybrid'),
  onsite('onsite', 'On-site');

  const WorkMode(this.apiValue, this.label);
  @override
  final String apiValue;
  @override
  final String label;
}

/// `public.employment_type`
enum EmploymentType implements ApiEnum {
  fullTime('full_time', 'Full-time'),
  partTime('part_time', 'Part-time'),
  contract('contract', 'Contract'),
  internship('internship', 'Internship'),
  temporary('temporary', 'Temporary'),
  freelance('freelance', 'Freelance');

  const EmploymentType(this.apiValue, this.label);
  @override
  final String apiValue;
  @override
  final String label;
}

/// `public.job_status` – lifecycle of employer-posted (internal) jobs.
/// New jobs start as [pending] until an admin approves them (guide §3.6).
enum JobStatus implements ApiEnum {
  draft('draft', 'Draft'),
  pending('pending', 'Pending approval'),
  approved('approved', 'Published'),
  rejected('rejected', 'Rejected'),
  closed('closed', 'Closed'),
  expired('expired', 'Expired');

  const JobStatus(this.apiValue, this.label);
  @override
  final String apiValue;
  @override
  final String label;
}

/// `public.application_status`
enum ApplicationStatus implements ApiEnum {
  submitted('submitted', 'Submitted'),
  underReview('under_review', 'Under review'),
  shortlisted('shortlisted', 'Shortlisted'),
  interview('interview', 'Interview'),
  rejected('rejected', 'Rejected'),
  accepted('accepted', 'Accepted'),
  withdrawn('withdrawn', 'Withdrawn');

  const ApplicationStatus(this.apiValue, this.label);
  @override
  final String apiValue;
  @override
  final String label;
}

/// Where a job listing comes from. Not a database enum: the backend keeps
/// internal jobs (`jobs`) and external jobs (`external_job_cache`) in
/// separate tables, and the app tags each listing with its origin.
enum JobSource {
  /// From the external job provider (JSearch); applying opens the original
  /// link and the app only records the click (`external_apply_clicks`).
  external('External'),

  /// Posted by a registered SharkHire employer; candidates apply in-app.
  internal('Internal');

  const JobSource(this.label);
  final String label;
}
