import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sharkhire/core/network/api_client.dart';
import 'package:sharkhire/core/network/api_exception.dart';
import 'package:sharkhire/core/network/auth_token_provider.dart';
import 'package:sharkhire/core/network/http_api_client.dart';
import 'package:sharkhire/core/network/paginated.dart';
import 'package:sharkhire/features/applications/data/models/application_json.dart';
import 'package:sharkhire/features/job_details/data/models/job_details_json.dart';
import 'package:sharkhire/features/job_search/data/repositories/api_jobs_repository.dart';
import 'package:sharkhire/features/resume/data/models/resume_json.dart';
import 'package:sharkhire/shared/models/domain_enums.dart';
import 'package:sharkhire/shared/models/job_summary.dart';
import 'package:sharkhire/shared/models/json_mappers.dart';

import 'helpers.dart';

class _Token implements AuthTokenProvider {
  @override
  Future<String?> accessToken() async => 'test-token';

  @override
  Future<bool> refresh() async => false;
}

/// Fake [ApiClient] that returns canned JSON per path.
class _FakeApi implements ApiClient {
  _FakeApi(this.responses);
  final Map<String, Object?> responses;

  @override
  Future<Object?> get(String path, {Map<String, Object?>? query}) async =>
      responses[path];
  @override
  Future<Object?> post(String path, {Object? body}) async => null;
  @override
  Future<ApiEnvelope> postEnvelope(String path, {Object? body}) async =>
      const ApiEnvelope();
  @override
  Future<Object?> put(String path, {Object? body}) async => null;
  @override
  Future<Object?> patch(String path, {Object? body}) async => null;
  @override
  Future<Object?> delete(String path) async => null;
  @override
  Future<Object?> upload(
    String path,
    UploadFile file, {
    Map<String, String> fields = const {},
  }) async => null;
}

Map<String, Object?> _job(String id, String source) => {
  'id': id,
  'source': source,
  'title': 'Flutter Developer',
  'company_name': 'Indus Ledger',
  'location_text': 'Lahore, Pakistan',
  'work_mode': 'hybrid',
  'employment_type': 'full_time',
  'posted_at': '2026-11-12T09:00:00Z',
  'match_score': 91.6,
};

