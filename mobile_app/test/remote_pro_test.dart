import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sharkhire/core/network/api_client.dart';
import 'package:sharkhire/core/network/api_exception.dart';
import 'package:sharkhire/core/network/auth_token_provider.dart';
import 'package:sharkhire/core/network/http_api_client.dart';
import 'package:sharkhire/features/job_search/data/repositories/api_jobs_repository.dart';
import 'package:sharkhire/features/job_search/presentation/providers/explore_providers.dart';
import 'package:sharkhire/features/subscription/domain/subscription_status.dart';
import 'package:sharkhire/features/subscription/presentation/providers/pro_access.dart';
import 'package:sharkhire/features/subscription/presentation/providers/subscription_providers.dart';
import 'package:sharkhire/shared/models/job_summary.dart';

import 'helpers.dart';

class _Token implements AuthTokenProvider {
  @override
  Future<String?> accessToken() async => 'test-token';
  @override
  Future<bool> refresh() async => false;
}

class _RecordingApi implements ApiClient {
  final calls = <(String, Map<String, Object?>)>[];
  @override
  Future<Object?> get(String path, {Map<String, Object?>? query}) async {
    calls.add((path, query ?? const {}));
    return {'items': <Object?>[]};
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Subscription status the test controls (no backend, no store).
class _FakeSubscription extends SubscriptionController {
  _FakeSubscription(this.initial);
  final SubscriptionStatus initial;

  @override
  SubscriptionStatus build() => initial;

  void set(SubscriptionStatus s) => state = s;

  @override
  Future<void> ensureLoaded() async {}
}

const _trial = SubscriptionStatus(state: AccessState.trialActive);
const _pro = SubscriptionStatus(state: AccessState.subscriptionActive);
const _expired = SubscriptionStatus(state: AccessState.subscriptionExpired);

ProviderContainer _container(SubscriptionStatus status) {
  final c = ProviderContainer(
    overrides: [
      subscriptionsEnabledProvider.overrideWithValue(true),
      subscriptionProvider.overrideWith(() => _FakeSubscription(status)),
    ],
  );
  addTearDown(c.dispose);
  return c;
}

Future<List<JobSummary>> _results(ProviderContainer c) async {
  await c.read(allJobsProvider.future);
  return c.read(exploreResultsProvider).requireValue;
}

void main() {
  group('Pro access', () {
    test('free (trial) is not Pro; a paid subscription is', () {
      expect(_container(_trial).read(proAccessProvider), isFalse);
      expect(_container(_pro).read(proAccessProvider), isTrue);
      expect(_container(_expired).read(proAccessProvider), isFalse);
    });

    test('nothing is locked when paid features are switched off', () {
      final c = ProviderContainer(
        overrides: [subscriptionsEnabledProvider.overrideWithValue(false)],
      );
      addTearDown(c.dispose);
      expect(c.read(proAccessProvider), isTrue);
    });
  });

  group('Explore results', () {
    test(
      'free users never see remote jobs; normal search still works',
      () async {
        final c = _container(_trial);
        final jobs = await _results(c);
        expect(jobs, isNotEmpty);
        expect(jobs.any((j) => j.workMode == WorkMode.remote), isFalse);
      },
    );

    test('Pro users turn Remote on and off', () async {
      final c = _container(_pro);
      final ctl = c.read(exploreControllerProvider.notifier);
      final all = await _results(c);
      expect(all.any((j) => j.workMode == WorkMode.remote), isTrue);

      ctl.toggle(ExploreFilter.remote);
      final remote = await _results(c);
      expect(remote, isNotEmpty);
      expect(remote.every((j) => j.workMode == WorkMode.remote), isTrue);

      ctl.toggle(ExploreFilter.remote);
      expect((await _results(c)).length, all.length);
    });

    test('Remote works together with the city filter', () async {
      final c = _container(_pro);
      final ctl = c.read(exploreControllerProvider.notifier);
      ctl.toggle(ExploreFilter.remote);
      ctl.setCity('London');
      final jobs = await _results(c);
      expect(
        jobs.every(
          (j) => j.workMode == WorkMode.remote && j.location.contains('London'),
        ),
        isTrue,
      );
    });

    test('a subscription that expires locks Remote again', () async {
      final c = _container(_pro);
      final ctl = c.read(exploreControllerProvider.notifier);
      ctl.toggle(ExploreFilter.remote);
      expect(
        c.read(exploreControllerProvider).filters,
        contains(ExploreFilter.remote),
      );

      (c.read(subscriptionProvider.notifier) as _FakeSubscription).set(
        _expired,
      );
      await Future<void>.delayed(Duration.zero);
      expect(c.read(proAccessProvider), isFalse);
      expect(
        c.read(exploreControllerProvider).filters,
        isNot(contains(ExploreFilter.remote)),
      );
      final jobs = await _results(c);
      expect(jobs.any((j) => j.workMode == WorkMode.remote), isFalse);
    });
  });

  group('API', () {
    test('remote_jobs_only is sent only when asked', () async {
      final api = _RecordingApi();
      final repo = ApiJobsRepository(api);
      Map<String, Object?> searchQuery() =>
          api.calls.lastWhere((c) => c.$1 == '/api/v1/jobs/search').$2;

      await repo.search('designer');
      expect(searchQuery().containsKey('remote_jobs_only'), isFalse);

      await repo.search('designer', city: 'Karachi', remoteOnly: true);
      expect(searchQuery(), {
        'query': 'designer',
        'city': 'Karachi',
        'remote_jobs_only': true,
        'num_pages': 1,
      });
    });

    for (final body in [
      {
        'error': {'code': 'PRO_FEATURE_REQUIRED', 'message': 'Pro only'},
      },
      {
        'detail': {'code': 'PRO_FEATURE_REQUIRED', 'message': 'Pro only'},
      },
      {'code': 'PRO_FEATURE_REQUIRED', 'message': 'Pro only'},
    ]) {
      test(
        '403 PRO_FEATURE_REQUIRED is recognised (${body.keys.first})',
        () async {
          final client = HttpApiClient(
            baseUrl: 'https://api.example.test',
            tokens: _Token(),
            client: MockClient(
              (_) async => http.Response(jsonEncode(body), 403),
            ),
          );
          Object? error;
          try {
            await client.get('/api/v1/jobs/search');
          } catch (e) {
            error = e;
          }
          expect(error, isA<ForbiddenException>());
          expect(isProFeatureRequired(error), isTrue);
        },
      );
    }

    test('other 403s are not treated as a Pro prompt', () {
      expect(isProFeatureRequired(const ForbiddenException()), isFalse);
      expect(isProFeatureRequired(Exception('x')), isFalse);
    });
  });

  group('Explore screen', () {
    List<Override> free() => [
      subscriptionsEnabledProvider.overrideWithValue(true),
      subscriptionProvider.overrideWith(() => _FakeSubscription(_trial)),
    ];

    testWidgets('free user: Remote is locked and shows the upgrade dialog', (
      tester,
    ) async {
      usePhone(tester);
      await launchToSeekerHome(tester, overrides: free());
      await tester.tap(find.text('Explore'));
      await tester.pumpAndSettle();

      expect(find.bySemanticsLabel('Remote, Pro feature'), findsOneWidget);
      await tester.tap(find.text('PRO').first);
      await tester.pumpAndSettle();
      expect(find.text('Unlock Remote Job Opportunities!'), findsOneWidget);

      // Maybe Later closes it and the filter stays off.
      await tester.tap(find.text('Maybe Later'));
      await tester.pumpAndSettle();
      expect(find.text('Unlock Remote Job Opportunities!'), findsNothing);
      expect(find.textContaining('jobs found'), findsOneWidget);

      // Upgrade to Pro opens the existing subscription screen.
      await tester.tap(find.text('PRO').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Upgrade to Pro'));
      await tester.pumpAndSettle();
      expect(find.text('SharkHire Premium'), findsWidgets);
    });

    testWidgets('Pro user: Remote is a normal filter', (tester) async {
      usePhone(tester);
      await launchToSeekerHome(
        tester,
        overrides: [
          subscriptionsEnabledProvider.overrideWithValue(true),
          subscriptionProvider.overrideWith(() => _FakeSubscription(_pro)),
        ],
      );
      await tester.tap(find.text('Explore'));
      await tester.pumpAndSettle();
      expect(find.text('PRO'), findsNothing);
      await tester.tap(find.text('Remote').first);
      await tester.pumpAndSettle();
      expect(find.text('Unlock Remote Job Opportunities!'), findsNothing);
    });
  });
}
