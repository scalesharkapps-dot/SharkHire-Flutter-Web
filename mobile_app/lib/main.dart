import 'package:material_ui/material_ui.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/config/app_config.dart';
import 'core/config/misconfigured_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Phone layouts, portrait only (matches the iOS/Android store configuration).
  // Browsers manage orientation and system bars themselves (Safari has no
  // orientation lock), so only phones get these calls.
  if (!kIsWeb) {
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  // A store build without its server settings must never run on sample data.
  final problem = AppConfig.isProduction
      ? AppConfig.productionConfigProblem
      : null;
  if (problem != null) {
    runApp(MisconfiguredApp(problem: problem));
    return;
  }

  runApp(const ProviderScope(child: SharkHireApp()));
}
