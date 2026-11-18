import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../shared/models/app_user.dart';
import '../../../../shared/models/backend_json.dart';
import '../../../../shared/models/domain_enums.dart';
import '../models/resume_models.dart';
import 'resume_repository.dart';

/// REAL – CVs through `/api/v1/cv/*`. The server extracts the CV while the
/// upload request runs, so there is nothing to poll.
class ApiResumeRepository implements ResumeRepository {
  ApiResumeRepository(this._api);

  final ApiClient _api;
  String? _activeId;

  /// Raw experience/education from the server, so corrections keep dates
  /// that the review screen doesn't edit.
  List<Map<String, Object?>> _rawExperience = const [];
  List<Map<String, Object?>> _rawEducation = const [];

  static String _mime(String ext) => ext == 'pdf'
      ? 'application/pdf'
      : 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';

  @override
  Stream<CvProcessingStage> uploadAndProcess(PickedCvFile file) async* {
    yield CvProcessingStage.uploading;
    final cv =
        await _api.upload(
              ApiEndpoints.cvUpload,
              UploadFile(
                fieldName: 'file',
                fileName: file.name,
                bytes: file.bytes,
                path: file.path,
                contentType: _mime(file.extension),
              ),
            )
            as Map<String, Object?>;
    yield CvProcessingStage.extracting;
    switch (cv['processing_status']) {
      case 'completed':
        break;
      case 'no_text' || 'ocr_required':
        throw const ValidationException(
          'We couldn\'t find readable text in this CV. Upload a PDF or Word '
          'file that contains text (not a scanned image).',
        );
      default:
        throw ValidationException(
          (cv['extraction_error'] as String?) ??
              'We couldn\'t read this CV. Try a different PDF or DOCX file.',
        );
    }
    final id = '${cv['id']}';
    _activeId = id;
    yield CvProcessingStage.building;
    // A new upload replaces the CV used for matching.
    if (cv['is_primary'] != true) {
      await _api.post(ApiEndpoints.cvPrimary(id));
    }
    yield CvProcessingStage.matching;
    yield CvProcessingStage.done;
  }

  @override
  Future<Resume?> fetchActive() async {
    final list = apiItems(await _api.get(ApiEndpoints.cvList));
    if (list.isEmpty) return null;
    final active = list.firstWhere(
      (c) => c['is_primary'] == true,
      orElse: () => list.first,
    );
    _activeId = '${active['id']}';
    return resumeFromApi(active);
  }

  @override
  Future<void> delete(String id) async {
    await _api.delete(ApiEndpoints.cv(id));
    if (_activeId == id) _activeId = null;
  }

  Future<String> _cvId() async {
    if (_activeId != null) return _activeId!;
    final active = await fetchActive();
    if (active == null) throw const NotFoundException('Upload a CV first.');
    return active.id;
  }

  @override
  Future<ParsedProfile> fetchParsedProfile(AppUser user) async {
    final j =
        await _api.get(ApiEndpoints.cvExtractedData(await _cvId()))
            as Map<String, Object?>;
    _rawExperience = [
      for (final e in (j['work_experience'] as List? ?? const []))
        e as Map<String, Object?>,
    ];
    _rawEducation = [
      for (final e in (j['education'] as List? ?? const []))
        e as Map<String, Object?>,
    ];
    return parsedProfileFromApi(j, user);
  }

  @override
  Future<void> saveCorrections(ParsedProfile profile) async {
    final id = await _cvId();
    await _api.patch(
      ApiEndpoints.cvExtractedData(id),
      body: {
        'extracted_name': profile.fullName,
        'skills': profile.skills,
        'job_titles': profile.jobTitles,
        'certifications': [...profile.certifications, ...profile.projects],
        'years_of_experience': profile.yearsOfExperience,
        'work_experience': [
          for (final e in profile.experience) _experienceToApi(e),
        ],
        'education': [for (final e in profile.education) _educationToApi(e)],
      },
    );
    // Copy the confirmed CV data into the user's profile.
    await _api.post(
      ApiEndpoints.cvApplyToProfile(id),
      body: {'overwrite': true},
    );
  }

  Map<String, Object?> _experienceToApi(ExperienceEntry e) {
    final raw = _rawExperience.where(
      (r) => r['title'] == e.jobTitle && r['company'] == e.organization,
    );
    return {
      if (raw.isNotEmpty) ...raw.first,
      'title': e.jobTitle,
      'company': e.organization,
      'description': e.description,
    };
  }

  Map<String, Object?> _educationToApi(EducationEntry e) {
    final raw = _rawEducation.where(
      (r) =>
          r['degree'] == e.qualification && r['institution'] == e.institution,
    );
    return {
      if (raw.isNotEmpty) ...raw.first,
      'degree': e.qualification,
      'institution': e.institution,
    };
  }
}

/// `CVOut` → [Resume].
Resume resumeFromApi(Map<String, Object?> j) => Resume(
  id: '${j['id']}',
  fileName: (j['original_filename'] as String?) ?? 'CV',
  sizeBytes: (j['file_size'] as num?)?.toInt() ?? 0,
  uploadedAt: apiDate(j['created_at']) ?? DateTime.now(),
  status: switch (j['processing_status']) {
    'completed' => ResumeStatus.processed,
    'pending' => ResumeStatus.uploaded,
    'processing' => ResumeStatus.processing,
    _ => ResumeStatus.failed,
  },
  isActive: j['is_primary'] == true,
);

/// `ExtractedDataOut` → [ParsedProfile].
ParsedProfile parsedProfileFromApi(Map<String, Object?> j, AppUser user) {
  String period(Object? start, Object? end, {bool current = false}) {
    String part(Object? v) {
      final d = v is String ? DateTime.tryParse(v) : null;
      if (d != null) return '${_months[d.month - 1]} ${d.year}';
      return v == null ? '' : '$v';
    }

    final s = part(start);
    final e = current ? 'Present' : part(end);
    return [s, e].where((x) => x.isNotEmpty).join(' – ');
  }

  return ParsedProfile(
    fullName: (j['extracted_name'] as String?) ?? user.fullName,
    email: (j['extracted_email'] as String?) ?? user.email,
    location: user.location,
    jobTitles: apiStrings(j['job_titles']),
    skills: apiStrings(j['skills']),
    certifications: apiStrings(j['certifications']),
    yearsOfExperience: (j['years_of_experience'] as num?)?.toDouble(),
    experience: [
      for (final e in (j['work_experience'] as List? ?? const []))
        if (e is Map && e['title'] != null)
          ExperienceEntry(
            jobTitle: '${e['title']}',
            organization: e['company'] as String?,
            period: period(
              e['start_date'],
              e['end_date'],
              current: e['is_current'] == true,
            ).nullIfEmpty,
            description: e['description'] as String?,
          ),
    ],
    education: [
      for (final e in (j['education'] as List? ?? const []))
        if (e is Map && (e['degree'] ?? e['institution']) != null)
          EducationEntry(
            qualification:
                '${e['degree'] ?? e['field_of_study'] ?? 'Education'}',
            institution: e['institution'] as String?,
            period: period(e['start_year'], e['end_year']).nullIfEmpty,
          ),
    ],
  );
}

const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

extension on String {
  String? get nullIfEmpty => isEmpty ? null : this;
}
