# SharkHire Frontend – Backend Integration Readiness

**Audit date:** 14 November 2026
**Scope:** `mobile_app/` (Flutter). The backend was not inspected or changed.
**Method:** I read the code. `flutter analyze` reports no issues and `flutter test` passes (145 tests). Nothing below is marked ready unless the code was read and, where possible, a test exercises it.

## Verdict

**Not fully ready.**

- **The networking foundation is solid and tested:**
  - HTTP client and typed errors
  - JSON mappers and enums
  - Feature-first architecture with repository interfaces
- **Only 3 of about 15 data areas can switch to the real API today:** jobs list, job details, and CV upload/review.
- **Everything else** keeps its data in in-memory Riverpod controllers with sample data built in. That covers applications, saved jobs, notifications, profile, preferences, employer, admin and settings.
- **Authentication is not wired.** No Supabase SDK, no token, no saved session.

Connecting the backend will **not** require an architecture change: the folder structure, router, theme and network layer stay as they are. It **will** require a moderate amount of planned work:

- About 12 new repositories.
- About 18 controllers changed from synchronous lists to asynchronous loading.
- At least 18 screen files updated to show loading and error states for that data.
- Real authentication.

Most of this can be done **before** the backend exists, against a fake API, so that integration day is mostly configuration.

---

## 1. Ready (verified)

| Item | Evidence |
|---|---|
| API client contract | `core/network/api_client.dart`: GET/POST/PUT/PATCH/DELETE + multipart upload interface. |
| HTTP implementation | `core/network/http_api_client.dart`: base URL from `--dart-define=API_BASE_URL`, `Authorization: Bearer <token>` when a token exists, JSON encode/decode, 30 s timeout. |
| Typed errors | `api_exception.dart` covers network, timeout, 401, 403, 404, 400/422 (FastAPI `detail[].loc` mapped to field errors), 429 (`Retry-After`) and 5xx, plus `friendlyErrorMessage()`. Tested in `test/api_layer_test.dart`. |
| Environment switch | `ApiConfig.isConfigured` = URL set **and** `USE_MOCK_DATA=false`. No hard-coded hosts and no secrets in the app. |
| Pagination model | `Paginated<T>` expects `{items, page, page_size, total}`. Tested. |
| Database enums (Appendix A) | All 7 Postgres enums mirrored value for value in `shared/models/domain_enums.dart`; unknown values fall back safely. Tested. |
| Jobs list (phase 4, part) | `ApiJobsRepository` merges `/api/v1/jobs` and `/api/v1/job-search/external` without duplicates. Tested with a fake API. |
| Job details + external apply click | `ApiJobDetailsRepository`; `apply_url` and `match_reasons` mapped; click sent to `/external-apply-clicks`. |
| CV flow (phase 3, part) | `ApiResumeRepository`: multipart upload, polling `/resumes/me` until `processed`/`failed`, parsed profile, corrections, then `POST /job-matches/generate`. Picker passes the file path. |
| Mock vs real separation (for these 3 areas) | `mock_*_repository.dart` and `api_*_repository.dart` in separate files, chosen in one provider. |
| UI states for job lists, job details, apply, CV | Shared `AsyncJobSliver` (loading skeleton, empty, error + Retry), plus error handling in the apply and CV screens. |
| Client-side validation | Email, password, name, CV type/size (PDF/DOCX ≤ 5 MB), job form fields. Tested. |
| Role-based navigation (phase 2 UI) | Pure `routeGuard` for signed-out, unverified, onboarding, job seeker, employer and admin. Tested. |

## 2. Partially ready

| Item | What exists | What is missing |
|---|---|---|
| **Auth (phase 2)** | `AuthRepository` interface (sign in/up, reset, verify, sign out) and `AuthTokenProvider` interface | Only `MockAuthRepository`, hard-wired. `authTokenProvider` always returns **no token**, so every real API call would be sent unauthenticated and get 401. |
| **Profile (phase 3)** | `appUserFromJson` (`/auth/me`) and `profileUpdateToJson` (`/profiles/me`) mappers | No repository calls them. Edit profile only updates local state. `AppUser` has no `id`. |
| **Job search (phase 4)** | API repository for the first page | Search text, filters (Pakistan/international, type, work mode) and paging are applied **on the phone** to page 1 only. Phase 4 needs them sent to the server: the `JobsRepository.fetchJobs()` signature needs query, filter and page parameters. |
| **Recommendations (phase 5)** | UI shows `match_score` and `match_reasons` from job data; `generateMatches` is called after CV processing | `GET /api/v1/job-matches` is declared but never called. Home sorts the generic job list instead of loading the user's matches. `features/job_matches/` is empty. |
| **Applications (phase 6)** | `applicationFromJson` with status history; endpoints declared | `ApplicationsController` holds built-in sample data; apply and withdraw only change local state. No repository. |
| **Notifications (phase 6)** | `notificationFromJson` | Endpoint not declared; controller holds sample data. |
| **CV upload details** | Upload works | `UploadFile.contentType` is set but **not sent** in the multipart request. The file arrives as `application/octet-stream`, and the backend may reject it because it validates PDF/DOCX MIME types. One-line fix. |
| **Error handling for actions** | Login, register, forgot password, apply, CV and subscription catch errors | Withdraw application, post/edit job, change applicant status, admin approve/reject and edit profile have **no try/catch**. On mock data they never fail; on a real API a failure would go unhandled. |
| **Server validation messages** | `ValidationException.fieldErrors` parsed | Never shown next to form fields. |

