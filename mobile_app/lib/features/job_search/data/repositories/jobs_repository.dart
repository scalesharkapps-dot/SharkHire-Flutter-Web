import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_config.dart';
import '../../../../core/network/http_api_client.dart';
import '../../../../shared/models/job_summary.dart';
import 'api_jobs_repository.dart';
import 'mock_jobs_repository.dart';

export 'mock_jobs_repository.dart';

/// Source of job listings for the app. Screens depend only on this interface.
///
/// * [ApiJobsRepository] – real backend (`/api/v1/jobs/*`,
///   `/api/v1/recommendations/for-me`).
/// * [MockJobsRepository] – local example data for development.
abstract interface class JobsRepository {
  /// Jobs shown before the user searches (Home, Explore).
  Future<List<JobSummary>> fetchJobs();

  /// Jobs matching [query] (Explore search box), optionally only in [city]
  /// and only remote ones ([remoteOnly], a Pro feature). [query] may be
  /// empty when only a city or remote is chosen.
  Future<List<JobSummary>> search(
    String query, {
    String? city,
    bool remoteOnly = false,
  });
}

/// Uses the real API when the app is built with an API URL and mock data
/// switched off (see `ApiConfig.isConfigured`); otherwise mock data.
final jobsRepositoryProvider = Provider<JobsRepository>(
  (ref) => ApiConfig.isConfigured
      ? ApiJobsRepository(ref.watch(apiClientProvider))
      : const MockJobsRepository(),
);
