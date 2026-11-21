import 'dart:async';
// Captures REAL screenshots of the SharkHire app for the frontend showcase.
//
// Renders the actual app (real widgets, theme, bundled fonts, Material icons
// and the official logo) with Flutter's own engine in the test runner, using
// the app's mock data. Nothing is mocked visually.
//
// Run from mobile_app/:
//   flutter test tool/showcase/capture_screens_test.dart
// Output: ../frontend_showcase/screenshots/<category>/<name>.png (780 × 1688)
//
// This is a documentation tool, not part of the app or its test suite.

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sharkhire/app.dart';
import 'package:sharkhire/core/routing/app_router.dart';
import 'package:sharkhire/features/authentication/domain/session.dart';
import 'package:sharkhire/features/authentication/presentation/providers/session_provider.dart';
import 'package:sharkhire/features/resume/data/models/resume_models.dart';
import 'package:sharkhire/features/resume/data/repositories/resume_repository.dart';
import 'package:sharkhire/features/resume/presentation/providers/cv_provider.dart';
import 'package:sharkhire/features/saved_jobs/presentation/providers/saved_jobs_provider.dart';
import 'package:sharkhire/shared/models/app_user.dart';
import 'package:sharkhire/shared/models/domain_enums.dart';

const _out = '../frontend_showcase/screenshots';
final _frame = GlobalKey();

// ── Sample sessions ─────────────────────────────────────────────────────────
const _seeker = Session(
  user: AppUser(
    fullName: 'Ayesha Khan',
    email: 'ayesha.khan@example.com',
    headline: 'Flutter Developer',
    location: 'Lahore, Pakistan',
    profileCompletion: 0.45,
  ),
  emailVerified: true,
  onboardingComplete: true,
);
const _seekerWithCv = Session(
  user: AppUser(
    fullName: 'Ayesha Khan',
    email: 'ayesha.khan@example.com',
    headline: 'Flutter Developer',
    location: 'Lahore, Pakistan',
    profileCompletion: 0.9,
    hasCv: true,
  ),
  emailVerified: true,
  onboardingComplete: true,
);
const _newSeeker = Session(
  user: AppUser(fullName: 'Sara Malik', email: 'sara.malik@example.com'),
);
const _verifiedNewSeeker = Session(
  user: AppUser(fullName: 'Sara Malik', email: 'sara.malik@example.com'),
  emailVerified: true,
);
const _employer = Session(
  user: AppUser(
    fullName: 'Bilal Ahmed',
    email: 'employer@sharkhire.app',
    roles: {AppRole.employer},
  ),
  emailVerified: true,
  onboardingComplete: true,
);
const _admin = Session(
  user: AppUser(
    fullName: 'Sana Iqbal',
    email: 'admin@sharkhire.app',
    roles: {AppRole.admin},
  ),
  emailVerified: true,
  onboardingComplete: true,
);

class _CvUploaded extends CvController {
  @override
  CvState build() => CvState(
    active: Resume(
      id: 'cv-1',
      fileName: 'Ayesha_Khan_CV.pdf',
      sizeBytes: 241000,
      uploadedAt: DateTime.now().subtract(const Duration(days: 2)),
      status: ResumeStatus.processed,
    ),
  );
}

class _SomeSaved extends SavedJobIdsNotifier {
  @override
  Set<String> build() => {'job-01', 'job-03', 'job-07'};
}

// ── Harness ─────────────────────────────────────────────────────────────────
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

/// Starts the real app on a 390 × 844 phone with status-bar and home-bar insets.
Future<void> _launch(
  WidgetTester tester,
  Session session, {
  List<Override> overrides = const [],
}) async {
  debugDisableShadows = false;
  addTearDown(() => debugDisableShadows = true);
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
          initialSessionProvider.overrideWithValue(session),
          ...overrides,
        ],
        child: const SharkHireApp(),
      ),
    ),
  );
  await tester.pump();
}