## 3. Missing

| Item | Notes |
|---|---|
| Supabase client SDK (`supabase_flutter`) | Not in `pubspec.yaml`. Needed for sign-in, sign-up, email verification and access tokens. |
| Session persistence and restore | The app always starts signed out (`initialSessionProvider`). Users would log in on every launch. |
| Token refresh and 401 handling | `UnauthorizedException` is never caught. An expired session should sign out and return to login. |
| Repositories for applications, saved jobs, notifications, job alerts, job preferences, profile, employer jobs, applicants, company, and all admin modules | These are in-memory controllers with sample data built in, so mock data is **not** separated here. |
| JSON mappers for employer, admin, job preferences, job alerts and settings | `employer_models.dart` and `admin_models.dart` have no `fromJson`/`toJson`. |
| Endpoints for notifications, job alerts, preferences, company, applicant status, and all admin APIs | Not declared in `api_endpoints.dart`. Unused declarations: `health`, `authMe`, `profileMe`, `resumeActivate`, `jobMatches`, `savedJobs`, `applications`, `applicationsMe`, `employerJobs`, `employerJob`, `employerApplications`. |
| Saved jobs shape | The app saves a plain job id. `saved_jobs` in Appendix A needs **either** `internal_job_id` **or** `external_job_id`, so the request must include the source. |
| Job preferences shape | App: `categories`, `includePakistan/International`, types, work modes, experience. Appendix A: `preferred_titles/countries/cities`, `minimum_salary`, `salary_currency`, with **no categories**. Needs a decision with the backend team. |
| Backend tables for some admin screens | Appendix A has no tables for categories/skills catalog, announcements, platform settings, API usage logs, analytics, subscriptions, or user block/deactivate status. These screens have no planned backend yet. |
| Real payments, push notifications, Google sign-in | Need store billing, Firebase/APNs and Supabase OAuth. |

## Backend roadmap phases vs frontend

| Phase | Frontend readiness |
|---|---|
| 1 Foundation | ✅ Ready: base URL, timeouts, typed errors. `/health` declared but unused (optional startup check). |
| 2 Authentication | ❌ Missing: Supabase SDK, token provider, saved session, 401 handling. UI and role routing are ready. |
| 3 Profile and CV | 🟡 Partial: CV ready (fix the MIME type); profile repository missing. |
| 4 JSearch | 🟡 Partial: list and details ready; server-side search, filters and paging missing; 429 message ready. |
| 5 Recommendations | 🟡 Partial: UI ready; `/job-matches` not called. |
| 6 Job management | ❌ Missing: saved jobs, applications, alerts and notifications are all in-memory. |
| 7 Employer and admin | ❌ Missing: all in-memory; no mappers; several admin areas have no planned tables. |
| 8 Production readiness | 🟡 Partial: 145 tests, no secrets, analyzer clean. No device build yet; no integration tests against a real API. |

## 4. Do before the backend team delivers the backend

In priority order. None of these needs the backend to exist: build each against a fake API, as `test/api_layer_test.dart` already does.

1. **Agree the API contract with the backend team:**
   - Request and response JSON for every endpoint.
   - Pagination format, error format and the auth header.
   - Saved-jobs source field and job-preferences fields.
   - Which admin features exist in v1.

   Ideally she shares the FastAPI OpenAPI schema early.
2. **Authentication:**
   - Add `supabase_flutter`.
   - Implement `SupabaseAuthRepository` and a real `AuthTokenProvider`.
   - Restore the session at launch.
   - Load roles from `/auth/me`.
   - On 401, sign out and return to login.

   Needs the company Supabase URL and anon key.
3. **Convert in-memory controllers to repositories, one feature at a time:**
   - Interface + `Mock*` + `Api*` repository.
   - Controller becomes an `AsyncNotifier`.
   - Screens show loading and error states.

   Order: profile/preferences → saved jobs → applications → notifications/alerts → employer → admin.
4. **Server-side job search:** add query, filter and page parameters to `JobsRepository`; Explore requests the next page instead of filtering locally.
5. **Recommendations:** load Home from `GET /job-matches`.
6. **Small fixes:**
   - Send the CV `contentType` in the multipart upload.
   - Add try/catch with friendly messages to every action.
   - Show `fieldErrors` next to form fields.
7. **Integration tests:** one fake-API test per repository, plus a smoke run against the backend's staging server when it's up.

Once 1–7 are done, connecting the real backend is a build setting:

```bash
flutter run --dart-define=API_BASE_URL=https://<staging-host> --dart-define=USE_MOCK_DATA=false
```
