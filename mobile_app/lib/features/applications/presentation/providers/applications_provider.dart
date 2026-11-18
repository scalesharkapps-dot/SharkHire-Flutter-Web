import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_config.dart';
import '../../../authentication/presentation/providers/session_provider.dart';
import '../../../job_search/data/mock_jobs.dart';
import '../../../resume/presentation/providers/cv_provider.dart';
import '../../../../shared/models/job_summary.dart';
import '../../data/models/application.dart';
import '../../data/repositories/applications_repository.dart';

/// Loading state of the applications list (real API only).
class ApplicationsLoad extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  void set(AsyncValue<void> v) => state = v;
}

final applicationsLoadProvider =
    NotifierProvider<ApplicationsLoad, AsyncValue<void>>(ApplicationsLoad.new);

/// The job seeker's applications. With the real API they come from
/// `GET /api/v1/applications`; in development a few examples are shown.
class ApplicationsController extends Notifier<List<JobApplication>> {
  ApplicationsRepository get _repo => ref.read(applicationsRepositoryProvider);

  @override
  List<JobApplication> build() {
    if (!ApiConfig.isConfigured) return _seed();
    final email = ref.watch(sessionProvider.select((s) => s.user?.email));
    if (email != null) Future.microtask(reload);
    return const [];
  }

  /// Loads the list from the server (real API only).
  Future<void> reload() async {
    if (!ApiConfig.isConfigured) return;
    final load = ref.read(applicationsLoadProvider.notifier);
    load.set(const AsyncLoading());
    try {
      final apps = await _repo.list();
      if (!ref.mounted) return;
      state = apps;
      load.set(const AsyncData(null));
    } catch (e, st) {
      if (ref.mounted) load.set(AsyncError(e, st));
    }
  }

  JobApplication? forJob(String jobId) => state
      .where(
        (a) => a.job.id == jobId && a.status != ApplicationStatus.withdrawn,
      )
      .firstOrNull;

  JobApplication? byId(String id) => state.where((a) => a.id == id).firstOrNull;

  /// Submits an application (`POST /api/v1/applications`).
  Future<JobApplication> apply(
    JobSummary job, {
    String? cvFileName,
    String? coverLetter,
  }) async {
    final letter = (coverLetter?.trim().isEmpty ?? true)
        ? null
        : coverLetter!.trim();
    final JobApplication app;
    if (ApiConfig.isConfigured) {
      final cv = ref.read(cvProvider).active;
      final created = await _repo.apply(job, cvId: cv?.id, coverLetter: letter);
      app = JobApplication(
        id: created.id,
        job: created.job,
        history: created.history,
        cvFileName: cv?.fileName ?? cvFileName,
        coverLetter: created.coverLetter ?? letter,
      );
    } else {
      await Future<void>.delayed(const Duration(milliseconds: 800));
      app = JobApplication(
        id: 'app-${DateTime.now().millisecondsSinceEpoch}',
        job: job,
        cvFileName: cvFileName,
        coverLetter: letter,
        history: [StatusChange(ApplicationStatus.submitted, DateTime.now())],
      );
    }
    state = [app, ...state];
    return app;
  }

  /// Withdraws an application (`PATCH /api/v1/applications/{id}/status`).
  Future<void> withdraw(String id) async {
    if (ApiConfig.isConfigured) {
      final updated = await _repo.withdraw(id);
      state = [
        for (final a in state)
          a.id == id
              ? JobApplication(
                  id: a.id,
                  job: a.job,
                  history: updated.history,
                  cvFileName: a.cvFileName,
                  coverLetter: a.coverLetter,
                )
              : a,
      ];
      return;
    }
    await Future<void>.delayed(const Duration(milliseconds: 500));
    state = [
      for (final a in state)
        a.id == id
            ? a.withStatus(
                ApplicationStatus.withdrawn,
                note: 'Withdrawn by you',
              )
            : a,
    ];
  }

  static List<JobApplication> _seed() {
    final jobs = {for (final j in MockJobs.all()) j.id: j};
    final now = DateTime.now();
    DateTime ago(int d, [int h = 0]) =>
        now.subtract(Duration(days: d, hours: h));

    final qa = JobSummary(
      id: 'job-90',
      title: 'QA Engineer',
      companyName: 'Harbor & Co.',
      location: 'Lahore, Pakistan',
      source: JobSource.internal,
      workMode: WorkMode.hybrid,
      employmentType: EmploymentType.fullTime,
      postedAt: ago(20),
      category: 'Software',
      matchScore: 81,
    );

    return [
      JobApplication(
        id: 'app-3',
        job: jobs['job-05']!,
        cvFileName: 'Ayesha_Khan_CV.pdf',
        history: [
          StatusChange(ApplicationStatus.submitted, ago(6)),
          StatusChange(ApplicationStatus.underReview, ago(4)),
          StatusChange(
            ApplicationStatus.shortlisted,
            ago(1),
            note: 'The team liked your portfolio.',
          ),
        ],
      ),
      JobApplication(
        id: 'app-4',
        job: qa,
        cvFileName: 'Ayesha_Khan_CV.pdf',
        history: [
          StatusChange(ApplicationStatus.submitted, ago(14)),
          StatusChange(ApplicationStatus.underReview, ago(11)),
          StatusChange(ApplicationStatus.shortlisted, ago(8)),
          StatusChange(
            ApplicationStatus.interview,
            ago(2),
            note: 'Interview on Thursday, 3:00 PM PKT.',
          ),
        ],
      ),
      JobApplication(
        id: 'app-2',
        job: jobs['job-06']!,
        cvFileName: 'Ayesha_Khan_CV.pdf',
        history: [
          StatusChange(ApplicationStatus.submitted, ago(3)),
          StatusChange(ApplicationStatus.underReview, ago(1, 3)),
        ],
      ),
      JobApplication(
        id: 'app-1',
        job: jobs['job-08']!,
        cvFileName: 'Ayesha_Khan_CV.pdf',
        history: [
          StatusChange(ApplicationStatus.submitted, ago(18)),
          StatusChange(ApplicationStatus.underReview, ago(15)),
          StatusChange(
            ApplicationStatus.rejected,
            ago(10),
            note: 'The role was filled internally.',
          ),
        ],
      ),
    ];
  }
}

final applicationsProvider =
    NotifierProvider<ApplicationsController, List<JobApplication>>(
      ApplicationsController.new,
    );

/// IDs of external jobs whose apply link the user opened
/// (`external_apply_clicks`). Not an application – just the click.
class ExternalApplyClicks extends Notifier<Set<String>> {
  @override
  Set<String> build() => {};

  void record(String jobId) => state = {...state, jobId};
}

final externalApplyClicksProvider =
    NotifierProvider<ExternalApplyClicks, Set<String>>(ExternalApplyClicks.new);
