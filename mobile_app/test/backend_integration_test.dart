// Tests for the integration with the deployed SharkHire API. Error bodies are
// copied from real responses of https://backend-job-search.onrender.com
// (17 Nov 2026); success bodies follow its OpenAPI schemas.

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sharkhire/core/network/api_exception.dart';
import 'package:sharkhire/core/network/auth_token_provider.dart';
import 'package:sharkhire/core/network/http_api_client.dart';
import 'package:sharkhire/features/applications/data/repositories/applications_repository.dart';
import 'package:sharkhire/features/authentication/data/repositories/api_auth_repository.dart';
import 'package:sharkhire/features/authentication/data/repositories/auth_repository.dart';
import 'package:sharkhire/features/profile/data/models/job_preferences.dart';
import 'package:sharkhire/features/profile/data/repositories/profile_repository.dart';
import 'package:sharkhire/features/resume/data/repositories/api_resume_repository.dart';
import 'package:sharkhire/shared/models/app_user.dart';
import 'package:sharkhire/shared/models/backend_json.dart';
import 'package:sharkhire/shared/models/job_summary.dart';

const _base = 'https://api.example.test';

String _ok(Object? data) => jsonEncode({
  'success': true,
  'message': 'Request completed successfully',
  'data': data,
  'error': null,
});

Map<String, Object?> _session(String access) => {
  'access_token': access,
  'refresh_token': 'refresh-$access',
  'token_type': 'bearer',
  'expires_in': 3600,
  'user': {
    'id': '7c0e9a2e-0000-4000-8000-000000000001',
    'email': 'ayesha@example.com',
    'full_name': 'Ayesha Khan',
    'role': 'job_seeker',
    'is_active': true,
    'email_verified': true,
  },
};

