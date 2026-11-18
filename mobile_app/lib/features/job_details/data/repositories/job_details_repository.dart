import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_config.dart';
import '../../../../core/network/http_api_client.dart';
import '../../../job_search/data/repositories/jobs_repository.dart';
import '../models/job_details.dart';
import 'api_job_details_repository.dart';
import 'mock_job_details_repository.dart';

export 'mock_job_details_repository.dart';

/// Loads full job details (`GET /api/v1/jobs/{id}`). External applications
/// open the employer site; the app records them with `POST /applications`.
abstract interface class JobDetailsRepository {
  Future<JobDetails> fetch(String jobId);
  Future<void> recordExternalApplyClick(String jobId);
}

class JobNotFound implements Exception {
  const JobNotFound();
}

/// Real API when configured (`ApiConfig.isConfigured`), otherwise mock data.
final jobDetailsRepositoryProvider = Provider<JobDetailsRepository>(
  (ref) => ApiConfig.isConfigured
      ? ApiJobDetailsRepository(ref.watch(apiClientProvider))
      : MockJobDetailsRepository(ref.watch(jobsRepositoryProvider)),
);

final jobDetailsProvider = FutureProvider.family<JobDetails, String>(
  (ref, id) => ref.watch(jobDetailsRepositoryProvider).fetch(id),
);
