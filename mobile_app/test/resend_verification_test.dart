// Issue 02 – resend email verification.
// The backend enforces the limit; these tests check the app reacts correctly
// to its responses (remaining_attempts, 429, errors) and never sends
// duplicate requests.

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sharkhire/core/network/api_exception.dart';
import 'package:sharkhire/core/network/auth_token_provider.dart';
import 'package:sharkhire/core/network/http_api_client.dart';
import 'package:sharkhire/core/theme/app_theme.dart';
import 'package:sharkhire/features/authentication/data/repositories/auth_repository.dart';
import 'package:sharkhire/features/authentication/domain/session.dart';
import 'package:sharkhire/features/authentication/presentation/providers/resend_verification_provider.dart';
import 'package:sharkhire/features/authentication/presentation/providers/session_provider.dart';
import 'package:sharkhire/features/authentication/presentation/screens/verify_email_screen.dart';
import 'package:sharkhire/shared/models/app_user.dart';

import 'helpers.dart';

const _email = 'sara.malik@example.com';
const _unverified = Session(
  user: AppUser(fullName: 'Sara Malik', email: _email),
);

/// Auth repository whose resend answers are scripted per test.
class _ScriptedAuth extends MockAuthRepository {
  _ScriptedAuth(this.answers);

  /// Each call takes the next answer: a result, an exception, or a
  /// Completer (to hold the request open).
  final List<Object> answers;
  int calls = 0;

  @override
  Future<ResendVerificationResult> resendVerificationEmail(String email) async {
    final answer = answers[calls++];
    if (answer is Completer<ResendVerificationResult>) return answer.future;
    if (answer is ResendVerificationResult) return answer;
    throw answer;
  }
}

ProviderContainer _container(_ScriptedAuth auth) {
  final c = ProviderContainer(
    overrides: [authRepositoryProvider.overrideWithValue(auth)],
  );
  addTearDown(c.dispose);
  return c;
}

ResendVerificationController _ctrl(ProviderContainer c) =>
    c.read(resendVerificationProvider(_email).notifier);

ResendVerificationState _state(ProviderContainer c) =>
    c.read(resendVerificationProvider(_email));

