import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/models/job_summary.dart';
import '../../../job_search/presentation/providers/explore_providers.dart';

// CV-based recommendations (guide §3.5). The backend calculates the match
// scores (`GET /api/v1/job-matches`); the app ranks and presents them.

/// Top CV matches (highest match score first), shown on Home (highest match score first).
final recommendedJobsProvider = Provider<AsyncValue<List<JobSummary>>>((ref) {
  return ref.watch(allJobsProvider).whenData((jobs) {
    final sorted = [...jobs]
      ..sort((a, b) => (b.matchScore ?? 0).compareTo(a.matchScore ?? 0));
    return sorted.take(4).toList();
  });
});

/// Number of strong (80%+) matches – shown in the Home header.
final strongMatchCountProvider = Provider<int>((ref) {
  final jobs = ref.watch(allJobsProvider).value ?? const [];
  return jobs.where((j) => (j.matchScore ?? 0) >= 80).length;
});
