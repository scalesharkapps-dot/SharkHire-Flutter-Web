import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/models/job_summary.dart';
import '../../../job_search/presentation/providers/explore_providers.dart';

/// Most recently posted jobs.
final recentJobsProvider = Provider<AsyncValue<List<JobSummary>>>((ref) {
  return ref.watch(allJobsProvider).whenData((jobs) {
    final sorted = [...jobs]..sort((a, b) => b.postedAt.compareTo(a.postedAt));
    return sorted.take(3).toList();
  });
});
