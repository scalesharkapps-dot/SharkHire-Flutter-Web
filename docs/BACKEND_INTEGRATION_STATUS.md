# SharkHire – Backend Integration Status

**Date:** 17 Nov 2026
**Backend:** `https://backend-job-search.onrender.com` (FastAPI)
- Swagger docs: `/docs`
- Version 1.0.0; its health check reports `environment: staging`.

**Spec reviewed:** the full OpenAPI document (`/openapi.json`, 90+ operations).

## How to run the app against the backend
```bash
cd mobile_app
flutter run --dart-define-from-file=config/staging.json
```
`config/staging.json` is ready, contains no secrets and is git-ignored. Production uses `config/production.json`, made the same way from `config/production.example.json`.

## How the backend works (relevant for the app)
- **Response envelope.** Every `/api/v1` response is `{success, message, data, error}`. The app unwraps `data` and reads `error.code` and `error.message`.
- **Sign-in.** The backend does sign-in itself (`/auth/login`, `/signup`, `/refresh`, `/logout`) and returns Supabase tokens. The app needs **no Supabase keys**.
- **Logged-in endpoints.** Every endpoint except health and `/jobs/filters` needs `Authorization: Bearer <access token>`.
- **Job search uses quota.** `/jobs/search` calls JSearch (RapidAPI), requires a query, and pages with a cursor.

## Integrated and tested

| Feature | Endpoints | Tests |
|---|---|---|
| Network layer | Envelope unwrap; error mapping (code, message, field errors); 60 s timeout, 2 min uploads | Unit tests with real error bodies; live: ✅ |
| Sign in | `POST /auth/login` → tokens → `GET /auth/me`, `/profile/me`, `/cv`, `/recommendations/preferences` | Unit ✅; live wrong-password path ✅ |
| Sign up and email confirmation | `POST /auth/signup`; on confirmation the app signs in with the details kept in memory | Unit ✅ |
| Forgot password, resend email | `POST /auth/forgot-password`, `/auth/resend-verification` | Code only |
| Token handling | Secure storage (Keychain / Keystore / web); refresh before expiry and once on 401 (`POST /auth/refresh`); sign out if refresh fails; `POST /auth/logout` | Unit ✅ |
| Stay signed in | Splash restores the saved session (up to 12 s) | Code only |
| Profile edit | `PATCH /profile/me` | Code only |
| Job preferences (onboarding + edit) | `GET/PUT /recommendations/preferences` | Mapping unit ✅ |
| Home / Explore default list | `GET /jobs/sharkhire` + `GET /recommendations/for-me` (no JSearch quota) | Unit ✅ |
| Job search | `GET /jobs/search?query=` (JSearch) + `/jobs/sharkhire?q=`; waits 0.6 s after typing, 2+ characters | Live: needs sign-in ✅ (401 path) |
| Job details + match reasons | `GET /jobs/{id}` + `GET /recommendations/jobs/{id}/match` | Mapping unit ✅ |
| CV upload / review / delete | `POST /cv/upload` (multipart, MIME type), `POST /cv/{id}/primary`, `GET/PATCH /cv/{id}/extracted-data`, `POST /cv/{id}/apply-to-profile`, `GET /cv`, `DELETE /cv/{id}` | Mapping unit ✅ |
| Saved jobs | `GET /saved-jobs`, `POST`/`DELETE /saved-jobs/{id}` (instant update, reverts on error) | Code only |
| Applications | `POST /applications`, `GET /applications`, `PATCH /applications/{id}/status` (withdraw); 12 backend statuses shown as the app's 7 stages | Mapping unit ✅ |

**Live tests run:**
- health ✅
- `/jobs/filters` ✅
- wrong login → "Invalid email or password." ✅
- search without login → `not_authenticated` ✅
- signed-in smoke test: **not run** (no test account)

Script: `mobile_app/tool/live_api_smoke_test.dart`.

**Full suite:** `flutter analyze` reports no issues; `flutter test` passes 161 tests.

## Bugs found and fixed during integration
- A wrong password returns 401. The old client treated every 401 as "session expired" and signed the user out. It now does that only for requests that carried a token.
- On Android the CV picker often returns a file without a path, so upload would have failed. The app now reads the file's bytes on every platform, which also fixes web.
- `dart:io` in the HTTP client would have broken Flutter Web compilation. Removed.
- A 30 s timeout was too short for the backend's cold starts. Now 60 s.
- Mocked "save" delays in Edit profile and Job preferences were replaced with real calls and error messages.

## Fixed after first browser test (17 Nov 2026)
- Saved jobs: sent `sort=newest`; the API accepts `saved_at|posted_at|title|match` → now `saved_at` (was 422).
- Applications: asked for 100 per page; the API maximum is 50 → now 50 (was 422).
- CV upload screen: always said "check your connection" and disabled retry; it now shows the server's reason and keeps the file so Upload can be pressed again.