void main() {
  group('Resend controller (backend is the source of truth)', () {
    test('first and second resend, then disabled at remaining 0', () async {
      final c = _container(
        _ScriptedAuth([
          const ResendVerificationResult(
            message: 'Verification email sent.',
            remainingAttempts: 1,
          ),
          const ResendVerificationResult(
            message: 'Verification email sent.',
            remainingAttempts: 0,
          ),
        ]),
      );
      await _ctrl(c).resend();
      expect(_state(c).notice, 'Verification email sent.');
      expect(_state(c).remainingAttempts, 1);
      expect(_state(c).canResend, isTrue);

      await _ctrl(c).resend();
      expect(_state(c).remainingAttempts, 0);
      expect(_state(c).limitReached, isTrue);
      expect(_state(c).canResend, isFalse);
    });

    test('HTTP 429 disables resending', () async {
      final auth = _ScriptedAuth([
        const RateLimitedException(
          message: resendLimitMessage,
          remainingAttempts: 0,
        ),
      ]);
      final c = _container(auth);
      await _ctrl(c).resend();
      expect(_state(c).limitReached, isTrue);
      expect(_state(c).remainingAttempts, 0);
      // Further taps send nothing.
      await _ctrl(c).resend();
      expect(auth.calls, 1);
    });

    test('no limit is assumed when the backend does not report one', () async {
      final c = _container(
        _ScriptedAuth([
          for (var i = 0; i < 4; i++)
            const ResendVerificationResult(message: 'Sent.'),
        ]),
      );
      for (var i = 0; i < 4; i++) {
        await _ctrl(c).resend();
      }
      expect(_state(c).limitReached, isFalse);
      expect(_state(c).remainingAttempts, isNull);
    });

    test('taps while a request is in flight send nothing', () async {
      final pending = Completer<ResendVerificationResult>();
      final auth = _ScriptedAuth([pending]);
      final c = _container(auth);
      final first = _ctrl(c).resend();
      expect(_state(c).sending, isTrue);
      await _ctrl(c).resend();
      await _ctrl(c).resend();
      pending.complete(const ResendVerificationResult(message: 'Sent.'));
      await first;
      expect(auth.calls, 1);
      expect(_state(c).sending, isFalse);
    });

    test('network failure shows an error and allows retry', () async {
      final c = _container(_ScriptedAuth([const NetworkException()]));
      await _ctrl(c).resend();
      expect(_state(c).noticeTone, ResendNoticeTone.error);
      expect(_state(c).notice, contains('No internet connection'));
      expect(_state(c).canResend, isTrue);
    });

    test('server and expired-link errors show the backend message', () async {
      final c = _container(
        _ScriptedAuth([
          const ValidationException(
            'Email link is invalid or has expired',
            code: 'otp_expired',
          ),
        ]),
      );
      await _ctrl(c).resend();
      expect(_state(c).notice, 'Email link is invalid or has expired');
      expect(_state(c).canResend, isTrue);
    });

    test('already-verified account', () async {
      final c = _container(
        _ScriptedAuth([
          const ValidationException(
            'Email is already confirmed.',
            code: 'email_already_confirmed',
          ),
        ]),
      );
      await _ctrl(c).resend();
      expect(_state(c).alreadyVerified, isTrue);
      expect(_state(c).canResend, isFalse);
      expect(_state(c).noticeTone, ResendNoticeTone.info);
    });
  });

  group('HTTP layer', () {
    HttpApiClient client(int status, String body) => HttpApiClient(
      baseUrl: 'https://api.example.test',
      tokens: const NoTokenProvider(),
      client: MockClient((_) async => http.Response(body, status)),
    );

    test('200 envelope keeps the message and remaining_attempts', () async {
      final res = await client(
        200,
        '{"success":true,"message":"Verification email sent.","data":{"remaining_attempts":1},"error":null}',
      ).postEnvelope('/api/v1/auth/resend-verification');
      expect(res.message, 'Verification email sent.');
      expect(res.remainingAttempts, 1);
    });

    test('live backend response today (no remaining_attempts)', () async {
      final res = await client(
        200,
        '{"success":true,"message":"If an account exists for this email, a message has been sent.","data":null,"error":null}',
      ).postEnvelope('/api/v1/auth/resend-verification');
      expect(res.message, startsWith('If an account exists'));
      expect(res.remainingAttempts, isNull);
    });

    test('429 keeps the backend message and remaining_attempts 0', () async {
      await expectLater(
        client(
          429,
          '{"success":false,"message":"$resendLimitMessage","data":{"remaining_attempts":0},"error":{"code":"resend_limit_reached","message":"$resendLimitMessage"}}',
        ).postEnvelope('/api/v1/auth/resend-verification'),
        throwsA(
          isA<RateLimitedException>()
              .having((e) => e.message, 'message', resendLimitMessage)
              .having((e) => e.remainingAttempts, 'remaining', 0),
        ),
      );
    });
  });

  group('Verify email screen', () {
    Future<_ScriptedAuth> pumpScreen(
      WidgetTester tester,
      List<Object> answers, {
      ProviderContainer? container,
    }) async {
      usePhone(tester);
      final auth = _ScriptedAuth(answers);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            initialSessionProvider.overrideWithValue(_unverified),
            authRepositoryProvider.overrideWithValue(auth),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            home: const VerifyEmailScreen(),
          ),
        ),
      );
      await tester.pump();
      return auth;
    }

    Finder resendButton() =>
        find.widgetWithText(OutlinedButton, 'Resend email');

    testWidgets('initial screen asks the user to confirm their email', (
      tester,
    ) async {
      await pumpScreen(tester, const []);
      expect(find.text('Confirm your email'), findsOneWidget);
      expect(find.textContaining(_email), findsOneWidget);
      final button = tester.widget<OutlinedButton>(resendButton());
      expect(button.onPressed, isNotNull);
    });

    testWidgets('loading state while the request runs', (tester) async {
      final pending = Completer<ResendVerificationResult>();
      await pumpScreen(tester, [pending]);
      await tester.tap(resendButton());
      await tester.pump();
      expect(find.text('Sending…'), findsOneWidget);
      final button = tester.widget<OutlinedButton>(
        find.ancestor(
          of: find.text('Sending…'),
          matching: find.byType(OutlinedButton),
        ),
      );
      expect(button.onPressed, isNull);
      pending.complete(
        const ResendVerificationResult(
          message: 'Verification email sent.',
          remainingAttempts: 1,
        ),
      );
      await tester.pump();
      expect(find.text('Verification email sent.'), findsOneWidget);
      expect(find.text('1 resend left'), findsOneWidget);
      expect(find.textContaining('Resend in'), findsOneWidget);
      await tester.pump(const Duration(seconds: 31));
    });

    testWidgets('exact maximum-limit message and disabled button after 429', (
      tester,
    ) async {
      await pumpScreen(tester, [
        const RateLimitedException(
          message: 'Too many requests',
          remainingAttempts: 0,
        ),
      ]);
      await tester.tap(resendButton());
      await tester.pump();
      expect(
        find.text(
          "You've reached the maximum resend limit. Please try again later.",
        ),
        findsOneWidget,
      );
      final button = tester.widget<OutlinedButton>(
        find.widgetWithText(OutlinedButton, 'Resend limit reached'),
      );
      expect(button.onPressed, isNull);
    });

    testWidgets('state is kept when the screen is reopened', (tester) async {
      usePhone(tester);
      final auth = _ScriptedAuth([
        const RateLimitedException(remainingAttempts: 0),
      ]);
      final show = ValueNotifier(true);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            initialSessionProvider.overrideWithValue(_unverified),
            authRepositoryProvider.overrideWithValue(auth),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            home: ValueListenableBuilder(
              valueListenable: show,
              builder: (_, visible, _) => visible
                  ? const VerifyEmailScreen()
                  : const Scaffold(body: Text('Elsewhere')),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.tap(resendButton());
      await tester.pump();
      show.value = false;
      await tester.pump();
      expect(find.text('Elsewhere'), findsOneWidget);
      show.value = true;
      await tester.pump();
      expect(find.text(resendLimitMessage), findsOneWidget);
      expect(auth.calls, 1);
    });

    testWidgets('fits a small phone', (tester) async {
      await expectNoOverflowOnSmallPhone(
        tester,
        const VerifyEmailScreen(),
        session: _unverified,
        overrides: [
          authRepositoryProvider.overrideWithValue(
            _ScriptedAuth([const RateLimitedException(remainingAttempts: 0)]),
          ),
        ],
      );
    });
  });
}