void main() {
  group('HttpApiClient.decodeResponse maps HTTP results', () {
    test('2xx returns decoded JSON', () {
      expect(HttpApiClient.decodeResponse(200, '{"ok":true}', {}), {
        'ok': true,
      });
      expect(HttpApiClient.decodeResponse(204, '', {}), isNull);
    });

    test('422 FastAPI validation errors become field errors', () {
      const body =
          '{"detail":[{"loc":["body","email"],"msg":"Invalid email"}]}';
      expect(
        () => HttpApiClient.decodeResponse(422, body, {}),
        throwsA(
          isA<ValidationException>().having(
            (e) => e.fieldErrors['email'],
            'email',
            'Invalid email',
          ),
        ),
      );
    });

    test('auth, missing, rate limit and server errors', () {
      expect(
        () => HttpApiClient.decodeResponse(401, '', {}),
        throwsA(isA<UnauthorizedException>()),
      );
      expect(
        () => HttpApiClient.decodeResponse(403, '', {}),
        throwsA(isA<ForbiddenException>()),
      );
      expect(
        () => HttpApiClient.decodeResponse(404, '', {}),
        throwsA(isA<NotFoundException>()),
      );
      expect(
        () => HttpApiClient.decodeResponse(429, '', {'retry-after': '30'}),
        throwsA(
          isA<RateLimitedException>().having(
            (e) => e.retryAfter,
            'retryAfter',
            const Duration(seconds: 30),
          ),
        ),
      );
      expect(
        () => HttpApiClient.decodeResponse(503, '', {}),
        throwsA(isA<ServerException>()),
      );
    });

    test('friendly messages for the UI', () {
      expect(
        friendlyErrorMessage(const RateLimitedException()),
        contains('busy'),
      );
      expect(friendlyErrorMessage(Exception('x')), contains('couldn\'t load'));
    });
  });

  test('HttpApiClient sends the bearer token and query parameters', () async {
    late http.Request seen;
    final client = HttpApiClient(
      baseUrl: 'https://api.example.test',
      tokens: _Token(),
      client: MockClient((req) async {
        seen = req;
        return http.Response(jsonEncode({'items': []}), 200);
      }),
    );
    await client.get('/api/v1/jobs', query: {'page': 2, 'q': null});
    expect(seen.url.toString(), 'https://api.example.test/api/v1/jobs?page=2');
    expect(seen.headers['Authorization'], 'Bearer test-token');
  });

  group('JSON mappers', () {
    test('job summary maps DB values and falls back on unknown enums', () {
      final j = jobSummaryFromJson({
        ..._job('1', 'internal'),
        'work_mode': 'space',
      });
      expect(j.isInternal, isTrue);
      expect(j.employmentType, EmploymentType.fullTime);
      expect(j.workMode, WorkMode.onsite);
      expect(j.matchScore, 92);
    });

    test('job details keep external apply url', () {
      final d = jobDetailsFromJson({
        ..._job('2', 'external'),
        'apply_url': 'https://jobs.example/apply/2',
        'required_skills': ['Flutter'],
        'experience_level': 'senior',
      });
      expect(d.applyUrl, 'https://jobs.example/apply/2');
      expect(d.isInternal, isFalse);
      expect(d.experienceLevel, ExperienceLevel.senior);
    });

    test('application status history', () {
      final a = applicationFromJson({
        'id': 'a1',
        'job': _job('1', 'internal'),
        'status_history': [
          {'status': 'submitted', 'created_at': '2026-11-01T10:00:00Z'},
          {
            'status': 'under_review',
            'created_at': '2026-11-02T10:00:00Z',
            'note': 'Looking',
          },
        ],
      });
      expect(a.status, ApplicationStatus.underReview);
      expect(a.history.last.note, 'Looking');
    });

    test('profile and resume', () {
      final u = appUserFromJson({
        'full_name': 'Ayesha Khan',
        'email': 'a@example.com',
        'roles': ['employer', 'unknown_role'],
        'city': 'Lahore',
        'country': 'Pakistan',
      });
      expect(u.isEmployer, isTrue);
      expect(u.location, 'Lahore, Pakistan');
      expect(profileUpdateToJson(u)['city'], 'Lahore');

      final r = resumeFromJson({
        'id': 'r1',
        'original_filename': 'cv.pdf',
        'status': 'processing',
      });
      expect(r.status, ResumeStatus.processing);
    });

    test('pagination', () {
      final p = Paginated.fromJson({
        'items': [_job('1', 'internal')],
        'page': 1,
        'page_size': 1,
        'total': 3,
      }, jobSummaryFromJson);
      expect(p.items.single.id, '1');
      expect(p.hasMore, isTrue);
    });
  });

  test('ApiJobsRepository merges recommendations and SharkHire jobs', () async {
    Map<String, Object?> job(String id, String source) => {
      'id': id,
      'source': source,
      'is_external': source != 'sharkhire',
      'job_title': 'Flutter Developer',
      'employer_name': 'Indus Ledger',
      'job_country': 'PK',
      'job_location': 'Lahore, Pakistan',
      'job_is_remote': false,
      'job_employment_type': 'FULLTIME',
      'job_posted_at': '2026-11-12T09:00:00Z',
    };
    final repo = ApiJobsRepository(
      _FakeApi({
        '/api/v1/recommendations/for-me': {
          'items': [
            {
              'job': job('2', 'jsearch'),
              'match': {'match_percentage': 87},
            },
          ],
        },
        '/api/v1/jobs/sharkhire': {
          'items': [job('1', 'sharkhire'), job('2', 'jsearch')],
        },
      }),
    );
    final jobs = await repo.fetchJobs();
    expect(jobs.map((j) => j.id), ['2', '1']);
    expect(jobs.first.matchScore, 87);
    expect(jobs.last.source, JobSource.internal);
  });

  testWidgets('Explore shows jobs page by page', (tester) async {
    usePhone(tester);
    await launchToSeekerHome(tester);
    await tester.tap(find.text('Explore'));
    await tester.pumpAndSettle();
    final more = find.text('Show more jobs (2 left)');
    await scrollTo(tester, more);
    await tester.tap(more);
    await tester.pumpAndSettle();
    expect(find.textContaining('Show more jobs'), findsNothing);
  });
}
