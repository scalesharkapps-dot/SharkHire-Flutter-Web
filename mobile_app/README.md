# SharkHire – Mobile App (Flutter)

AI-powered job search and recruitment app for **SCALE SHARK (PRIVATE) LIMITED**.
**Mobile only:** Android and iOS from one Flutter codebase (no web build).
Three roles share the app: job seekers, employers and admins (`features/admin`). The backend (FastAPI + Supabase) is a
separate project owned by the backend team.

## Stack
- Flutter / Dart, Material 3
- Riverpod 3 (state management; no BLoC)
- GoRouter 18 (navigation, `StatefulShellRoute` for Home | Explore | Saved | Profile)
- Material 3 via `package:material_ui` (Flutter 3.50+ replacement for `flutter/material.dart`)
- Brand fonts bundled in `assets/fonts` (Archivo Black, Archivo, Hind – SIL OFL)

## Run
```bash
flutter pub get
flutter devices             # list connected phones / emulators
flutter run                 # run on an Android emulator, Android phone or iOS device
```

Optional build-time settings:
```bash
flutter run --dart-define=APP_ENV=staging --dart-define=API_BASE_URL=https://...
```

## Check
```bash
flutter analyze
flutter test
```

## Structure
```
lib/
  main.dart            entry point (ProviderScope)
  app.dart             MaterialApp.router + theme
  core/
    config/            environment & build flags (AppConfig)
    constants/         app constants, asset paths
    theme/             colours, typography, spacing, Material 3 theme
    routing/           route names + GoRouter provider
    network/           API contracts: endpoints, config, exceptions, ApiClient interface
                       (HTTP implementation added at backend integration)
    utils/             small helpers
  shared/
    widgets/           reusable UI (logo, job card, nav shell, …)
    models/            shared models; domain_enums.dart mirrors Appendix A enums
    data/              mock data used until the API is connected
  features/<feature>/
    data/              models, repositories, mock data
    domain/            business entities / rules
    presentation/      screens, widgets, providers
```

## Rules
- Never put API keys, the JSearch key or Supabase service-role key in this app.
- Use design tokens from `core/theme` – no hard-coded colours or sizes in widgets.
- Screens read data through repositories (e.g. `JobsRepository`); mock
  implementations are swapped for API ones at integration.
- App icons / native splash are generated from the official logo:
  `dart run flutter_launcher_icons` and `dart run flutter_native_splash:create`.
