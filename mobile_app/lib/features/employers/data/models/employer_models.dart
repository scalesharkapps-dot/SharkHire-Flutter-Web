import 'package:flutter/foundation.dart';

import '../../../../shared/models/domain_enums.dart';

/// An employer's job post. Mirrors `jobs` + `job_skills` (Appendix A).
@immutable
class EmployerJob {
  const EmployerJob({
    required this.id,
    required this.title,
    required this.location,
    required this.workMode,
    required this.employmentType,
    required this.status,
    required this.createdAt,
    this.description = '',
    this.requiredSkills = const [],
    this.experienceLevel = ExperienceLevel.any,
    this.education,
    this.salaryMin,
    this.salaryMax,
    this.salaryCurrency = 'PKR',
    this.deadline,
    this.vacancies = 1,
    this.instructions,
    this.rejectionReason,
    this.views = 0,
  });

  final String id;
  final String title;
  final String location;
  final WorkMode workMode;
  final EmploymentType employmentType;
  final JobStatus status;
  final DateTime createdAt;
  final String description;
  final List<String> requiredSkills;
  final ExperienceLevel experienceLevel;
  final String? education;
  final int? salaryMin;
  final int? salaryMax;
  final String salaryCurrency;
  final DateTime? deadline;
  final int vacancies;
  final String? instructions;

  /// Admin's reason when [status] is rejected.
  final String? rejectionReason;
  final int views;

  bool get isOpen => status == JobStatus.approved;

  String? get salaryLabel {
    if (salaryMin == null && salaryMax == null) return null;
    String k(int v) => v >= 1000 ? '${(v / 1000).round()}K' : '$v';
    if (salaryMin != null && salaryMax != null) {
      return '$salaryCurrency ${k(salaryMin!)} – ${k(salaryMax!)}';
    }
    return '$salaryCurrency ${k((salaryMin ?? salaryMax)!)}';
  }

  EmployerJob copyWith({JobStatus? status, String? rejectionReason}) =>
      EmployerJob(
        id: id,
        title: title,
        location: location,
        workMode: workMode,
        employmentType: employmentType,
        status: status ?? this.status,
        createdAt: createdAt,
        description: description,
        requiredSkills: requiredSkills,
        experienceLevel: experienceLevel,
        education: education,
        salaryMin: salaryMin,
        salaryMax: salaryMax,
        salaryCurrency: salaryCurrency,
        deadline: deadline,
        vacancies: vacancies,
        instructions: instructions,
        rejectionReason: rejectionReason,
        views: views,
      );
}

/// A candidate who applied to one of the employer's jobs. Employers only see
/// candidates who applied (guide §3.6, §3.12).
@immutable
class Applicant {
  const Applicant({
    required this.id,
    required this.name,
    required this.jobId,
    required this.jobTitle,
    required this.status,
    required this.appliedAt,
    this.headline,
    this.location,
    this.skills = const [],
    this.experienceSummary,
    this.education,
    this.cvFileName,
    this.coverLetter,
    this.matchScore,
    this.notes = const [],
  });

  final String id;
  final String name;
  final String jobId;
  final String jobTitle;
  final ApplicationStatus status;
  final DateTime appliedAt;
  final String? headline;
  final String? location;
  final List<String> skills;
  final String? experienceSummary;
  final String? education;
  final String? cvFileName;
  final String? coverLetter;
  final int? matchScore;

  /// Private employer notes (`applications.employer_notes`).
  final List<String> notes;

  String get initials {
    final parts = name.split(' ').where((p) => p.isNotEmpty).take(2);
    return parts.map((p) => p[0].toUpperCase()).join();
  }

  Applicant copyWith({ApplicationStatus? status, List<String>? notes}) =>
      Applicant(
        id: id,
        name: name,
        jobId: jobId,
        jobTitle: jobTitle,
        status: status ?? this.status,
        appliedAt: appliedAt,
        headline: headline,
        location: location,
        skills: skills,
        experienceSummary: experienceSummary,
        education: education,
        cvFileName: cvFileName,
        coverLetter: coverLetter,
        matchScore: matchScore,
        notes: notes ?? this.notes,
      );
}

enum VerificationStatus { pending, verified, rejected }

/// Mirrors `companies`.
@immutable
class Company {
  const Company({
    required this.name,
    this.website,
    this.industry,
    this.companySize,
    this.headquarters,
    this.description,
    this.verification = VerificationStatus.pending,
  });

  final String name;
  final String? website;
  final String? industry;
  final String? companySize;
  final String? headquarters;
  final String? description;
  final VerificationStatus verification;

  Company copyWith({
    String? name,
    String? website,
    String? industry,
    String? companySize,
    String? headquarters,
    String? description,
  }) => Company(
    name: name ?? this.name,
    website: website ?? this.website,
    industry: industry ?? this.industry,
    companySize: companySize ?? this.companySize,
    headquarters: headquarters ?? this.headquarters,
    description: description ?? this.description,
    verification: verification,
  );
}
