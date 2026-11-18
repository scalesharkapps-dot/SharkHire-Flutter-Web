# SharkHire – Frontend Release Roadmap

The feature milestones M0–M7 are in `mobile_app/ROADMAP.md`. This file tracks the **release-readiness** work toward publishing on Google Play and the App Store.

**Rules:**
- Flutter frontend and its Android/iOS configuration only; never backend work.
- Small steps; `flutter analyze` + `flutter test` after every change.
- Nothing is marked done unless it was verified.

| Phase | Goal | Status |
|---|---|---|
| R1 Audit | Inspect Android/iOS config, security, store requirements | ✅ 15 Nov 2026 |
| R2 Platform config | Android: INTERNET permission, release signing via `key.properties`, R8, https query. iOS: names, iPhone-only, portrait, export compliance. Version 1.0.0+1 | ✅ in code · ⬜ device builds |
| R3 Production safety | dev/staging/prod config files; production defaults to real data; misconfigured production build blocked; demo accounts, simulated Premium and unwired Google sign-in hidden in production | ✅ tested |
| R4 Integration fixes | CV upload MIME type, upload timeout, 401 → sign out, error handling on withdraw and email verification, real account deletion and data request via a repository | ✅ tested (5 new tests, 150 total) |
| R5 Real sign-in | Backend `/auth/*` (no Supabase SDK needed), secure token storage, refresh, session restore, roles from `/auth/me` | ✅ 17 Nov 2026 (unit + live error-path tests) |
| R6 API repositories | Job seeker: profile, preferences, jobs, recommendations, details, CV, saved jobs, applications | ✅ 17 Nov 2026 · Employer and admin ⬜ · notifications/alerts have no backend endpoints |
| R7 Server-side search | Explore query goes to `/jobs/search` (debounced) | ✅ · cursor paging ⬜ |
| R8 Device verification | Android phone + AAB; iPhone + Xcode archive + TestFlight | ⬜ needs the Android SDK and a Mac |
| R9 Store assets | Store screenshots at exact sizes from the production build, 512 px icon, feature graphic | ⬜ |
| R10 Store services (optional for v1) | Real in-app purchases, push notifications, Google + Apple sign-in | ⬜ |

Store publishing waits for R5–R8, plus the backend and legal texts (see `MOBILE_RELEASE_CHECKLIST.md` §0).
