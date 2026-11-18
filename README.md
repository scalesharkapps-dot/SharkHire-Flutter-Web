# SharkHire – Flutter Frontend

SharkHire is a job-search and hiring app by **Scale Shark**. It matches job seekers in Pakistan and abroad to jobs from their CV, and has employer and admin areas. This repository holds the **Flutter frontend** for Android, iOS and the web. The backend (FastAPI) lives in a separate repository.

| Folder / file | What it is |
|---|---|
| `mobile_app/` | The Flutter app (Riverpod, GoRouter); Android, iOS and Web |
| `mobile_app/vercel.json`, `mobile_app/tool/vercel_build.sh` | Vercel deployment (builds Flutter, serves `build/web`) |
| `WEB_DEPLOYMENT_GUIDE.md` | Step-by-step Vercel deployment |
| `APP_STORE_PUBLISHING_GUIDE.md`, `MOBILE_RELEASE_CHECKLIST.md` | Google Play / App Store preparation |
| `docs/BACKEND_INTEGRATION_STATUS.md` | Which backend endpoints the app uses |
| `frontend_showcase/` | Screenshots of the app's screens |

## Run locally
Requires Flutter 3.50 (Dart 3.14).

Install packages (from `mobile_app/`):
```bash
flutter pub get
```
Run with built-in sample data:
```bash
flutter run
```
Run against the real backend. First copy `config/staging.example.json` to `config/staging.json`, then:
```bash
flutter run --dart-define-from-file=config/staging.json
```
Run the checks:
```bash
flutter analyze
```
```bash
flutter test
```

## Deploy the web app (Vercel)
1. Import this repository on Vercel.
2. Set **Root Directory** to `mobile_app`.
3. Click **Deploy**.

No environment variables or secrets are needed: the site forwards `/api/*` to the backend. See `WEB_DEPLOYMENT_GUIDE.md`.

## Configuration and security
- **Build-time settings:** the app only uses `APP_ENV`, `USE_MOCK_DATA` and `API_BASE_URL` (see `mobile_app/.env.example`). All of them are public by nature, because a web app ships its settings to the browser.
- **No secrets in this repo:** there are no API keys or secrets here, and none belong here. The backend keeps its own secrets.
- **Never commit:** real config files (`config/*.json`), Android signing keys (`key.properties`, `*.jks`) and `.env` files are git-ignored.

© SCALE SHARK (PRIVATE) LIMITED. All rights reserved.
