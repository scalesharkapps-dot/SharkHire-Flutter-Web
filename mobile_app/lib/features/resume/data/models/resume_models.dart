import 'package:flutter/foundation.dart';

import '../../../../shared/models/domain_enums.dart';

/// A CV file chosen on the device, before upload.
@immutable
class PickedCvFile {
  const PickedCvFile({
    required this.name,
    required this.sizeBytes,
    this.bytes,
    this.path,
  });

  final String name;
  final int sizeBytes;
  final Uint8List? bytes;
  final String? path;

  String get extension =>
      name.contains('.') ? name.split('.').last.toLowerCase() : '';
}

/// Rules for accepted CV files (guide §3.12: strict type and size checks).
abstract final class CvRules {
  static const allowedExtensions = ['pdf', 'docx'];
  static const maxSizeBytes = 5 * 1024 * 1024;
  static const maxSizeLabel = '5 MB';

  /// Returns a message describing the problem, or null if the file is OK.
  static String? validate(PickedCvFile file) {
    if (!allowedExtensions.contains(file.extension)) {
      return '"${file.name}" isn\'t a PDF or DOCX file. Save your CV as PDF or Word (.docx) and try again.';
    }
    if (file.sizeBytes <= 0) {
      return 'This file looks empty. Choose another copy of your CV.';
    }
    if (file.sizeBytes > maxSizeBytes) {
      return 'This file is ${formatSize(file.sizeBytes)}. CVs must be $maxSizeLabel or smaller.';
    }
    return null;
  }

  static String formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

/// An uploaded CV. Mirrors the `resumes` table (Appendix A).
@immutable
class Resume {
  const Resume({
    required this.id,
    required this.fileName,
    required this.sizeBytes,
    required this.uploadedAt,
    this.status = ResumeStatus.uploaded,
    this.isActive = true,
  });

  final String id;
  final String fileName;
  final int sizeBytes;
  final DateTime uploadedAt;
  final ResumeStatus status;
  final bool isActive;

  Resume copyWith({ResumeStatus? status, bool? isActive}) => Resume(
    id: id,
    fileName: fileName,
    sizeBytes: sizeBytes,
    uploadedAt: uploadedAt,
    status: status ?? this.status,
    isActive: isActive ?? this.isActive,
  );
}

/// `candidate_experience`
@immutable
class ExperienceEntry {
  const ExperienceEntry({
    required this.jobTitle,
    this.organization,
    this.period,
    this.description,
  });

  final String jobTitle;
  final String? organization;
  final String? period;
  final String? description;
}

/// `candidate_education`
@immutable
class EducationEntry {
  const EducationEntry({
    required this.qualification,
    this.institution,
    this.period,
  });

  final String qualification;
  final String? institution;
  final String? period;
}

/// Data extracted from a CV, which the candidate reviews and corrects before
/// it is used for matching (guide §3.5).
@immutable
class ParsedProfile {
  const ParsedProfile({
    required this.fullName,
    this.email,
    this.location,
    this.jobTitles = const [],
    this.skills = const [],
    this.experience = const [],
    this.education = const [],
    this.certifications = const [],
    this.projects = const [],
    this.yearsOfExperience,
  });

  final String fullName;
  final String? email;
  final String? location;
  final List<String> jobTitles;
  final List<String> skills;
  final List<ExperienceEntry> experience;
  final List<EducationEntry> education;
  final List<String> certifications;
  final List<String> projects;

  /// Null when the CV doesn't say – treated as unknown, never as zero.
  final double? yearsOfExperience;

  ParsedProfile copyWith({
    String? fullName,
    String? location,
    List<String>? skills,
    List<ExperienceEntry>? experience,
    List<EducationEntry>? education,
    List<String>? certifications,
    List<String>? projects,
  }) => ParsedProfile(
    fullName: fullName ?? this.fullName,
    email: email,
    location: location ?? this.location,
    jobTitles: jobTitles,
    skills: skills ?? this.skills,
    experience: experience ?? this.experience,
    education: education ?? this.education,
    certifications: certifications ?? this.certifications,
    projects: projects ?? this.projects,
    yearsOfExperience: yearsOfExperience,
  );
}

/// Steps shown while a CV is processed (mockup 4.2).
enum CvProcessingStage {
  uploading('Upload and check file'),
  extracting('Read your CV'),
  building('Build your candidate profile'),
  matching('Find matching jobs'),
  done('Done');

  const CvProcessingStage(this.label);
  final String label;
}
