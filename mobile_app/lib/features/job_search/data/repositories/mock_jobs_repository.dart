import '../../../../shared/models/job_summary.dart';
import '../mock_jobs.dart';
import '../city_match.dart';
import 'jobs_repository.dart';

/// MOCK – local example data with a small delay so loading states are
/// visible during development. Not used when the API is configured.
class MockJobsRepository implements JobsRepository {
  const MockJobsRepository();

  @override
  Future<List<JobSummary>> fetchJobs() async {
    await Future<void>.delayed(MockJobs.latency);
    return MockJobs.all();
  }

  @override
  Future<List<JobSummary>> search(
    String query, {
    String? city,
    bool remoteOnly = false,
  }) async {
    final q = query.trim().toLowerCase();
    final all = await fetchJobs();
    return [
      for (final j in all)
        if ((j.title.toLowerCase().contains(q) ||
                j.companyName.toLowerCase().contains(q) ||
                j.location.toLowerCase().contains(q) ||
                (j.category?.toLowerCase().contains(q) ?? false)) &&
            (city == null || jobInCity(j, city)) &&
            (!remoteOnly || j.workMode == WorkMode.remote))
          j,
    ];
  }
}
