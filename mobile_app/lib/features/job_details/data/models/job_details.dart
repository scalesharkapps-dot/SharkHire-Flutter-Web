import 'package:flutter/foundation.dart';

import '../../../../shared/models/job_summary.dart';

/// Full job information for the details screen.
///
/// Internal jobs come from `jobs` + `job_skills`; external jobs come from
/// `external_job_cache`. Match data comes from `job_matches`.
@immutable
class JobDetails {
  const JobDetails({
    required this.summary,
    required this.description,
    this.responsibilities = const [],
    this.requirements = const [],
    this.requiredSkills = const [],
    this.matchReasons = const [],
    this.experienceLevel,
    this.education,
    this.vacancies,
    this.deadline,
    this.applicationInstructions,
    this.applyUrl,
    this.publisher,
    this.lastCheckedAt,
    this.companyAbout,
    this.verifiedEmployer = false,
  });

  final JobSummary summary;
  final String description;
  final List<String> responsibilities;
  final List<String> requirements;
  final List<String> requiredSkills;

  /// Plain-language reasons from the matching engine,
  /// e.g. "Your Flutter and Dart skills match this role".
  final List<String> matchReasons;

  final ExperienceLevel? experienceLevel;
  final String? education;
  final int? vacancies;
  final DateTime? deadline;
  final String? applicationInstructions;

  /// External jobs only: the original application link.
  final String? applyUrl;

  /// External jobs only: the site that published the listing.
  final String? publisher;

  /// External jobs only: when the listing was last refreshed.
  final DateTime? lastCheckedAt;

  final String? companyAbout;
  final bool verifiedEmployer;

  String get id => summary.id;
  bool get isInternal => summary.isInternal;
}
