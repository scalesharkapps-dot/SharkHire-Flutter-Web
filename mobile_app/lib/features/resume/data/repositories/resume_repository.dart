import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_config.dart';
import '../../../../core/network/http_api_client.dart';
import '../../../../shared/models/app_user.dart';
import '../models/resume_models.dart';
import 'api_resume_repository.dart';
import 'mock_resume_repository.dart';

export 'mock_resume_repository.dart';

/// CV upload and extraction contract (`/api/v1/cv/*`).
/// Parsing happens on the backend; the app uploads, follows progress and
/// sends back the candidate's corrections.
abstract interface class ResumeRepository {
  /// Uploads [file] and reports each processing stage until [CvProcessingStage.done].
  Stream<CvProcessingStage> uploadAndProcess(PickedCvFile file);

  /// Extracted data for the most recently processed CV.
  Future<ParsedProfile> fetchParsedProfile(AppUser user);

  Future<void> saveCorrections(ParsedProfile profile);

  /// The CV used for matching, or null when none is uploaded.
  Future<Resume?> fetchActive();

  Future<void> delete(String id);
}

/// Real API when configured (`ApiConfig.isConfigured`), otherwise mock data.
final resumeRepositoryProvider = Provider<ResumeRepository>(
  (ref) => ApiConfig.isConfigured
      ? ApiResumeRepository(ref.watch(apiClientProvider))
      : const MockResumeRepository(),
);
