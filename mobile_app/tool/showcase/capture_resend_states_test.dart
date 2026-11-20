// Captures the resend-verification states of the real Verify Email screen
// (documentation tool, not part of `flutter test`). Run:
//   flutter test tool/showcase/capture_resend_states_test.dart
// Output: ../frontend_showcase/screenshots/01_authentication/06b_*.png

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sharkhire/core/network/api_exception.dart';
import 'package:sharkhire/core/theme/app_theme.dart';
import 'package:sharkhire/features/authentication/data/repositories/auth_repository.dart';
import 'package:sharkhire/features/authentication/domain/session.dart';
import 'package:sharkhire/features/authentication/presentation/providers/session_provider.dart';
import 'package:sharkhire/features/authentication/presentation/screens/verify_email_screen.dart';
import 'package:sharkhire/shared/models/app_user.dart';

const _out = '../frontend_showcase/screenshots/01_authentication';
final _frame = GlobalKey();

class _Scripted extends MockAuthRepository {
  _Scripted(this.answers);
  final List<Object> answers;
  int _i = 0;

  @override
  Future<ResendVerificationResult> resendVerificationEmail(String email) async {
    final a = answers[_i++];
    if (a is ResendVerificationResult) return a;
    throw a;
  }
}

Future<void> _loadFonts() async {
  Future<ByteData> a(String p) => rootBundle.load('assets/fonts/$p');
  final icons = File(
    'C:/src/flutter/bin/cache/artifacts/material_fonts/materialicons-regular.otf',
  );
  await Future.wait([
    (FontLoader('ArchivoBlack')..addFont(a('ArchivoBlack-Regular.ttf'))).load(),
    (FontLoader('Archivo')
          ..addFont(a('Archivo-Medium.ttf'))
          ..addFont(a('Archivo-SemiBold.ttf'))
          ..addFont(a('Archivo-Bold.ttf')))
        .load(),
    (FontLoader('Hind')
          ..addFont(a('Hind-Regular.ttf'))
          ..addFont(a('Hind-Medium.ttf'))
          ..addFont(a('Hind-SemiBold.ttf'))
          ..addFont(a('Hind-Bold.ttf')))
        .load(),
    (FontLoader(
          'MaterialIcons',
        )..addFont(Future.value(ByteData.sublistView(icons.readAsBytesSync()))))
        .load(),
  ]);
}

Future<void> _launch(WidgetTester tester, List<Object> answers) async {
  tester.view.physicalSize = const Size(390, 844) * 3;
  tester.view.devicePixelRatio = 3;
  tester.view.padding = const FakeViewPadding(top: 47 * 3, bottom: 34 * 3);
  tester.view.viewPadding = const FakeViewPadding(top: 47 * 3, bottom: 34 * 3);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    RepaintBoundary(
      key: _frame,
      child: ProviderScope(
        overrides: [
          initialSessionProvider.overrideWithValue(
            const Session(
              user: AppUser(
                fullName: 'Sara Malik',
                email: 'sara.malik@example.com',
              ),
            ),
          ),
          authRepositoryProvider.overrideWithValue(_Scripted(answers)),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          home: const VerifyEmailScreen(),
        ),
      ),
    ),
  );
  await tester.pump();
}

Future<void> _shot(WidgetTester tester, String name) async {
  await tester.pump(const Duration(milliseconds: 600));
  final boundary =
      _frame.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  final bytes = await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 2);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    return data!.buffer.asUint8List();
  });
  File('$_out/$name.png')
    ..createSync(recursive: true)
    ..writeAsBytesSync(bytes!);
}

void main() {
  setUpAll(_loadFonts);
  Finder resend() => find.widgetWithText(OutlinedButton, 'Resend email');

  testWidgets('resend sent', (t) async {
    await _launch(t, [
      const ResendVerificationResult(
        message: 'Verification email sent. Check your inbox.',
        remainingAttempts: 1,
      ),
    ]);
    await t.tap(resend());
    await t.pump();
    await _shot(t, '06b_resend_sent');
    await t.pump(const Duration(seconds: 31));
  });

  testWidgets('resend limit', (t) async {
    await _launch(t, [
      const RateLimitedException(
        message:
            "You've reached the maximum resend limit. Please try again later.",
        remainingAttempts: 0,
      ),
    ]);
    await t.tap(resend());
    await t.pump();
    await _shot(t, '06c_resend_limit_reached');
  });

  testWidgets('resend network error', (t) async {
    await _launch(t, [const NetworkException()]);
    await t.tap(resend());
    await t.pump();
    await _shot(t, '06d_resend_network_error');
  });
}