void main() {
  group('Envelope and errors (real API responses)', () {
    test('success envelope returns data', () {
      expect(HttpApiClient.decodeResponse(200, _ok({'status': 'ok'}), {}), {
        'status': 'ok',
      });
    });

    test('401 not_authenticated keeps code and message', () {
      const body =
          '{"success":false,"message":"Authentication is required.","data":null,"error":{"code":"not_authenticated","message":"Authentication is required.","details":null,"request_id":"766e2fad5b654710bc4b7202d3da28d4"}}';
      expect(
        () => HttpApiClient.decodeResponse(401, body, {}),
        throwsA(
          isA<UnauthorizedException>()
              .having((e) => e.code, 'code', 'not_authenticated')
              .having(
                (e) => e.message,
                'message',
                'Authentication is required.',
              ),
        ),
      );
    });

    test('503 storage_not_configured explains why uploads fail', () {
      const body =
          '{"success":false,"message":"Supabase Storage is not configured.","data":null,"error":{"code":"storage_not_configured","message":"Supabase Storage is not configured.","details":null,"request_id":"2c88c6a677a84be9a883a868aeb3005a"}}';
      expect(
        () => HttpApiClient.decodeResponse(503, body, {}),
        throwsA(
          isA<ServerException>()
              .having((e) => e.code, 'code', 'storage_not_configured')
              .having((e) => e.message, 'message', contains('file storage')),
        ),
      );
    });

    test('422 validation_error maps field details', () {
      const body =
          '{"success":false,"message":"The submitted data is invalid.","data":null,"error":{"code":"validation_error","message":"The submitted data is invalid.","details":[{"field":"email","message":"value is not a valid email address: An email address must have an @-sign.","type":"value_error"},{"field":"password","message":"String should have at least 1 character","type":"string_too_short"}],"request_id":"840d554b059c49ccb7f5e85281d4c3b7"}}';
      expect(
        () => HttpApiClient.decodeResponse(422, body, {}),
        throwsA(
          isA<ValidationException>()
              .having((e) => e.code, 'code', 'validation_error')
              .having((e) => e.fieldErrors.keys, 'fields', [
                'email',
                'password',
              ]),
        ),
      );
    });
  });

  test('expired token is refreshed once and the request retried', () async {
    final store = MemoryTokenStore();
    await store.write(
      SessionTokens.fromSessionJson({
        ..._session('old'),
        'expires_at':
            DateTime.now()
                .add(const Duration(hours: 1))
                .millisecondsSinceEpoch ~/
            1000,
      }),
    );
    final calls = <String>[];
    final mock = MockClient((req) async {
      calls.add(
        '${req.method} ${req.url.path} ${req.headers['Authorization']}',
      );
      if (req.url.path == '/api/v1/auth/refresh') {
        expect(jsonDecode(req.body), {'refresh_token': 'refresh-old'});
        return http.Response(_ok(_session('new')), 200);
      }
      return req.headers['Authorization'] == 'Bearer new'
          ? http.Response(_ok({'email': 'ayesha@example.com'}), 200)
          : http.Response(
              '{"success":false,"message":"Invalid access token.","data":null,"error":{"code":"invalid_token","message":"Invalid access token."}}',
              401,
            );
    });
    final tokens = SessionTokenManager(
      store: store,
      baseUrl: _base,
      client: mock,
    );
    var expired = false;
    final api = HttpApiClient(
      baseUrl: _base,
      tokens: tokens,
      client: mock,
      onUnauthorized: () => expired = true,
    );
    final me = await api.get('/api/v1/auth/me');
    expect(me, {'email': 'ayesha@example.com'});
    expect(calls, [
      'GET /api/v1/auth/me Bearer old',
      'POST /api/v1/auth/refresh null',
      'GET /api/v1/auth/me Bearer new',
    ]);
    expect(expired, isFalse);
    expect((await store.read())!.accessToken, 'new');
  });

  group('ApiAuthRepository', () {
    ApiAuthRepository repo(MockClient mock, SessionTokenManager tokens) =>
        ApiAuthRepository(
          HttpApiClient(baseUrl: _base, tokens: tokens, client: mock),
          tokens,
        );

    test(
      'wrong password shows the backend message, not "session expired"',
      () async {
        final tokens = SessionTokenManager(
          store: MemoryTokenStore(),
          baseUrl: _base,
        );
        final r = repo(
          MockClient(
            (_) async => http.Response(
              '{"success":false,"message":"Invalid email or password.","data":null,"error":{"code":"invalid_credentials","message":"Invalid email or password.","details":null}}',
              401,
            ),
          ),
          tokens,
        );
        expect(
          () => r.signIn(email: 'a@example.com', password: 'x'),
          throwsA(
            isA<AuthFailure>().having(
              (e) => e.message,
              'message',
              'Invalid email or password.',
            ),
          ),
        );
      },
    );

    test('login stores tokens and builds the session', () async {
      final store = MemoryTokenStore();
      final tokens = SessionTokenManager(store: store, baseUrl: _base);
      final mock = MockClient((req) async {
        return switch (req.url.path) {
          '/api/v1/auth/login' => http.Response(_ok(_session('a1')), 200),
          '/api/v1/auth/me' => http.Response(
            _ok({
              'id': 'u1',
              'email': 'ayesha@example.com',
              'full_name': 'Ayesha Khan',
              'role': 'job_seeker',
              'is_active': true,
              'email_verified': true,
              'session_expires_at': 0,
            }),
            200,
          ),
          '/api/v1/profile/me' => http.Response(
            _ok({
              'user_id': 'u1',
              'email': 'ayesha@example.com',
              'role': 'job_seeker',
              'full_name': 'Ayesha Khan',
              'headline': 'Flutter Developer',
              'city': 'Lahore',
              'country': 'Pakistan',
              'profile_completion': 60,
              'completion_breakdown': {},
            }),
            200,
          ),
          '/api/v1/cv' => http.Response(
            _ok([
              {
                'id': 'cv1',
                'processing_status': 'completed',
                'is_primary': true,
              },
            ]),
            200,
          ),
          '/api/v1/recommendations/preferences' => http.Response(
            _ok({
              'preferred_job_titles': ['Software'],
              'updated_at': '2026-11-17T10:00:00Z',
            }),
            200,
          ),
          _ => http.Response('', 404),
        };
      });
      final session = await repo(
        mock,
        tokens,
      ).signIn(email: 'ayesha@example.com', password: 'secret123');
      expect((await store.read())!.accessToken, 'a1');
      expect(session.user!.fullName, 'Ayesha Khan');
      expect(session.user!.location, 'Lahore, Pakistan');
      expect(session.user!.profileCompletion, 0.6);
      expect(session.user!.hasCv, isTrue);
      expect(session.emailVerified, isTrue);
      expect(session.onboardingComplete, isTrue);
      expect(session.user!.roles, {AppRole.jobSeeker});
    });

    test(
      'sign-up with email confirmation returns an unverified session',
      () async {
        final tokens = SessionTokenManager(
          store: MemoryTokenStore(),
          baseUrl: _base,
        );
        final mock = MockClient(
          (_) async => http.Response(
            _ok({
              'user': null,
              'session': null,
              'email_confirmation_required': true,
            }),
            200,
          ),
        );
        final s = await repo(mock, tokens).signUp(
          fullName: 'Sara Malik',
          email: 'sara@example.com',
          password: 'secret123',
          role: AppRole.jobSeeker,
        );
        expect(s.isSignedIn, isTrue);
        expect(s.emailVerified, isFalse);
        expect(await tokens.current(), isNull);
      },
    );
  });

  group('Mapping', () {
    test('JSearch job summary', () {
      final j = jobSummaryFromApi({
        'id': 'j1',
        'source': 'jsearch',
        'is_external': true,
        'job_title': 'Backend Engineer',
        'employer_name': 'Northwind',
        'job_city': 'Dubai',
        'job_country': 'AE',
        'job_location': null,
        'job_is_remote': true,
        'job_employment_type': 'CONTRACTOR',
        'job_min_salary': 4000,
        'job_max_salary': 6000,
        'job_currency': 'USD',
        'job_salary_period': 'MONTH',
        'job_posted_at': '2026-11-15T08:00:00Z',
      });
      expect(j.isInternal, isFalse);
      expect(j.isInternational, isTrue);
      expect(j.workMode, WorkMode.remote);
      expect(j.employmentType, EmploymentType.contract);
      expect(j.location, 'Dubai, AE');
      expect(j.salaryLabel, 'USD 4K – 6K / month');
    });

    test('application statuses and history', () {
      final a = applicationFromApi({
        'id': 'a1',
        'job_id': 'j1',
        'source': 'sharkhire',
        'job_title': 'QA Engineer',
        'company_name': 'Harbor & Co.',
        'status': 'interview_scheduled',
        'applied_at': '2026-11-01T10:00:00Z',
        'created_at': '2026-11-01T10:00:00Z',
        'updated_at': '2026-11-05T10:00:00Z',
        'history': [
          {
            'id': 'h1',
            'previous_status': null,
            'new_status': 'applied',
            'changed_at': '2026-11-01T10:00:00Z',
            'notes': null,
          },
          {
            'id': 'h2',
            'previous_status': 'applied',
            'new_status': 'interview_scheduled',
            'changed_at': '2026-11-05T10:00:00Z',
            'notes': 'Thursday 3 PM',
          },
        ],
      });
      expect(a.status, ApplicationStatus.interview);
      expect(a.history.map((h) => h.status), [
        ApplicationStatus.submitted,
        ApplicationStatus.interview,
      ]);
      expect(a.history.last.note, 'Thursday 3 PM');
      expect(a.job.isInternal, isTrue);
      expect(applicationStatusToApi(ApplicationStatus.withdrawn), 'withdrawn');
    });

    test('job preferences round-trip', () {
      const prefs = JobPreferences(
        includePakistan: true,
        includeInternational: false,
        categories: {'Software'},
        employmentTypes: {EmploymentType.fullTime, EmploymentType.internship},
        workModes: {WorkMode.remote},
        experienceLevel: ExperienceLevel.junior,
      );
      final json = preferencesToApi(prefs);
      expect(json['preferred_countries'], ['pk']);
      expect(json['employment_types'], ['FULLTIME', 'INTERN']);
      expect(json['remote_preference'], 'remote_only');
      expect(json['experience_level'], 'junior');
      final back = preferencesFromApi({...json, 'updated_at': 'x'});
      expect(back.includeInternational, isFalse);
      expect(back.workModes, {WorkMode.remote});
      expect(back.employmentTypes, prefs.employmentTypes);
    });

    test('CV extracted data', () {
      final p = parsedProfileFromApi({
        'cv_id': 'cv1',
        'processing_status': 'completed',
        'extracted_name': 'Ayesha Khan',
        'skills': ['Flutter', 'Dart'],
        'work_experience': [
          {
            'title': 'Flutter Developer',
            'company': 'Northstar Apps',
            'start_date': '2024-01-01',
            'is_current': true,
          },
        ],
        'education': [
          {
            'degree': 'BS Computer Science',
            'start_year': 2019,
            'end_year': 2023,
          },
        ],
        'years_of_experience': 2,
      }, const AppUser(fullName: 'A', email: 'a@example.com'));
      expect(p.skills, ['Flutter', 'Dart']);
      expect(p.experience.single.period, 'Jan 2024 – Present');
      expect(p.education.single.period, '2019 – 2023');
      expect(p.yearsOfExperience, 2);
    });
  });
}
