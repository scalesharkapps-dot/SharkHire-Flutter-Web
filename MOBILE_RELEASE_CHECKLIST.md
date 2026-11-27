# SharkHire – Mobile Release Checklist

Last updated: 27 Nov 2026.

Legend:
- ✅ done and verified here
- 🔧 done in code, but not verifiable on this PC
- ⬜ not done or not tested yet
- 👤 you must do or provide this

**Nothing is marked "passed" unless it was actually run.**

## 0. Release blockers (must be cleared before any store submission)

| # | Blocker | Status |
|---|---|---|
| B1 | Real backend connected and tested | 🔧 Job-seeker flows connected to `backend-job-search.onrender.com` (17 Nov 2026), unit + live smoke tests pass. Signed-in flows not yet tested with a real account. See `docs/BACKEND_INTEGRATION_STATUS.md`. |
| B2 | Employer app and admin panel not yet connected (endpoints exist); notifications and job alerts have no backend endpoints | ⬜ |
| B3 | Real sign-in, saved session, token refresh | ✅ via the backend's `/auth/*`, tokens in secure storage (unit-tested) |
| B7 | Backend: account deletion endpoint (store requirement), CORS for web, always-on hosting | ⬜ Backend team |
| B4 | Terms of Use and Privacy Policy published at public URLs | 👤 From Scale Shark (legal) |
| B5 | Android release built and tested on a phone | ⬜ The Android SDK is not installed on this PC |
| B6 | iOS archive built and tested on an iPhone | ⬜ Needs a Mac with Xcode (or Codemagic) |
| B8 | 5-application limit (free trial: 5; each Premium purchase: 5 more) | 🔧 App side done (counter, used-up sheet, Premium page line). Still needed: **backend** counts applications and blocks the 6th; **stores** need a one-time "5 applications" product (Premium is a monthly subscription today, so "Buy Premium again" can't complete); `SUBSCRIPTIONS_ENABLED=true` in the store and Vercel builds, or the limit stays off. |
| B9 | Intro line "Jobs from LinkedIn, Indeed, Glassdoor, ZipRecruiter, Monster, CareerBuilder & more" | 👤 Confirm the backend really lists jobs from these sites before launch (store reviewers reject claims the app can't back up). Names only, no logos. |

## 1. Android configuration

| Item | Status | Detail |
|---|---|---|
| Application ID | ✅ | `io.thescaleshark.sharkhire` (can't change after the first upload) |
| App name | ✅ | `android:label="SharkHire"` |
| Launcher icon | ✅ | Branded Scale Shark icon, adaptive icon (`mipmap-anydpi-v26`), no Flutter default |
| Splash screen | ✅ | Brand navy native splash, Android 12+ splash icon |
| INTERNET permission in the release manifest | ✅ | **Was missing** (only debug/profile had it): a release build could not have reached the API. Fixed. |
| Permissions | ✅ | INTERNET only. CVs are picked with the system file picker, so no storage or camera permission is requested. |
| Package visibility for external links (Android 11+) | ✅ | `<queries>` VIEW `https` for `url_launcher` |
| Release signing | 🔧 | `build.gradle.kts` reads `android/key.properties` (git-ignored); template in `android/key.properties.example`. Without it the build falls back to debug signing, which Play rejects. |
| R8 / resource shrinking | 🔧 | `isMinifyEnabled = true`, `isShrinkResources = true`. Verify with a release build on a phone. |
| min / target SDK | 🔧 | Flutter 3.50 defaults (`flutter.minSdkVersion` / `flutter.targetSdkVersion`). Confirm target SDK ≥ the current Play requirement when you build: Play shows an error on upload if it's too low. |
| Version | ✅ | `1.0.0+1` in `pubspec.yaml` (`+1` = versionCode; raise it for every upload) |
| AAB build | ⬜ | `flutter build appbundle --release --dart-define-from-file=config/production.json` (needs the Android SDK) |

## 2. iOS configuration

| Item | Status | Detail |
|---|---|---|
| Bundle identifier | ✅ | `io.thescaleshark.sharkhire` |
| Display name / bundle name | ✅ | `SharkHire` (bundle name was lowercase `sharkhire`; fixed) |
| App icons | ✅ | Full `AppIcon.appiconset`, 1024 px marketing icon **without alpha** (Apple rejects alpha) |
| Launch screen | ✅ | `LaunchScreen.storyboard`, brand navy |
| Devices | ✅ | iPhone only (`TARGETED_DEVICE_FAMILY = 1`). Was iPhone + iPad; iPad layouts were never designed or tested, and iPad builds need iPad screenshots. |
| Orientation | ✅ | Portrait (Info.plist matches the Dart portrait lock) |
| Export compliance | ✅ | `ITSAppUsesNonExemptEncryption = false` (standard HTTPS only), so no compliance question on every upload |
| Privacy permission strings | ✅ | None needed: the CV picker uses the system document picker. If App Store Connect emails "ITMS-90683 Missing purpose string", add the key it names to `ios/Runner/Info.plist`. |
| Deployment target | ✅ | iOS 15.0 |
| Signing | 👤 | Xcode → Runner → Signing & Capabilities → choose your Team; "Automatically manage signing" is on |
| Archive / IPA | ⬜ | On a Mac: `flutter build ipa --release --dart-define-from-file=config/production.json` |

## 3. App configuration and security

| Item | Status | Detail |
|---|---|---|
| Separate dev / staging / production settings | ✅ | `mobile_app/config/*.example.json`; real files git-ignored |
| Production can't run on sample data | ✅ | Production defaults to `USE_MOCK_DATA=false`. A misconfigured production build (mock data, non-https or localhost API, missing Supabase values) shows a "not configured" screen instead of the app. Tested. |
| Demo accounts hidden in production | ✅ | Shown only when mock data is on |
| HTTPS only in production | ✅ | Enforced by the production check |
| No secrets in the app | ✅ | Only the Supabase **anon** key (public by design). JSearch and service-role keys stay on the backend. |
| Secrets not committed | ✅ | `.gitignore`: `key.properties`, `*.jks`, `*.keystore`, `.env*`, `config/*.json` |
| Logging | ✅ | No `print`/`debugPrint` in app code |
| Debug banner | ✅ | Off |
| Expired session (401) | ✅ | Signs the user out and returns to login. Tested. |
| CV upload MIME type | ✅ | Now sends `application/pdf` / DOCX type (was `octet-stream`; the backend could have rejected it). Tested. |
| Long uploads | ✅ | 2-minute upload timeout (normal requests 30 s) |
| In-app account deletion (Apple 5.1.1(v), Google Play policy) | 🔧 | **Was fake** (showed "requested", sent nothing). Now calls the account repository (`DELETE /api/v1/profiles/me`, PROPOSED), shows real errors, signs out. Backend endpoint pending. |
| Data export request | 🔧 | Same fix (`POST /api/v1/profiles/me/data-export`, PROPOSED) |
| Unfinished features hidden in production | ✅ | Premium purchase (simulated) and "Continue with Google" (not wired) are hidden in production builds until real billing and OAuth exist |
| Secure token storage | ⬜ | Comes with the Supabase repository (B3) |

## 4. Quality

| Check | Status |
|---|---|
| `flutter analyze` | ✅ No issues (15 Nov 2026) |
| `flutter test` | ✅ 150 tests passed (15 Nov 2026) |
| Small (320 px) and large (430 px) phone layouts, accessibility | ✅ Automated tests |
| Real screenshots of all 60 screens | ✅ `frontend_showcase/` |
| Runtime on a real Android phone | ⬜ Not performed |
| Runtime on a real iPhone | ⬜ Not performed |
| Performance profiling on a device | ⬜ Not performed |

## 5. Pre-submission tests (fill in as you go)

### Android
- [ ] `flutter run` (debug) on a physical Android phone
- [ ] `flutter build apk --release --dart-define-from-file=config/staging.json`, then install and test on a phone
- [ ] `flutter build appbundle --release --dart-define-from-file=config/production.json` succeeds
- [ ] Sign up, verify email, log in, log out (real Supabase)
- [ ] CV upload (PDF and DOCX) and review against the real API
- [ ] Search, filters, job details, external apply opens the browser
- [ ] Apply in-app, see the application, withdraw it
- [ ] Employer: post a job; admin: approve it; job appears for seekers
- [ ] Delete account works end to end
- [ ] Airplane mode: friendly offline messages, no crash
- [ ] Internal testing track install from Play works

### iOS
- [ ] Runs in the iOS Simulator (iPhone 15/16)
- [ ] Runs on a physical iPhone (debug)
- [ ] Release configuration with `config/production.json`
- [ ] Xcode archive succeeds and validates (Organizer → Validate App)
- [ ] Upload to App Store Connect succeeds; build appears in TestFlight
- [ ] TestFlight install and the same flows as Android

## 6. Information you must provide (👤)

1. Google Play Developer account (organization account recommended for Scale Shark; needs a D-U-N-S number).
2. Apple Developer Program membership (organization; D-U-N-S number).
3. Privacy Policy URL and Terms of Use URL (public web pages).
4. Support email and support website URL. The app currently shows `support@thescaleshark.io`. **Confirm this inbox exists**, or tell me the right address.
5. Production `API_BASE_URL`, `SUPABASE_URL` and `SUPABASE_ANON_KEY` (from the backend).
6. A reviewer demo account (job seeker) on the production backend, for Apple and Google reviewers.
7. The Android upload keystore you create (keep it and its passwords backed up).
8. Store screenshots from the production build (see the guide for sizes).
9. Answers only the backend can give for the privacy forms: where data is stored, retention periods, and which AI service reads CVs.
