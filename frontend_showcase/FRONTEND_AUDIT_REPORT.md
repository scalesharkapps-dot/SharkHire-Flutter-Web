# SharkHire Frontend Audit Report

**Product:** SharkHire, the AI job-matching mobile app by SCALE SHARK (PRIVATE) LIMITED
**Scope:** Flutter mobile frontend only (Android and iOS). The backend (FastAPI, PostgreSQL, Supabase) belongs to the backend team and is out of scope.
**Audit date:** 14 November 2026
**Code audited:** `mobile_app/` (121 Dart source files, about 18,500 lines)

Every statement in this report was checked against the code, `flutter analyze`, `flutter test` and the screenshots in `screenshots/`. Each item has one of these statuses:

| Status | Meaning |
|---|---|
| ✅ **Implemented and tested** | The screen or flow exists and is covered by automated widget or unit tests. |
| 🟡 **Partially implemented** | The UI is complete, but part of it runs on mock data or waits for a backend or service. |
| ⏳ **Pending** | Not built yet, or blocked by something outside the frontend. |

---

## 1. Overview

SharkHire runs as one Flutter app with three role-based experiences:

- **Job seekers:**
  - Sign up, upload a CV, and review what the CV reader extracted.
  - Get matched jobs from internal and external sources, with match reasons.
  - Apply and track applications.
- **Employers:** post jobs (each goes to admin approval first), manage applicants and keep a company profile.
- **Admins:** approve or reject jobs, manage users and employers, and monitor the platform. Per the project instructions, this runs inside the mobile app, not on a website.

The whole UI flow works end to end today on realistic mock data. Mock data and real API code are kept apart behind repository interfaces, so the backend can be connected without rewriting screens.

## 2. Technology stack

| Area | Choice |
|---|---|
| Framework | Flutter 3.50 / Dart 3.14, mobile only (Android + iOS) |
| State management | Riverpod 3.5 (`Notifier`, `NotifierProvider`, `FutureProvider.family`, `AsyncValue`) |
| Navigation | GoRouter 18 with three `StatefulShellRoute`s (seeker, employer, admin) and a pure `routeGuard` function for role and onboarding rules |
| Networking | `package:http` `HttpApiClient` with bearer token, timeouts and typed errors (401, 403, 404, 422 with field errors, 429 with retry-after, 5xx, network) |
| Data | Repository interfaces with `Mock*` and `Api*` implementations, chosen by `ApiConfig.isConfigured`; JSON mappers use the database's snake_case names and Appendix A enum values |
| Design system | Scale Shark brand tokens (navy `#0E2134`, ocean `#066CBE`, cyan `#10AFEE`, teal `#18ACC3`); Archivo Black, Archivo and Hind fonts bundled in the app |
| Other packages | `file_picker` (CV), `url_launcher` (external apply), `flutter_launcher_icons`, `flutter_native_splash` |
| Architecture | Feature-first folders (guide §3.14): `core/`, `shared/`, `features/<feature>/{data,presentation}` |

## 3. Features and screens

60 real screenshots are in `screenshots/`, grouped in 8 categories. The gallery is in `index.html`.

| Area | What exists | Status |
|---|---|---|
| **Authentication** | Splash, welcome, log in, register with role choice, forgot password, email verification, job-preference onboarding, role-based routing, log out | ✅ UI and routing tested · 🟡 runs on a mock auth service (Supabase Auth not connected; Google sign-in button shows an explanation) |
| **Job seeker home and profile** | Home with greeting, CV prompt, recommended jobs, categories, recent jobs; profile with completion and menu; edit profile; edit job preferences | ✅ tested · 🟡 profile changes kept in memory only |
| **Job search** | Explore with search, quick filters, filter sheet, sort, paging ("Show more"); saved jobs | ✅ tested · 🟡 API repository ready, live data waits for backend |
| **Job details** | Internal job (job information, skills, instructions, Apply now) and external job (source badge, opens employer site, click tracked) | ✅ tested · 🟡 API repository ready |
| **Recommendations** | Match score ring, match level, plain-language reasons ("Your Flutter and Dart skills match this role") | ✅ UI tested · 🟡 scores come from mock data; real matching is a backend feature |
| **CV management** | Upload (PDF/DOCX, type and size checks, privacy note), 4-step processing view, review and correct extracted profile (skills, experience, education, certifications), replace/remove CV | ✅ tested · 🟡 API repository ready (upload, status polling, corrections) |
| **Applications** | Apply form (choose CV, cover letter), success screen, list with all 7 statuses, detail with progress and history, withdraw | ✅ tested · 🟡 kept in memory until the applications API exists |
| **Account** | Notifications (swipe to dismiss with Undo), job alerts, settings, privacy and security, help and support | ✅ tested · ⏳ push notifications not wired (needs Firebase/APNs setup) |
| **Subscription** | 3-day trial, $10/month, local price note, Restore Purchases, terms | ✅ UI tested · 🟡 purchase is simulated; real store billing not connected |
| **Employer** | Overview, manage jobs by status, create/edit job (all §3.6 fields; starts as Pending), fix and resubmit a rejected job, applicants by status, candidate details with status change, company profile | ✅ tested · 🟡 in-memory data |
| **Admin (inside the app)** | Overview, job approvals (reason required to reject), users, employers (verify), applications, external listings, CV reports, categories and skills, announcements, API monitoring (JSearch quota), analytics, audit logs, platform settings | ✅ tested · 🟡 in-memory data |

## 4. UI/UX assessment

**Strengths (verified in the screenshots):**

