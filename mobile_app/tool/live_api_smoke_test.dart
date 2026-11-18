// Live smoke test against the deployed backend. NOT part of `flutter test`
// (it lives in tool/ and needs the internet). Run:
//
//   flutter test tool/live_api_smoke_test.dart --dart-define=API_BASE_URL=https://backend-job-search.onrender.com
//
// It only uses public endpoints and expected-failure paths; it never creates
// accounts. Signed-in flows need a test account (see SESSION_HANDOFF.md).
//
// Optional signed-in check (your own test account):
//   --dart-define=SMOKE_EMAIL=... --dart-define=SMOKE_PASSWORD=...

import 'package:flutter_test/flutter_test.dart';
import 'package:sharkhire/core/network/api_exception.dart';
import 'package:sharkhire/core/network/auth_token_provider.dart';
import 'package:sharkhire/core/network/http_api_client.dart';
import 'package:sharkhire/features/authentication/data/repositories/api_auth_repository.dart';
import 'package:sharkhire/features/authentication/data/repositories/auth_repository.dart';
import 'package:sharkhire/features/job_search/data/repositories/api_jobs_repository.dart';

const _base = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'https://backend-job-search.onrender.com',
);
const _email = String.fromEnvironment('SMOKE_EMAIL');
const _password = String.fromEnvironment('SMOKE_PASSWORD');

void main() {
  final tokens = SessionTokenManager(store: MemoryTokenStore(), baseUrl: _base);
  final api = HttpApiClient(baseUrl: _base, tokens: tokens);
  final auth = ApiAuthRepository(api, tokens);
  const slow = Timeout(Duration(minutes: 2)); // free hosting may cold-start

  test('health', () async {
    final h = await api.get('/api/v1/health') as Map;
    expect(h['status'], 'ok');
  }, timeout: slow);

  test('job filters (public, envelope unwrapped)', () async {
    final f = await api.get('/api/v1/jobs/filters') as Map;
    expect(f['employment_types'], contains('FULLTIME'));
  }, timeout: slow);

  test('wrong login shows the backend message', () async {
    await expectLater(
      auth.signIn(
        email: 'smoke.nobody@example.com',
        password: 'not-the-password',
      ),
      throwsA(
        isA<AuthFailure>().having(
          (e) => e.message,
          'message',
          'Invalid email or password.',
        ),
      ),
    );
  }, timeout: slow);

  test('job search requires sign-in', () async {
    await expectLater(
      api.get('/api/v1/jobs/search', query: {'query': 'flutter'}),
      throwsA(
        isA<UnauthorizedException>().having(
          (e) => e.code,
          'code',
          'not_authenticated',
        ),
      ),
    );
  }, timeout: slow);

  test(
    'signed-in: session, SharkHire jobs and recommendations',
    () async {
      final session = await auth.signIn(email: _email, password: _password);
      expect(session.isSignedIn, isTrue);
      final jobs = await ApiJobsRepository(api).fetchJobs();
      // ignore: avoid_print
      print('Signed in as ${session.user!.email}; ${jobs.length} jobs loaded');
      await auth.signOut();
    },
    timeout: slow,
    skip: _email.isEmpty ? 'No SMOKE_EMAIL/SMOKE_PASSWORD given' : false,
  );
}
