import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_config.dart';
import '../../../../shared/models/job_summary.dart';
import '../../../subscription/presentation/providers/pro_access.dart';
import '../../data/city_match.dart';
import '../../data/repositories/jobs_repository.dart';

export '../../data/city_match.dart' show pakistanCities, internationalCities;

/// All jobs available to the user (internal + external).
final allJobsProvider = FutureProvider<List<JobSummary>>(
  (ref) => ref.watch(jobsRepositoryProvider).fetchJobs(),
);

/// What the server searches for: text, a city when chosen, and remote-only
/// (Pro users with the Remote filter on).
typedef JobSearchKey = ({String query, String? city, bool remoteOnly});

/// Server-side search for a [JobSearchKey]. Waits for typing to pause so
/// the job-search quota isn't spent on every keystroke.
final jobSearchProvider = FutureProvider.autoDispose
    .family<List<JobSummary>, JobSearchKey>((ref, key) async {
      await Future<void>.delayed(const Duration(milliseconds: 600));
      if (!ref.mounted) return const [];
      return ref
          .watch(jobsRepositoryProvider)
          .search(key.query, city: key.city, remoteOnly: key.remoteOnly);
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
    this.city,
  });

  final String query;
  final Set<ExploreFilter> filters;
  final ExploreSort sort;

  /// Chosen city (Pakistani or international), or null for any city.
  final String? city;

  /// Chips plus the city, for the badge on the filter button.
  int get activeFilterCount => filters.length + (city == null ? 0 : 1);

  ExploreState copyWith({
    String? query,
    Set<ExploreFilter>? filters,
    ExploreSort? sort,
    String? city,
    bool clearCity = false,
  }) => ExploreState(
    query: query ?? this.query,
    filters: filters ?? this.filters,
    sort: sort ?? this.sort,
    city: clearCity ? null : (city ?? this.city),
  );
}

class ExploreController extends Notifier<ExploreState> {
  @override
  ExploreState build() {
    // Losing Pro (expired, cancelled, signed out) locks Remote again.
    ref.listen(proAccessProvider, (_, pro) {
      if (!pro) removeRemote();
    });
    return const ExploreState();
  }

  /// Turns the Remote filter off (lost Pro, or the backend refused it).
  void removeRemote() {
    if (!state.filters.contains(ExploreFilter.remote)) return;
    state = state.copyWith(
      filters: {...state.filters}..remove(ExploreFilter.remote),
    );
  }

  void setQuery(String q) => state = state.copyWith(query: q);

  void toggle(ExploreFilter f) {
    final next = {...state.filters};
    next.contains(f) ? next.remove(f) : next.add(f);
    final city = state.city;
    // A city that the new region rules out is cleared.
    final cityOff =
        city != null &&
        ((isPakistanCity(city) &&
                next.contains(ExploreFilter.international) &&
                !next.contains(ExploreFilter.pakistan)) ||
            (!isPakistanCity(city) &&
                next.contains(ExploreFilter.pakistan) &&
                !next.contains(ExploreFilter.international)) ||
            (f == ExploreFilter.pakistan &&
                !next.contains(f) &&
                isPakistanCity(city)));
    state = state.copyWith(filters: next, clearCity: cityOff);
  }

  /// Picks a city, or any city when [city] is null or blank. A city outside
  /// the chosen region turns that region chip off.
  void setCity(String? city) {
    final c = city?.trim();
    if (c == null || c.isEmpty) {
      state = state.copyWith(clearCity: true);
      return;
    }
    final next = {...state.filters};
    if (isPakistanCity(c)) {
      next.remove(ExploreFilter.international);
    } else {
      next.remove(ExploreFilter.pakistan);
    }
    state = state.copyWith(city: c, filters: next);
  }

  void setSort(ExploreSort s) => state = state.copyWith(sort: s);

  void clearFilters() => state = state.copyWith(filters: {}, clearCity: true);

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
  final city = s.city;
  // Remote jobs are a Pro feature: free users never get them.
  final pro = ref.watch(proAccessProvider);
  final remoteOnly = pro && s.filters.contains(ExploreFilter.remote);
  // With the real API, text search (from 2 characters), the city and the
  // remote-only filter run on the server; each is sent only when chosen.
  final serverSearch =
      ApiConfig.isConfigured && (q.length >= 2 || city != null || remoteOnly);
  final source = serverSearch
      ? ref.watch(
          jobSearchProvider((
            query: q.length >= 2 ? q : '',
            city: city,
            remoteOnly: remoteOnly,
          )),
        )
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
          (serverSearch && q.length >= 2) ||
          q.isEmpty ||
          j.title.toLowerCase().contains(q) ||
          j.companyName.toLowerCase().contains(q) ||
          j.location.toLowerCase().contains(q) ||
          (j.category?.toLowerCase().contains(q) ?? false);
      return text &&
          (pro || j.workMode != WorkMode.remote) &&
          group(j, types) &&
          group(j, regions) &&
          // The server already filtered by city; sample data is filtered here.
          (city == null || serverSearch || jobInCity(j, city)) &&
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
