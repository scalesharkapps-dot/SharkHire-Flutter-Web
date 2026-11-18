import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_config.dart';
import '../../../../shared/models/job_summary.dart';
import '../../../authentication/presentation/providers/session_provider.dart';
import '../../../job_search/presentation/providers/explore_providers.dart';
import '../../data/repositories/saved_jobs_repository.dart';

/// IDs of jobs the user has bookmarked. With the real API they are loaded
/// after sign-in and every change is sent to `/api/v1/saved-jobs`.
class SavedJobIdsNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() {
    final email = ref.watch(sessionProvider.select((s) => s.user?.email));
    if (email != null && ApiConfig.isConfigured) {
      Future.microtask(() async {
        try {
          final jobs = await ref.read(savedJobsRepositoryProvider).list();
          if (ref.mounted) state = {for (final j in jobs) j.id};
        } catch (_) {
          // The Saved tab shows its own error state with Retry.
        }
      });
    }
    return <String>{};
  }

  /// Saves or unsaves immediately; reverts if the server rejects it.
  Future<void> toggle(String jobId) async {
    final wasSaved = state.contains(jobId);
    state = wasSaved ? ({...state}..remove(jobId)) : {...state, jobId};
    if (!ApiConfig.isConfigured) return;
    try {
      final repo = ref.read(savedJobsRepositoryProvider);
      wasSaved ? await repo.remove(jobId) : await repo.save(jobId);
    } catch (_) {
      if (ref.mounted) {
        state = wasSaved ? {...state, jobId} : ({...state}..remove(jobId));
      }
    }
  }

  Future<void> remove(String jobId) async {
    if (state.contains(jobId)) await toggle(jobId);
  }
}

final savedJobIdsProvider = NotifierProvider<SavedJobIdsNotifier, Set<String>>(
  SavedJobIdsNotifier.new,
);

/// Saved jobs from the server (real API only); reloads when the set changes.
final remoteSavedJobsProvider = FutureProvider<List<JobSummary>>((ref) {
  ref.watch(savedJobIdsProvider);
  return ref.watch(savedJobsRepositoryProvider).list();
});

/// Saved jobs resolved to full summaries, most recently saved first.
final savedJobsProvider = Provider<AsyncValue<List<JobSummary>>>((ref) {
  final ids = ref.watch(savedJobIdsProvider);
  if (ApiConfig.isConfigured) {
    return ref
        .watch(remoteSavedJobsProvider)
        .whenData(
          (jobs) => [
            for (final j in jobs)
              if (ids.contains(j.id)) j,
          ],
        );
  }
  final ordered = ids.toList().reversed.toList();
  return ref.watch(allJobsProvider).whenData((jobs) {
    final byId = {for (final j in jobs) j.id: j};
    return [
      for (final id in ordered)
        if (byId[id] != null) byId[id]!,
    ];
  });
});
