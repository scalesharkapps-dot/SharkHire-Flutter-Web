import '../../../../shared/models/domain_enums.dart';
import '../../../../shared/models/json_mappers.dart';
import 'resume_models.dart';

/// `POST /api/v1/resumes/upload` response and `GET /api/v1/resumes/me` item.
///
/// ```json
/// {"id": "uuid", "original_filename": "cv.pdf", "file_size_bytes": 240000,
///  "status": "processing", "is_active": true, "uploaded_at": "…"}
/// ```
Resume resumeFromJson(Map<String, Object?> j) => Resume(
  id: '${j['id']}',
  fileName: j['original_filename'] as String? ?? 'CV',
  sizeBytes: (j['file_size_bytes'] as num?)?.toInt() ?? 0,
  uploadedAt: parseDate(j['uploaded_at']) ?? DateTime.now(),
  status: ApiEnum.parse(
    ResumeStatus.values,
    j['status'] as String?,
    fallback: ResumeStatus.uploaded,
  )!,
  isActive: j['is_active'] as bool? ?? true,
);

/// `GET /api/v1/resumes/{id}/parsed` – extracted candidate data
/// (`candidate_skills`, `candidate_experience`, `candidate_education`).
///
/// ```json
/// {
///   "full_name": "…", "email": "…", "location": "Lahore, Pakistan",
///   "job_titles": ["Flutter Developer"], "skills": ["Flutter", "Dart"],
///   "years_of_experience": 2,
///   "experience": [{"job_title": "…", "organization": "…", "period": "…", "description": "…"}],
///   "education": [{"qualification": "…", "institution": "…", "period": "…"}],
///   "certifications": ["…"], "projects": ["…"]
/// }
/// ```
ParsedProfile parsedProfileFromJson(Map<String, Object?> j) => ParsedProfile(
  fullName: j['full_name'] as String? ?? '',
  email: j['email'] as String?,
  location: j['location'] as String?,
  jobTitles: stringList(j['job_titles']),
  skills: stringList(j['skills']),
  yearsOfExperience: (j['years_of_experience'] as num?)?.toDouble(),
  experience: [
    for (final e in (j['experience'] as List? ?? const []))
      if (e is Map<String, Object?>)
        ExperienceEntry(
          jobTitle: e['job_title'] as String? ?? '',
          organization: e['organization'] as String?,
          period: e['period'] as String?,
          description: e['description'] as String?,
        ),
  ],
  education: [
    for (final e in (j['education'] as List? ?? const []))
      if (e is Map<String, Object?>)
        EducationEntry(
          qualification: e['qualification'] as String? ?? '',
          institution: e['institution'] as String?,
          period: e['period'] as String?,
        ),
  ],
  certifications: stringList(j['certifications']),
  projects: stringList(j['projects']),
);

/// Body for saving the candidate's corrections.
Map<String, Object?> parsedProfileToJson(ParsedProfile p) => {
  'full_name': p.fullName,
  'location': p.location,
  'skills': p.skills,
  'experience': [
    for (final e in p.experience)
      {
        'job_title': e.jobTitle,
        'organization': e.organization,
        'period': e.period,
        'description': e.description,
      },
  ],
  'education': [
    for (final e in p.education)
      {
        'qualification': e.qualification,
        'institution': e.institution,
        'period': e.period,
      },
  ],
  'certifications': p.certifications,
  'projects': p.projects,
};
