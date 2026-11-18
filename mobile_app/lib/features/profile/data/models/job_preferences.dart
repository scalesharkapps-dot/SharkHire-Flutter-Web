import 'package:flutter/foundation.dart';

import '../../../../shared/models/domain_enums.dart';

/// Job seeker preferences. Mirrors the `job_preferences` table (Appendix A).
@immutable
class JobPreferences {
  const JobPreferences({
    this.includePakistan = true,
    this.includeInternational = true,
    this.categories = const {},
    this.employmentTypes = const {},
    this.workModes = const {},
    this.experienceLevel = ExperienceLevel.any,
  });

  final bool includePakistan;
  final bool includeInternational;
  final Set<String> categories;
  final Set<EmploymentType> employmentTypes;
  final Set<WorkMode> workModes;
  final ExperienceLevel experienceLevel;

  static const List<String> allCategories = [
    'Software',
    'Data / AI',
    'Design',
    'Marketing',
    'Finance',
    'Operations',
    'Sales',
    'Customer support',
  ];

  bool get isValid =>
      (includePakistan || includeInternational) && categories.isNotEmpty;

  JobPreferences copyWith({
    bool? includePakistan,
    bool? includeInternational,
    Set<String>? categories,
    Set<EmploymentType>? employmentTypes,
    Set<WorkMode>? workModes,
    ExperienceLevel? experienceLevel,
  }) => JobPreferences(
    includePakistan: includePakistan ?? this.includePakistan,
    includeInternational: includeInternational ?? this.includeInternational,
    categories: categories ?? this.categories,
    employmentTypes: employmentTypes ?? this.employmentTypes,
    workModes: workModes ?? this.workModes,
    experienceLevel: experienceLevel ?? this.experienceLevel,
  );
}