/// Opens [path]. With [from], opens that screen first and then pushes [path]
/// on top, the way a user gets there (so the back arrow shows).
Future<void> _go(
  WidgetTester tester,
  String path, {
  String? from,
  Duration wait = const Duration(milliseconds: 1500),
}) async {
  final router = ProviderScope.containerOf(
    tester.element(find.byType(SharkHireApp)),
  ).read(appRouterProvider);
  if (from != null) {
    router.go(from);
    await tester.pump();
    await tester.pumpAndSettle();
    unawaited(router.push(path));
  } else {
    router.go(path);
  }
  await tester.pump();
  await tester.pump(wait);
  await tester.pumpAndSettle();
}

Future<void> _shot(
  WidgetTester tester,
  String category,
  String name, {
  bool settle = true,
}) async {
  if (settle) await tester.pumpAndSettle();
  // Decode every image (logo) before capturing.
  await tester.runAsync(() async {
    for (final e in find.byType(Image).evaluate()) {
      await precacheImage((e.widget as Image).image, e);
    }
  });
  await tester.pump(const Duration(milliseconds: 50));
  if (settle) await tester.pumpAndSettle();
  final boundary =
      _frame.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  final bytes = await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 2);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    return data!.buffer.asUint8List();
  });
  File('$_out/$category/$name.png')
    ..createSync(recursive: true)
    ..writeAsBytesSync(bytes!);
  // Visible text of the screen, used to check the showcase descriptions.
  final view = tester.view.physicalSize / tester.view.devicePixelRatio;
  final texts = <String>[
    for (final e in find.byType(RichText).evaluate())
      if (_onScreen(e, view)) (e.widget as RichText).text.toPlainText(),
  ];
  File('build/showcase_text/$category/$name.txt')
    ..createSync(recursive: true)
    ..writeAsStringSync(
      texts
          .where(
            (t) => t.trim().isNotEmpty && t.codeUnits.every((c) => c < 0xE000),
          )
          .join(String.fromCharCode(10)),
    );
}

bool _onScreen(Element e, Size view) {
  final box = e.renderObject;
  if (box is! RenderBox || !box.hasSize || !box.attached) return false;
  final r = box.localToGlobal(Offset.zero) & box.size;
  return r.bottom > 0 &&
      r.top < view.height &&
      r.right > 0 &&
      r.left < view.width;
}

Future<void> _scroll(WidgetTester tester, double dy) async {
  await tester.drag(find.byType(Scrollable).first, Offset(0, -dy));
  await tester.pumpAndSettle();
}

/// The list screen a detail [path] is opened from, or null for tab roots.
String? _parentOf(String path, List<String> parents) {
  for (final p in parents) {
    if (path.startsWith('$p/')) return p;
  }
  return null;
}

