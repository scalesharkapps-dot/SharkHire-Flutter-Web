import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sharkhire/core/config/app_config.dart';
import 'package:sharkhire/core/network/api_client.dart';
import 'package:sharkhire/core/network/api_exception.dart';
import 'package:sharkhire/core/network/auth_token_provider.dart';
import 'package:sharkhire/core/network/http_api_client.dart';
import 'package:sharkhire/core/network/session_expiry.dart';
import 'package:sharkhire/features/authentication/domain/session.dart';
import 'package:sharkhire/features/authentication/presentation/providers/session_provider.dart';
import 'package:sharkhire/shared/models/app_user.dart';

void main() {
  group('Production configuration check', () {
    String? check({
      bool mock = false,
      String api = 'https://api.sharkhire.example',
    }) => AppConfig.checkProductionConfig(useMockData: mock, apiBaseUrl: api);

    test('a complete https configuration passes', () {
      expect(check(), isNull);
    });

    test('mock data, http or localhost fail', () {
      expect(check(mock: true), contains('USE_MOCK_DATA'));
      expect(check(api: ''), contains('API_BASE_URL'));
      expect(check(api: 'http://api.sharkhire.example'), contains('https'));
      expect(check(api: 'https://localhost:8000'), contains('local'));
    });

    test('this test build is not a production build', () {
      expect(AppConfig.isProduction, isFalse);
    });
  });

  test('CV upload sends the file MIME type, not octet-stream', () async {
    late String contentType;
    final client = HttpApiClient(
      baseUrl: 'https://api.example.test',
      tokens: const NoTokenProvider(),
      client: MockClient((req) async {
        contentType = req.headers['content-type'] ?? '';
        final body = utf8.decode(req.bodyBytes, allowMalformed: true);
        expect(body.toLowerCase(), contains('content-type: application/pdf'));
        return http.Response(jsonEncode({'id': 'r1'}), 201);
      }),
    );
    await client.upload(
      '/api/v1/resumes/upload',
      UploadFile(
        fieldName: 'file',
        fileName: 'cv.pdf',
        bytes: utf8.encode('%PDF-1.4'),
        contentType: 'application/pdf',
      ),
    );
    expect(contentType, startsWith('multipart/form-data'));
  });

  test('a 401 on a signed-in request signs the user out', () async {
    final container = ProviderContainer(
      overrides: [
        initialSessionProvider.overrideWithValue(
          const Session(
            user: AppUser(fullName: 'Ayesha Khan', email: 'a@example.com'),
            emailVerified: true,
            onboardingComplete: true,
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    expect(container.read(sessionProvider).isSignedIn, isTrue);

    final client = HttpApiClient(
      baseUrl: 'https://api.example.test',
      tokens: _ExpiredToken(),
      client: MockClient((_) async => http.Response('', 401)),
      onUnauthorized: () =>
          container.read(sessionExpiryProvider.notifier).expired(),
    );
    await expectLater(
      client.get('/api/v1/auth/me'),
      throwsA(isA<UnauthorizedException>()),
    );
    await Future<void>.delayed(Duration.zero);
    expect(container.read(sessionProvider).isSignedIn, isFalse);
  });
}

/// A token the server rejects and that can't be renewed.
class _ExpiredToken implements AuthTokenProvider {
  @override
  Future<String?> accessToken() async => 'expired';

  @override
  Future<bool> refresh() async => false;
}