- Real Scale Shark branding throughout: logo, navy and ocean palette, Archivo and Hind fonts. No copied third-party branding; the Glassdoor screenshots were used only as layout inspiration.
- Every list has loading skeletons, an empty state with a next step, and an error state with Retry.
- Plain, friendly copy. For example, CV results warn "Automatic reading can miss details" and invite corrections.
- Clear status language: colored status chips, an application progress stepper and history, and job approval states for employers.
- Accessibility checked by automated tests:
  - 48 px minimum tap targets
  - labelled buttons
  - WCAG AA text contrast (several brand colors were darkened slightly to pass)
- The source of each job is always shown ("Apply in-app · Verified employer" versus external site), as the guide §3.9 asks.

**Points to improve:**

- The app is light-theme only; dark mode is not designed yet.
- The app is English only; Urdu is not localised.
- Admin category cards: the "+ Skill" button sits slightly lower than the skill chips when they share a row (cosmetic).
- The screens have not yet been reviewed on a physical phone by a designer. The screenshots are rendered by Flutter's own engine (see section 6).

## 5. Backend readiness

| Item | Status |
|---|---|
| Endpoint list from guide §3.13 in `core/network/api_endpoints.dart` (extra ones marked **PROPOSED**) | ✅ |
| HTTP client with token, timeouts and typed errors; friendly error messages in the UI | ✅ tested |
| JSON mappers for jobs, job details, applications, profile, resume, pagination; unknown enum values fall back safely | ✅ tested |
| `Api*` repositories for jobs (internal + external merged without duplicates), job details, CV | ✅ tested with fake API |
| `Api*` repositories for applications, saved jobs, notifications, profile, employer, admin | ⏳ these still use in-memory Riverpod controllers |
| Supabase Auth client and `AuthTokenProvider` | ⏳ needs the company's Supabase URL and anon key |
| JSON shapes agreed with the backend team | ⏳ the mappers document the expected shapes; they need confirmation |

Turning the API on is a build setting, not a code change:

```
--dart-define=API_BASE_URL=https://… --dart-define=USE_MOCK_DATA=false
```

## 6. Responsive behavior and how screenshots were made

- Layouts are tested automatically on a **320 px small phone** and a **430 px large phone**, with no overflow allowed.
- Screenshots are **real renders of the app's own widgets**, not mock-ups.
  - They are captured with `tool/showcase/capture_screens_test.dart` on a 390 × 844 pt iPhone-size screen.
  - The screen includes a simulated status bar and home indicator, and uses the bundled fonts, real logo and shadows.
  - The data shown is the app's own sample data.
- They are **not photos from a physical device**. No Android or iOS device build has been made yet (see section 9).
- Rendering with a notch area revealed one layout bug, now fixed: grids on the employer and admin overviews added an empty gap above the stat tiles (see section 8).

## 7. Testing

| Check | Result |
|---|---|
| `flutter analyze` | **No issues found** |
| `flutter test` | **145 tests, all passing** (11 test files) |
| Test areas | unit (validators, enums, route guard, models), auth flow, seeker app, CV flow, apply flow, account screens, employer, admin, QA (states, small/large phones, accessibility), API layer |
| Manual device testing | ⏳ not possible yet (no Android SDK on the development PC; iOS needs macOS) |

## 8. Bugs found and fixed

**Found while preparing this showcase:**

- Employer and admin overview grids added the status-bar height as an empty gap, and the admin stat tiles were too tall. Fixed with zero grid padding and a fixed tile height.
- The application progress line used an arrow character (→) missing from the Hind font, so it showed as an empty box. Replaced with "›", which Hind includes.
- API monitoring said "1 results". The plural is now correct.

**Fixed earlier in development:**

- Tests were flaky because of lazily built lists.
- The splash logo flashed empty.
- Small 320 px phones had overflows in job cards, chips, profile rows, employer cards and admin tiles.
- A widget updated itself after it was closed.
- Notification Undo used a closed widget.
- The filter sheet opened under the tab bar.
- Several colors and tap targets failed accessibility checks.
- The `file_picker` 13 API change broke CV picking.

## 9. Pending work

1. **Real backend connection:**
   - Remaining `Api*` repositories (applications, saved jobs, notifications, profile, employer, admin).
   - Supabase Auth.
   - Final JSON shapes agreed with the backend team.
2. **Device builds:**
   - Android needs the Android SDK installed.
   - iOS needs macOS/Xcode or a CI service such as Codemagic.
   - Then test on real phones.
3. **Store services:** real in-app purchase for the subscription, push notifications (Firebase / APNs), and Google sign-in.
4. **Legal texts:** Terms of Use and Privacy Policy must come from Scale Shark. The app shows a placeholder notice and no invented legal text.
5. **Nice to have:** dark mode, Urdu localisation, and a designer review on physical devices.
6. **Repository:** the project is not in Git yet. The guide expects the company GitHub repository.

## 10. Progress summary

| Milestone | Status |
|---|---|
| M0 Foundation | ✅ |
| M1 Authentication and onboarding | ✅ (mock auth) |
| M2 CV upload, processing, review | ✅ (mock + API repository) |
| M3 Job details, match explanation, apply | ✅ |
| M4 Applications, notifications, account, subscription | ✅ (mock purchase) |
| M5 Employer app | ✅ (in-memory data) |
| M6 Admin panel in the mobile app | ✅ (in-memory data) |
| QA: states, small/large phones, accessibility | ✅ |
| M7 Backend-compatibility layer | ✅ for jobs, job details and CV · ⏳ other areas |
| Android / iOS device builds | ⏳ blocked by tooling |
| Live backend integration | ⏳ waits for the backend |

**In one sentence:** the frontend's UI is complete and tested for all three roles on mock data. The remaining work is connecting it to the real backend and services, and building and testing it on real devices.
