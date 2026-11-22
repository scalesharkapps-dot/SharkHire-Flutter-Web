// Captures the Bold screens (documentation tool, not part
// of `flutter test`). Run:
//   flutter test tool/showcase/capture_dark_theme_test.dart
// Output: ../frontend_showcase/screenshots/10_dark_theme/*.png

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sharkhire/app.dart';
import 'package:sharkhire/core/theme/theme_mode_provider.dart';
import 'package:sharkhire/features/authentication/domain/session.dart';
import 'package:sharkhire/features/authentication/presentation/providers/session_provider.dart';
import 'package:sharkhire/features/job_search/data/mock_jobs.dart';
import 'package:sharkhire/shared/models/app_user.dart';

const _out = '../frontend_showcase/screenshots/12_bold';
final _frame = GlobalKey();

const _seeker = Session(
  user: AppUser(
    fullName: 'Ayesha Khan',
    email: 'seeker@sharkhire.app',
    headline: 'Flutter Developer',
    location: 'Lahore, Pakistan',
    profileCompletion: 0.45,
  ),
  emailVerified: true,
  onboardingComplete: true,
);

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

Future<void> _shot(WidgetTester tester, String name) async {
  await tester.pump(const Duration(milliseconds: 800));
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

  Future<void> boot(WidgetTester tester, Session session) async {
    tester.view.physicalSize = const Size(390, 844) * 3;
    tester.view.devicePixelRatio = 3;
    tester.view.padding = const FakeViewPadding(top: 47 * 3, bottom: 34 * 3);
    tester.view.viewPadding = const FakeViewPadding(
      top: 47 * 3,
      bottom: 34 * 3,
    );
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      RepaintBoundary(
        key: _frame,
        child: ProviderScope(
          overrides: [
            initialSessionProvider.overrideWithValue(session),
            initialThemeModeProvider.overrideWithValue(ThemeMode.light),
          ],
          child: const SharkHireApp(),
        ),
      ),
    );
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  testWidgets('welcome screens', (tester) async {
    await boot(tester, Session.signedOut);
    await _shot(tester, '01_welcome');
    await tester.tap(find.text('Hiring? Create an employer account'));
    await tester.pumpAndSettle();
    await _shot(tester, '02_employer_welcome');
  });

  testWidgets('roles and match', (tester) async {
    await boot(tester, _seeker);
    await tester.pump(MockJobs.latency + const Duration(milliseconds: 400));
    await tester.tap(find.text('Explore').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('By role'));
    await tester.pumpAndSettle();
    await _shot(tester, '03_roles');
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Senior Flutter Developer').first);
    await tester.pumpAndSettle();
    await tester.pump(MockJobs.latency + const Duration(milliseconds: 400));
    await _shot(tester, '04_job_match');
  });
}
