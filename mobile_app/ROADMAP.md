# SharkHire Frontend Roadmap

Goal-based plan: each milestone moves on only when its success criteria are
met **and verified** (`flutter analyze` clean, `flutter test` green,
320 px phone layout test). No day limits.
Source: SharkHire Developer Project Guide – frontend sections §3.5–§3.10,
§3.18 and mockups 4.1–4.5. Mobile only (Android and iOS). Backend work is out of scope; all data is mock
data behind repositories until the API is available.

Legend: `[x]` done and verified · `[ ]` pending

## M0 – Foundation
- [x] Flutter project, Riverpod, GoRouter, Material 3, brand theme
- [x] Home, Explore (search, filters, sort), Saved, Profile on mock data
- [x] Network contracts, Appendix A enums, app icons, native splash

## M1 – Authentication & onboarding (guide §3.5, mockup 4.1)
- [x] Welcome screen
- [x] Login (email + password, Google button), validation, errors
- [x] Registration with role choice: Job Seeker / Employer
- [x] Forgot password
- [x] Email verification
- [x] Job preferences onboarding (location, categories, employment type, work mode, experience)
- [x] Session state + role-based routing (seeker app vs employer app), logout
- Success: a job seeker and an employer can each sign up and land in their own app.

## M2 – CV & resume intelligence (§3.5, mockup 4.2)
- [x] Upload CV: PDF/DOCX picker, type & size validation, privacy note
- [x] Processing steps (upload → extract → build profile → find matches)
- [x] Review extracted profile: edit skills, experience, education, certifications
- [x] Replace / remove CV; profile shows active CV
- Success: invalid files rejected; extracted data editable before matching.

## M3 – Job details & applying (§3.5, mockup 4.3)
- [x] Job details: external (source badge, apply on employer site, click tracked)
- [x] Job details: internal (job information table, required skills, instructions)
- [x] Match explanation with reasons
- [x] Internal apply form: choose CV, optional cover letter, submit, success state
- Success: both apply paths work; internal application appears in tracking.

## M4 – Tracking, notifications, account (§3.5, §3.8, mockup 4.4)
- [x] Applications list with all 7 statuses, detail with status history, withdraw
- [x] Notifications (matches, application updates, saved-job reminders, employer responses)
- [x] Job alerts management
- [x] Settings, privacy & security, help & support
- [x] Subscription: 3-day trial, $10/month, local price note, Restore Purchases, terms
- Success: every status renders; withdraw updates the list; subscription screen complete.

## M5 – Employer app (§3.6, mockup 4.5)
- [x] Employer navigation: Overview | Jobs | Applicants | Company
- [x] Overview with counts and recent applications
- [x] Create / edit job form (all §3.6 fields) → submitted as Pending
- [x] Manage jobs by status: Pending, Published, Rejected, Closed (close job)
- [x] Applicants by status, candidate details, change status
- [x] Company profile
- Success: new job starts Pending; candidate status changes persist in session.

## M6 – Admin panel inside the mobile app (§3.7, mockups 4.6–4.7)
The frontend is mobile only, so the admin panel is a third role in the same
app (admin accounts are never created in-app).
- [x] Admin role, demo admin account, role-based routing (Overview | Jobs | Users | More)
- [x] Overview: totals, pending approvals, JSearch usage vs plan limit, activity
- [x] Job approvals: approve / reject with required reason → audit log
- [x] Users (search, block, deactivate) and employers (verify / reject)
- [x] Applications, external listings, CV reports
- [x] Categories and skills, announcements
- [x] API monitoring, analytics, audit logs, platform settings
- Success: approve/reject writes an audit entry; every admin screen fits 320–430 px phones.

## M7 – Backend compatibility (reference: docs/backend_roadmap_reference.md)
Frontend-only preparation so the backend can be plugged in without
changing screens. No backend code is written here.
- [x] HTTP `ApiClient` (bearer token, timeouts, multipart upload) + status → typed error mapping (401/403/404/422/429/5xx, offline, timeout) + `/health`
- [x] Auth token provider (Supabase access token at integration)
- [x] `fromJson` / `toJson` + documented API shapes for jobs, job details, applications, profile, resumes, notifications; paginated responses
- [x] Real `Api*Repository` classes in separate files from `Mock*Repository`; providers switch on `ApiConfig.isConfigured`
- [x] Explore "Show more" pagination; friendly rate-limit / timeout / offline messages
- Success: analyze clean, all tests pass, mocks and API code clearly separated.

## QA – Release readiness (§3.18 frontend items)
- [x] Every screen: loading, empty, error states
- [x] 320 px and large-phone layout tests for all screens
- [x] Accessibility pass (labels, contrast, tap targets)
- [ ] Android release build – blocked: Android SDK not installed on this PC
- [ ] iOS build – needs macOS/Xcode or Codemagic (guide §3.17)

## Showcase – documentation (keep updated as the UI evolves)
- [x] Real screenshots of all 60 screens: `flutter test tool/showcase/capture_screens_test.dart` → `../frontend_showcase/screenshots/`
- [x] `frontend_showcase/FRONTEND_AUDIT_REPORT.md`, `README.md`, `index.html` (built by `python -I tool/build_showcase.py`)
- [x] Layout/text bugs found by the screenshots fixed (overview grid gap, missing → glyph, plurals)
