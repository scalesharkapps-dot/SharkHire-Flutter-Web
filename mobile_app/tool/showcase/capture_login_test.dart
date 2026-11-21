// Captures the Login screen with "Remember me" (documentation tool, not part
// of `flutter test`). Run:
//   flutter test tool/showcase/capture_login_test.dart [--dart-define=DARK=true]

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sharkhire/core/theme/app_theme.dart';
import 'package:sharkhire/features/authentication/data/login_preferences.dart';
import 'package:sharkhire/features/authentication/presentation/screens/login_screen.dart';

const _dark = bool.fromEnvironment('DARK');
const _out = '../frontend_showcase/screenshots/01_authentication';
final _frame = GlobalKey();

class _Prefs implements LoginPreferencesStore {
  @override
  Future<LoginPreferences> read() async =>
      const LoginPreferences(email: 'sara.malik@example.com');
  @override
  Future<void> write(LoginPreferences prefs) async {}
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

void main() {
  setUpAll(_loadFonts);

  testWidgets('login with remember me', (tester) async {
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
            loginPreferencesStoreProvider.overrideWithValue(_Prefs()),
          ],
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.build(dark: _dark),
            home: const LoginScreen(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final boundary =
        _frame.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final bytes = await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 2);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      return data!.buffer.asUint8List();
    });
    File('$_out/02b_login_remember_me${_dark ? '_dark' : ''}.png')
      ..createSync(recursive: true)
      ..writeAsBytesSync(bytes!);
  });
}
