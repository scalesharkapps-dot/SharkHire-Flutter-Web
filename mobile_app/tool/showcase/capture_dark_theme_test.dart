// Captures the main screens in the dark theme (documentation tool, not part
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

const _light = bool.fromEnvironment('LIGHT');
const _out = _light
    ? '../frontend_showcase/screenshots/11_signal_light'
    : '../frontend_showcase/screenshots/10_dark_theme';
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

  testWidgets('dark theme tour', (tester) async {
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
            initialSessionProvider.overrideWithValue(_seeker),
            initialThemeModeProvider.overrideWithValue(
              _light ? ThemeMode.light : ThemeMode.dark,
            ),
          ],
          child: const SharkHireApp(),
        ),
      ),
    );
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.pump(MockJobs.latency + const Duration(milliseconds: 400));
    await _shot(tester, '01_home');

    Future<void> tab(String label, String name) async {
      await tester.tap(find.text(label).last);
      await tester.pumpAndSettle();
      await tester.pump(MockJobs.latency + const Duration(milliseconds: 400));
      await _shot(tester, name);
    }

    await tab('Explore', '02_explore');
    await tab('Saved', '03_saved');
    await tab('Profile', '04_profile');

    await tester.tap(find.text('Home').last);
    await tester.pumpAndSettle();
    await tester.pump(MockJobs.latency + const Duration(milliseconds: 400));
    await tester.tap(find.text('Senior Flutter Developer').first);
    await tester.pumpAndSettle();
    await tester.pump(MockJobs.latency + const Duration(milliseconds: 400));
    await _shot(tester, '06_job_details');
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Profile').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    await _shot(tester, '05_settings_appearance');
  });
}