## Not integrated yet (endpoints exist in the API)
- **Employer app:**
  - `/employers/register`, `/employers/me`, `/employer/jobs*`, `/employer/applications*`, `/employer/statistics`
  - Employer screens show **no sample data** in real-API mode (empty states) until connected.
- **Admin panel:** `/admin/*` (dashboard, users, employers, jobs moderation, reports, audit logs). Same empty states.
- **Interviews, reminders, statistics:** `/applications/{id}/interviews`, `/interviews/upcoming`, `/applications/statistics`, `/applications/reminders`.
- **Profile photo:** `/profile/me/photo`. Employer logo: `/employers/me/logo`.
- **Explore "Show more":** cursor paging (`pagination.next_cursor`); first page only for now.
- **Reports:** `/reports`.

## Missing in the backend (reported, not invented)

| Need | Status |
|---|---|
| **CV upload / file storage** | **`POST /cv/upload` returns 503 `storage_not_configured`** ("Supabase Storage is not configured."), seen 17 Nov 2026 with a real account; `GET /profile/me` also returns 503. Supabase Storage settings are missing on the Render deployment. The app now shows a clear message and lets the user retry. |
| Account deletion | **No endpoint.** Apple and Google require in-app deletion. The app now says plainly it isn't available yet. |
| Data export | No endpoint (same handling) |
| Notifications | No endpoint. The list is empty in real-API mode. |
| Job alerts | No endpoint. Alerts aren't saved on the server. |
| Admin categories/skills, announcements, platform settings, API usage monitoring, analytics | No endpoints (`/admin/dashboard` may cover some totals) |
| Employer sign-up role | `POST /auth/signup` has no role. Employers must call `POST /employers/register` with company details, and the app has no screen for that step yet, so an "Employer" sign-up currently becomes a job seeker. |
| Click tracking for external apply | No endpoint. The backend expects `POST /applications` to record external applications; the app doesn't offer an "I applied" step yet. |
| Web browser access (CORS) | The `OPTIONS` preflight returns **405**, so a Flutter **web** build will be blocked by the browser. Android and iOS are unaffected. The backend needs CORS middleware allowing the web origin. |
| Hosting cold starts | The first request after idle took ~29 s. Use an always-on plan before release. |

## Notes
- **Web platform:** the code stays web-compatible, but `mobile_app/web/` was removed earlier (mobile-only decision). Add it back with `flutter create --platforms=web .` if a web build is needed.
- **No test account:** none was created, because creating accounts on your server needs your go-ahead. To run the signed-in smoke test with your own test account:
  ```bash
  flutter test tool/live_api_smoke_test.dart --dart-define=SMOKE_EMAIL=you@example.com --dart-define=SMOKE_PASSWORD=yourpassword
  ```

## Web preview in Chrome (17 Nov 2026)

**Verified in the browser:**
- The web build compiles with no errors.
- The app opens at `http://localhost:5200` (splash, then Welcome).
- A login attempt reached the backend through the local proxy: preflight `204`, login `401`, and the app showed "Invalid email or password."

**CORS – confirmed blocked.** Called directly from `http://localhost:5200`, Chrome blocks every request:
- `GET /jobs/filters`: "No 'Access-Control-Allow-Origin' header is present"
- `POST /auth/login`: the preflight fails (`OPTIONS` → 405)

**Backend fix needed (not done here):** add FastAPI `CORSMiddleware` before the routers. Re-checked 17 Nov 2026: still 405 on preflight, with no CORS headers.
- `allow_origins`: from env var `CORS_ALLOWED_ORIGINS`, e.g. `https://<project>.vercel.app,https://<custom-domain>,http://localhost:5200,http://localhost:5210`
- `allow_origin_regex` (optional): only this project's Vercel preview URLs
- `allow_methods`: GET, POST, PUT, PATCH, DELETE, OPTIONS
- `allow_headers`: Authorization, Content-Type, Accept
- `allow_credentials`: False (bearer tokens, no cookies)
- `max_age`: 600
- **Never** `*`

The exact code, Render environment variables and a curl check are in `WEB_DEPLOYMENT_GUIDE.md` → "CORS configuration for the backend".

**Local workaround (development only):** `mobile_app/tool/dev_cors_proxy.py` forwards requests to the backend and adds CORS headers for localhost pages. Run each command in its own terminal, from `mobile_app/`:

```bash
python tool/dev_cors_proxy.py
```
```bash
flutter run -d chrome --web-port 5300 --dart-define-from-file=config/web-local.json
```

Or serve a release build:
```bash
flutter build web --release --dart-define-from-file=config/web-local.json
```
```bash
python -m http.server 5200 --bind 127.0.0.1 --directory build/web
```

Once the backend allows CORS, skip the proxy and use `config/staging.json` directly. Port 8080 is reserved on this PC, so use 5200/5300.
