import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_config.dart';
import '../../../../shared/models/job_summary.dart';
import '../../data/repositories/jobs_repository.dart';

/// All jobs available to the user (internal + external).
final allJobsProvider = FutureProvider<List<JobSummary>>(
  (ref) => ref.watch(jobsRepositoryProvider).fetchJobs(),
);

/// Server-side search for [query]. Waits for typing to pause so the
/// job-search quota isn't spent on every keystroke.
final jobSearchProvider = FutureProvider.autoDispose
    .family<List<JobSummary>, String>((ref, query) async {
      await Future<void>.delayed(const Duration(milliseconds: 600));
      if (!ref.mounted) return const [];
      return ref.watch(jobsRepositoryProvider).search(query);
    });

/// Quick filters shown as chips on Explore (from the project guide).
enum ExploreFilter {
  remote('Remote'),
  fullTime('Full-time'),
  partTime('Part-time'),
  contract('Contract'),
  internship('Internship'),
  pakistan('Pakistan'),
  international('International'),
  applyInApp('Apply in-app');

  const ExploreFilter(this.label);
  final String label;

  bool matches(JobSummary j) => switch (this) {
    ExploreFilter.remote => j.workMode == WorkMode.remote,
    ExploreFilter.fullTime => j.employmentType == EmploymentType.fullTime,
    ExploreFilter.partTime => j.employmentType == EmploymentType.partTime,
    ExploreFilter.contract => j.employmentType == EmploymentType.contract,
    ExploreFilter.internship => j.employmentType == EmploymentType.internship,
    ExploreFilter.pakistan => !j.isInternational,
    ExploreFilter.international => j.isInternational,
    ExploreFilter.applyInApp => j.isInternal,
  };
}

enum ExploreSort {
  relevance('Relevance'),
  newest('Newest');

  const ExploreSort(this.label);
  final String label;
}

@immutable
class ExploreState {
  const ExploreState({
    this.query = '',
    this.filters = const {},
    this.sort = ExploreSort.relevance,
  });

  final String query;
  final Set<ExploreFilter> filters;
  final ExploreSort sort;

  ExploreState copyWith({
    String? query,
    Set<ExploreFilter>? filters,
    ExploreSort? sort,
  }) => ExploreState(
    query: query ?? this.query,
    filters: filters ?? this.filters,
    sort: sort ?? this.sort,
  );
}

class ExploreController extends Notifier<ExploreState> {
  @override
  ExploreState build() => const ExploreState();

  void setQuery(String q) => state = state.copyWith(query: q);

  void toggle(ExploreFilter f) {
    final next = {...state.filters};
    next.contains(f) ? next.remove(f) : next.add(f);
    state = state.copyWith(filters: next);
  }

  void setSort(ExploreSort s) => state = state.copyWith(sort: s);

  void clearFilters() => state = state.copyWith(filters: {});

  void reset() => state = const ExploreState();
}

final exploreControllerProvider =
    NotifierProvider<ExploreController, ExploreState>(ExploreController.new);

/// Jobs after applying search text, chip filters and sort.
///
/// Filters in the same group (e.g. Full-time + Contract) are OR-ed;
/// different groups (type vs region vs work mode) are AND-ed.
final exploreResultsProvider = Provider<AsyncValue<List<JobSummary>>>((ref) {
  final s = ref.watch(exploreControllerProvider);
  final q = s.query.trim().toLowerCase();
  // With the real API, text search runs on the server (from 2 characters).
  final serverSearch = ApiConfig.isConfigured && q.length >= 2;
  final source = serverSearch
      ? ref.watch(jobSearchProvider(q))
      : ref.watch(allJobsProvider);
  return source.whenData((jobs) {
    bool group(JobSummary j, Set<ExploreFilter> g) {
      final active = s.filters.intersection(g);
      return active.isEmpty || active.any((f) => f.matches(j));
    }

    const types = {
      ExploreFilter.fullTime,
      ExploreFilter.partTime,
      ExploreFilter.contract,
      ExploreFilter.internship,
    };
    const regions = {ExploreFilter.pakistan, ExploreFilter.international};

    final result = jobs.where((j) {
      final text =
          serverSearch ||
          q.isEmpty ||
          j.title.toLowerCase().contains(q) ||
          j.companyName.toLowerCase().contains(q) ||
          j.location.toLowerCase().contains(q) ||
          (j.category?.toLowerCase().contains(q) ?? false);
      return text &&
          group(j, types) &&
          group(j, regions) &&
          group(j, {ExploreFilter.remote}) &&
          group(j, {ExploreFilter.applyInApp});
    }).toList();

    result.sort(switch (s.sort) {
      ExploreSort.relevance => (a, b) => (b.matchScore ?? 0).compareTo(
        a.matchScore ?? 0,
      ),
      ExploreSort.newest => (a, b) => b.postedAt.compareTo(a.postedAt),
    });
    return result;
  });
});
