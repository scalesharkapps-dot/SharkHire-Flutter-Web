import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sharkhire/core/network/api_client.dart';
import 'package:sharkhire/features/job_search/data/city_match.dart';
import 'package:sharkhire/features/job_search/data/repositories/api_jobs_repository.dart';
import 'package:sharkhire/features/job_search/presentation/providers/explore_providers.dart';
import 'package:sharkhire/shared/models/job_summary.dart';

import 'helpers.dart';

/// Records every GET so the test can check the query parameters.
class _RecordingApi implements ApiClient {
  final calls = <(String, Map<String, Object?>)>[];
  final Map<String, Object?> responses;
  _RecordingApi(this.responses);

  @override
  Future<Object?> get(String path, {Map<String, Object?>? query}) async {
    calls.add((path, query ?? const {}));
    return responses[path];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Map<String, Object?> _job(
  String id,
  String location, {
  String country = 'PK',
}) => {
  'id': id,
  'source': id.startsWith('s') ? 'sharkhire' : 'jsearch',
  'is_external': !id.startsWith('s'),
  'job_title': 'Flutter Developer',
  'employer_name': 'Indus Ledger',
  'job_country': country,
  'job_location': location,
  'job_is_remote': false,
  'job_employment_type': 'FULLTIME',
  'job_posted_at': '2026-11-12T09:00:00Z',
};

void main() {
  group('API: city parameter', () {
    late _RecordingApi api;
    setUp(() {
      api = _RecordingApi({
        '/api/v1/jobs/search': {
          'items': [_job('j1', 'London, UK', country: 'GB')],
        },
        '/api/v1/jobs/sharkhire': {
          'items': [
            _job('s1', 'Karachi, Pakistan'),
            _job('s2', 'Lahore, Pakistan'),
          ],
        },
      });
    });

    Map<String, Object?> searchQuery() =>
        api.calls.firstWhere((c) => c.$1 == '/api/v1/jobs/search').$2;

    test('sent only when a city is chosen; other parameters kept', () async {
      await ApiJobsRepository(api).search('flutter');
      expect(searchQuery(), {'query': 'flutter', 'num_pages': 1});

      api.calls.clear();
      await ApiJobsRepository(api).search('flutter', city: 'Karachi');
      expect(searchQuery(), {
        'query': 'flutter',
        'city': 'Karachi',
        'num_pages': 1,
      });
    });

    test('city alone searches without an empty query', () async {
      await ApiJobsRepository(api).search('', city: 'London');
      expect(searchQuery(), {'city': 'London', 'num_pages': 1});
    });

    test('blank city is not sent', () async {
      await ApiJobsRepository(api).search('flutter', city: '  ');
      expect(searchQuery().containsKey('city'), isFalse);
    });

    test('SharkHire jobs are kept to the chosen city', () async {
      final jobs = await ApiJobsRepository(api).search('', city: 'Lahore');
      expect(jobs.map((j) => j.id), containsAll(['j1', 's2']));
      expect(jobs.map((j) => j.id), isNot(contains('s1')));
    });
  });

  group('City rules', () {
    JobSummary job(String location, {bool intl = false}) => JobSummary(
      id: location,
      title: 'Developer',
      companyName: 'Co',
      location: location,
      workMode: WorkMode.onsite,
      employmentType: EmploymentType.fullTime,
      source: JobSource.external,
      isInternational: intl,
      postedAt: DateTime(2026),
    );

    test('matches the city in the location text', () {
      expect(jobInCity(job('Lahore, Pakistan'), 'Lahore'), isTrue);
      expect(jobInCity(job('Karachi, Pakistan'), 'Lahore'), isFalse);
      expect(jobInCity(job('London, UK', intl: true), 'london'), isTrue);
    });

    test('Hyderabad, India is not Hyderabad, Pakistan', () {
      expect(
        jobInCity(job('Hyderabad, India', intl: true), 'Hyderabad'),
        isFalse,
      );
      expect(jobInCity(job('Hyderabad, Pakistan'), 'Hyderabad'), isTrue);
    });

    test('picking a city sets the matching region and can be cleared', () {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      final ctl = c.read(exploreControllerProvider.notifier);

      ctl.toggle(ExploreFilter.pakistan);
      ctl.setCity('London');
      var s = c.read(exploreControllerProvider);
      expect(s.city, 'London');
      expect(s.filters.contains(ExploreFilter.pakistan), isFalse);

      ctl.toggle(ExploreFilter.international);
      ctl.setCity('Karachi');
      s = c.read(exploreControllerProvider);
      expect(s.filters.contains(ExploreFilter.international), isFalse);
      expect(s.activeFilterCount, 1);

      ctl.setCity(null);
      expect(c.read(exploreControllerProvider).city, isNull);
    });
  });

  group('Explore (sample data)', () {
    Future<List<JobSummary>> results(ProviderContainer c) async {
      await c.read(allJobsProvider.future);
      return c.read(exploreResultsProvider).requireValue;
    }

    test('Karachi, then Lahore, then cleared', () async {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      final ctl = c.read(exploreControllerProvider.notifier);
      final all = await results(c);

      ctl.setCity('Karachi');
      final karachi = await results(c);
      expect(karachi, isNotEmpty);
      expect(karachi.every((j) => j.location.contains('Karachi')), isTrue);

      ctl.setCity('Lahore');
      final lahore = await results(c);
      expect(lahore, isNotEmpty);
      expect(lahore.every((j) => j.location.contains('Lahore')), isTrue);

      ctl.setCity(null);
      expect((await results(c)).length, all.length);
    });

    test('city works together with other filters', () async {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      final ctl = c.read(exploreControllerProvider.notifier);
      ctl.setCity('Lahore');
      ctl.toggle(ExploreFilter.fullTime);
      final jobs = await results(c);
      expect(
        jobs.every(
          (j) =>
              j.location.contains('Lahore') &&
              j.employmentType == EmploymentType.fullTime,
        ),
        isTrue,
      );
    });
  });

  testWidgets('Explore: choose a city, see the chip, clear it', (tester) async {
    usePhone(tester);
    await launchToSeekerHome(tester);
    await tester.tap(find.text('Explore'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Choose a city'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'Karachi');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Karachi').last);
    await tester.pumpAndSettle();

    expect(find.textContaining('in Karachi'), findsOneWidget);
    expect(find.byTooltip('Clear city'), findsOneWidget);

    await tester.tap(find.byTooltip('Clear city'));
    await tester.pumpAndSettle();
    expect(find.textContaining('in Karachi'), findsNothing);
    expect(find.textContaining('found'), findsOneWidget);
  });
}
