import 'package:flutter/foundation.dart';

import 'domain_enums.dart';

export 'domain_enums.dart';

/// Lightweight job model used by lists and cards.
/// The full job details model will live in `features/job_details`.
@immutable
class JobSummary {
  const JobSummary({
    required this.id,
    required this.title,
    required this.companyName,
    required this.location,
    required this.source,
    required this.workMode,
    required this.employmentType,
    required this.postedAt,
    this.isInternational = false,
    this.category,
    this.companyRating,
    this.salaryLabel,
    this.matchScore,
  });

  final String id;
  final String title;
  final String companyName;
  final String location;
  final JobSource source;
  final WorkMode workMode;
  final EmploymentType employmentType;
  final DateTime postedAt;

  /// `true` for jobs outside Pakistan (used by the region filter).
  final bool isInternational;

  /// Display category, e.g. "Software" or "Data / AI".
  final String? category;
  final double? companyRating;

  /// Pre-formatted salary text, e.g. "PKR 250K – 350K / month".
  final String? salaryLabel;

  /// CV match score between 0 and 100, calculated by the backend.
  final int? matchScore;

  bool get isInternal => source == JobSource.internal;
}
