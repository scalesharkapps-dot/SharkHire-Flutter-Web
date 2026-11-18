// Admin data models. They mirror the backend admin views of `profiles`,
// `companies`, `jobs`, `applications`, `external_job_cache` and
// `admin_audit_logs` (Appendix A).
import 'package:flutter/foundation.dart';

import '../../../../shared/models/domain_enums.dart';

export '../../../../shared/models/domain_enums.dart';

enum AccountStatus {
  active('Active'),
  blocked('Blocked'),
  deactivated('Deactivated');

  const AccountStatus(this.label);
  final String label;
}

enum Verification {
  pending('Pending'),
  verified('Verified'),
  rejected('Rejected');

  const Verification(this.label);
  final String label;
}

@immutable
class AdminUserRecord {
  const AdminUserRecord({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.joinedAt,
    this.status = AccountStatus.active,
    this.location,
  });

  final String id;
  final String name;
  final String email;
  final AppRole role;
  final DateTime joinedAt;
  final AccountStatus status;
  final String? location;

  AdminUserRecord withStatus(AccountStatus s) => AdminUserRecord(
    id: id,
    name: name,
    email: email,
    role: role,
    joinedAt: joinedAt,
    status: s,
    location: location,
  );
}

@immutable
class CompanyRecord {
  const CompanyRecord({
    required this.id,
    required this.name,
    required this.owner,
    required this.joinedAt,
    this.industry,
    this.website,
    this.verification = Verification.pending,
    this.jobCount = 0,
  });

  final String id;
  final String name;
  final String owner;
  final DateTime joinedAt;
  final String? industry;
  final String? website;
  final Verification verification;
  final int jobCount;

  CompanyRecord withVerification(Verification v) => CompanyRecord(
    id: id,
    name: name,
    owner: owner,
    joinedAt: joinedAt,
    industry: industry,
    website: website,
    verification: v,
    jobCount: jobCount,
  );
}

@immutable
class ModerationJob {
  const ModerationJob({
    required this.id,
    required this.title,
    required this.company,
    required this.location,
    required this.employmentType,
    required this.workMode,
    required this.submittedAt,
    required this.status,
    this.description = '',
    this.skills = const [],
    this.salaryLabel,
    this.rejectionReason,
  });

  final String id;
  final String title;
  final String company;
  final String location;
  final EmploymentType employmentType;
  final WorkMode workMode;
  final DateTime submittedAt;
  final JobStatus status;
  final String description;
  final List<String> skills;
  final String? salaryLabel;
  final String? rejectionReason;

  ModerationJob withStatus(JobStatus s, {String? reason}) => ModerationJob(
    id: id,
    title: title,
    company: company,
    location: location,
    employmentType: employmentType,
    workMode: workMode,
    submittedAt: submittedAt,
    status: s,
    description: description,
    skills: skills,
    salaryLabel: salaryLabel,
    rejectionReason: reason,
  );
}

@immutable
class ApplicationRecord {
  const ApplicationRecord({
    required this.id,
    required this.candidate,
    required this.job,
    required this.company,
    required this.status,
    required this.submittedAt,
  });

  final String id;
  final String candidate;
  final String job;
  final String company;
  final ApplicationStatus status;
  final DateTime submittedAt;
}

/// Cached JSearch listing (`external_job_cache`).
@immutable
class ExternalListing {
  const ExternalListing({
    required this.providerJobId,
    required this.title,
    required this.company,
    required this.country,
    required this.publisher,
    required this.fetchedAt,
    required this.expiresAt,
  });

  final String providerJobId;
  final String title;
  final String company;
  final String country;
  final String publisher;
  final DateTime fetchedAt;
  final DateTime expiresAt;

  bool get isStale => DateTime.now().isAfter(expiresAt);
}

@immutable
class ApiRequestLog {
  const ApiRequestLog({
    required this.at,
    required this.endpoint,
    required this.query,
    required this.statusCode,
    required this.latencyMs,
    required this.results,
  });

  final DateTime at;
  final String endpoint;
  final String query;
  final int statusCode;
  final int latencyMs;
  final int results;

  bool get ok => statusCode >= 200 && statusCode < 300;
}

/// `admin_audit_logs`
@immutable
class AuditEntry {
  const AuditEntry({
    required this.admin,
    required this.action,
    required this.entityType,
    required this.entityLabel,
    required this.at,
    this.details,
  });

  final String admin;
  final String action;
  final String entityType;
  final String entityLabel;
  final DateTime at;
  final String? details;
}

@immutable
class CategoryRecord {
  const CategoryRecord({required this.name, this.skills = const []});

  final String name;
  final List<String> skills;
}

enum Audience {
  everyone('Everyone'),
  jobSeekers('Job seekers'),
  employers('Employers');

  const Audience(this.label);
  final String label;
}

@immutable
class Announcement {
  const Announcement({
    required this.title,
    required this.message,
    required this.audience,
    required this.sentAt,
  });

  final String title;
  final String message;
  final Audience audience;
  final DateTime sentAt;
}

@immutable
class PlatformSettings {
  const PlatformSettings({
    this.requireJobApproval = true,
    this.externalListingDays = 14,
    this.cvRetentionMonths = 24,
    this.jsearchMonthlyLimit = 200,
    this.maintenanceBanner = false,
  });

  final bool requireJobApproval;
  final int externalListingDays;
  final int cvRetentionMonths;
  final int jsearchMonthlyLimit;
  final bool maintenanceBanner;

  PlatformSettings copyWith({
    bool? requireJobApproval,
    int? externalListingDays,
    int? cvRetentionMonths,
    int? jsearchMonthlyLimit,
    bool? maintenanceBanner,
  }) => PlatformSettings(
    requireJobApproval: requireJobApproval ?? this.requireJobApproval,
    externalListingDays: externalListingDays ?? this.externalListingDays,
    cvRetentionMonths: cvRetentionMonths ?? this.cvRetentionMonths,
    jsearchMonthlyLimit: jsearchMonthlyLimit ?? this.jsearchMonthlyLimit,
    maintenanceBanner: maintenanceBanner ?? this.maintenanceBanner,
  );
}