// ── Screens ─────────────────────────────────────────────────────────────────
void main() {
  setUpAll(_loadFonts);

  const auth = '01_authentication';
  testWidgets('splash', (t) async {
    await _launch(t, Session.signedOut);
    // Step frame by frame so the fade-in animation actually plays.
    for (var i = 0; i < 17; i++) {
      await t.pump(const Duration(milliseconds: 100));
    }
    await _shot(t, auth, '01_splash', settle: false);
    await t.pump(const Duration(seconds: 3));
  });
  testWidgets('welcome', (t) async {
    await _launch(t, Session.signedOut);
    await _go(t, '/welcome');
    await _shot(t, auth, '02_welcome');
  });
  testWidgets('login', (t) async {
    await _launch(t, Session.signedOut);
    await _go(t, '/login', from: '/welcome');
    await _shot(t, auth, '03_login');
  });
  testWidgets('register', (t) async {
    await _launch(t, Session.signedOut);
    await _go(t, '/register', from: '/welcome');
    await _shot(t, auth, '04_register');
  });
  testWidgets('forgot', (t) async {
    await _launch(t, Session.signedOut);
    await _go(t, '/forgot-password', from: '/login');
    await _shot(t, auth, '05_forgot_password');
  });
  testWidgets('verify', (t) async {
    await _launch(t, _newSeeker);
    await _go(t, '/verify-email');
    await _shot(t, auth, '06_verify_email');
  });
  testWidgets('preferences', (t) async {
    await _launch(t, _verifiedNewSeeker);
    await _go(t, '/onboarding/preferences');
    await _shot(t, auth, '07_job_preferences');
  });

  const seeker = '02_job_seeker';
  testWidgets('home', (t) async {
    await _launch(t, _seeker);
    await _go(t, '/home');
    await _shot(t, seeker, '01_home');
  });
  testWidgets('profile', (t) async {
    await _launch(
      t,
      _seekerWithCv,
      overrides: [cvProvider.overrideWith(_CvUploaded.new)],
    );
    await _go(t, '/profile');
    await _shot(t, seeker, '02_profile');
    await _scroll(t, 700);
    await _shot(t, seeker, '03_profile_menu');
  });
  for (final (name, path) in const [
    ('04_notifications', '/notifications'),
    ('05_job_alerts', '/job-alerts'),
    ('06_subscription', '/subscription'),
    ('07_settings', '/settings'),
    ('08_privacy_security', '/settings/privacy'),
    ('09_help_support', '/help'),
    ('10_edit_profile', '/profile/edit'),
    ('11_edit_job_preferences', '/preferences'),
  ]) {
    testWidgets(name, (t) async {
      await _launch(t, _seeker);
      await _go(t, path, from: path == '/notifications' ? '/home' : '/profile');
      await _shot(t, seeker, name);
    });
  }

  const search = '03_job_search';
  testWidgets('explore', (t) async {
    await _launch(t, _seeker);
    await _go(t, '/explore');
    await _shot(t, search, '01_explore');
    await t.tap(find.byTooltip('Filters'));
    await t.pumpAndSettle();
    await _shot(t, search, '02_filters');
  });
  testWidgets('job details', (t) async {
    await _launch(
      t,
      _seekerWithCv,
      overrides: [cvProvider.overrideWith(_CvUploaded.new)],
    );
    await _go(t, '/jobs/job-01', from: '/explore');
    await _shot(t, search, '03_job_details_internal');
    await _scroll(t, 650);
    await _shot(t, search, '04_job_details_info');
    await _go(t, '/jobs/job-02', from: '/explore');
    await _shot(t, search, '05_job_details_external');
  });
  testWidgets('saved', (t) async {
    await _launch(
      t,
      _seeker,
      overrides: [savedJobIdsProvider.overrideWith(_SomeSaved.new)],
    );
    await _go(t, '/saved');
    await _shot(t, search, '06_saved_jobs');
  });

  const recs = '04_recommendations';
  testWidgets('recommendations', (t) async {
    await _launch(
      t,
      _seekerWithCv,
      overrides: [cvProvider.overrideWith(_CvUploaded.new)],
    );
    await _go(t, '/home');
    await _shot(t, recs, '01_home_with_cv');
    await _scroll(t, 420);
    await _shot(t, recs, '02_recommended_jobs');
    await _scroll(t, 900);
    await _shot(t, recs, '03_categories_and_recent');
    await _go(t, '/jobs/job-03', from: '/home');
    await _shot(t, recs, '04_match_explanation');
  });

  const cv = '05_cv_management';
  testWidgets('cv upload', (t) async {
    await _launch(
      t,
      _seeker,
      overrides: [
        cvPickerProvider.overrideWithValue(
          () async =>
              const PickedCvFile(name: 'Ayesha_Khan_CV.pdf', sizeBytes: 241000),
        ),
        resumeRepositoryProvider.overrideWithValue(
          const MockResumeRepository(stepDelay: Duration(seconds: 2)),
        ),
      ],
    );
    await _go(t, '/cv/upload?from=onboarding');
    await _shot(t, cv, '01_upload_cv');
    await t.tap(find.text('Choose a file'));
    await t.pumpAndSettle();
    await _shot(t, cv, '02_file_selected');
    await t.tap(find.text('Upload and analyse'));
    for (var i = 0; i < 25; i++) {
      await t.pump(const Duration(milliseconds: 100));
    }
    await _shot(t, cv, '03_processing', settle: false);
    await t.pump(const Duration(seconds: 8));
    await t.pumpAndSettle();
    await _shot(t, cv, '04_review_profile');
    await _scroll(t, 700);
    await _shot(t, cv, '05_review_experience');
  });
  testWidgets('cv invalid', (t) async {
    await _launch(
      t,
      _seeker,
      overrides: [
        cvPickerProvider.overrideWithValue(
          () async => const PickedCvFile(
            name: 'portfolio_photo.png',
            sizeBytes: 900000,
          ),
        ),
      ],
    );
    await _go(t, '/cv/upload', from: '/profile');
    await t.tap(find.text('Choose a file'));
    await t.pumpAndSettle();
    await _shot(t, cv, '06_invalid_file_rejected');
  });

  const apps = '06_applications';
  testWidgets('apply', (t) async {
    await _launch(
      t,
      _seekerWithCv,
      overrides: [cvProvider.overrideWith(_CvUploaded.new)],
    );
    await _go(t, '/jobs/job-01/apply', from: '/jobs/job-01');
    await t.enterText(
      find.byType(TextField).last,
      'I have shipped two Flutter apps to the Play Store and would love to help Indus Ledger build its next product.',
    );
    await t.pumpAndSettle();
    await _shot(t, apps, '01_apply_form');
    await _go(t, '/applications/app-4/sent');
    await _shot(t, apps, '02_application_sent');
    await _go(t, '/applications', from: '/profile');
    await _shot(t, apps, '03_my_applications');
    await _go(t, '/applications/app-4', from: '/applications');
    await _shot(t, apps, '04_application_timeline');
    await _go(t, '/applications/app-3', from: '/applications');
    await _scroll(t, 600);
    await _shot(t, apps, '05_withdraw_option');
  });

  const emp = '07_employer';
  for (final (name, path) in const [
    ('01_overview', '/employer'),
    ('02_manage_jobs', '/employer/jobs'),
    ('03_create_job', '/employer/jobs/new'),
    ('04_fix_rejected_job', '/employer/jobs/ej-4/edit'),
    ('05_applicants', '/employer/applicants'),
    ('06_candidate_details', '/employer/applicants/c-1'),
    ('07_company_profile', '/employer/company'),
  ]) {
    testWidgets('employer $name', (t) async {
      await _launch(t, _employer);
      await _go(
        t,
        path,
        from: _parentOf(path, const ['/employer/jobs', '/employer/applicants']),
      );
      await _shot(t, emp, name);
    });
  }

  const adm = '08_admin';
  for (final (name, path) in const [
    ('01_overview', '/admin'),
    ('02_job_approvals', '/admin/jobs'),
    ('03_users', '/admin/users'),
    ('04_more_modules', '/admin/more'),
    ('05_employers', '/admin/employers'),
    ('06_applications', '/admin/applications'),
    ('07_external_listings', '/admin/external-jobs'),
    ('08_cv_reports', '/admin/cv-reports'),
    ('09_categories', '/admin/categories'),
    ('10_announcements', '/admin/announcements'),
    ('11_api_monitoring', '/admin/api-monitoring'),
    ('12_analytics', '/admin/analytics'),
    ('13_audit_logs', '/admin/audit-logs'),
    ('14_platform_settings', '/admin/settings'),
  ]) {
    testWidgets('admin $name', (t) async {
      await _launch(t, _admin);
      await _go(
        t,
        path,
        from:
            const {
              '/admin',
              '/admin/jobs',
              '/admin/users',
              '/admin/more',
            }.contains(path)
            ? null
            : '/admin/more',
      );
      await _shot(t, adm, name);
    });
  }
}
