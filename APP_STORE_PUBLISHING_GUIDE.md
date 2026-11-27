# SharkHire – Connecting the Backend and Publishing (Beginner Guide)

You publish the app yourself. Claude never submits, signs in to your accounts, or buys anything.
The terminal commands run from the `mobile_app` folder unless the step says otherwise.

**Order of work:**
- **Part A:** connect the backend.
- **Part B:** build for Android.
- **Part C:** build for iOS.
- **Part D:** fill in the store listings.
- **Part E:** submit and handle review.

---

## Part A – Connecting the backend

> **Update 17 Nov 2026:** the app is connected to `https://backend-job-search.onrender.com`. Run it with `flutter run --dart-define-from-file=config/staging.json`. What's connected and what's missing is in `docs/BACKEND_INTEGRATION_STATUS.md`. The app needs **no Supabase keys**: the backend handles sign-in. The original instructions below are kept for reference.

### A1. What switches on automatically
These features already have real API code. They use the server as soon as you build with the settings file in A2:

- Jobs list
- Job details and external "Apply" click tracking
- CV upload, processing and review
- Generating matches
- Account deletion and data request

### A2. Create the settings file (no code changes)
1. Copy `mobile_app/config/production.example.json` to `mobile_app/config/production.json`.
2. Fill in the values from the backend team:
   ```json
   {
     "APP_ENV": "production",
     "USE_MOCK_DATA": "false",
     "API_BASE_URL": "https://api.your-domain.com",
     "SUPABASE_URL": "https://your-project.supabase.co",
     "SUPABASE_ANON_KEY": "the anon public key"
   }
   ```
   Do **not** put the Supabase service-role key or the JSearch key here. They stay on the server.
3. Do the same for `config/staging.json` using the test server.
4. Run against the test server:
   ```bash
   flutter run --dart-define-from-file=config/staging.json
   ```

If a value is missing or wrong in a production build, the app shows "This build is not configured" instead of starting. That screen tells you which value to fix.

### A3. What still needs frontend code before publishing
These parts still keep their data inside the app. Each needs a small API repository written in the Flutter app; no backend changes. Claude can build them, following the pattern of `features/settings/data/repositories/account_repository.dart`:

| Area | Server endpoint (from the project guide) |
|---|---|
| Sign in / sign up / email verification | Supabase Auth (`supabase_flutter`) + `GET /api/v1/auth/me` |
| Profile and job preferences | `GET/PUT /api/v1/profiles/me` |
| Saved jobs | `/api/v1/saved-jobs` |
| Applications | `POST /api/v1/applications`, `GET /api/v1/applications/me` |
| Recommendations | `GET /api/v1/job-matches` |
| Notifications and job alerts | to be added to the API |
| Employer jobs, applicants, company | `/api/v1/employer/...` |
| Admin panel | admin APIs (phase 7) |

When the API is up, check each JSON shape against the comments in `lib/shared/models/json_mappers.dart` and `features/*/data/models/*_json.dart`. If the backend team's field names differ, only those mapper files change, not the screens.

### A4. Test against the real server
Work through `MOBILE_RELEASE_CHECKLIST.md` §5 with the staging settings before building for the stores.

---

## Part B – Android (Google Play)

### B1. One-time setup on your PC
1. Install **Android Studio**: https://developer.android.com/studio. On first launch choose **Standard** setup; it installs the Android SDK.
2. Open a new terminal and accept the licences:
   ```bash
   flutter doctor --android-licenses
   ```
3. Check that `flutter doctor` shows ✓ next to "Android toolchain":
   ```bash
   flutter doctor
   ```

### B2. Create the upload key (once; keep it forever)
1. Make a folder **outside** OneDrive and outside the project, for example `C:\keys`.
2. Run (keytool comes with Android Studio):
   ```bash
   "C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe" -genkey -v -keystore C:\keys\sharkhire-upload.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```
   Choose a strong password and answer the name/organisation questions.
3. Copy `mobile_app/android/key.properties.example` to `mobile_app/android/key.properties` and fill it in:
   ```
   storePassword=your password
   keyPassword=your password
   keyAlias=upload
   storeFile=C:/keys/sharkhire-upload.jks
   ```
4. Back up `sharkhire-upload.jks` and the password somewhere safe, such as a password manager. **Never** commit them; `.gitignore` already excludes them.

### B3. Test on a real phone
1. On the phone, open **Settings → About phone** and tap **Build number** 7 times. Then go to **Developer options** and turn on **USB debugging**.
2. Connect the phone by USB and allow debugging.
3. Run:
   ```bash
   flutter run --release --dart-define-from-file=config/staging.json
   ```

### B4. Build the App Bundle (AAB)
1. Raise the build number in `pubspec.yaml` for every upload: `version: 1.0.0+1` → `1.0.0+2` → …
2. Build:
   ```bash
   flutter build appbundle --release --dart-define-from-file=config/production.json
   ```
3. The file is at `mobile_app\build\app\outputs\bundle\release\app-release.aab`.

### B5. Google Play Console
1. Go to https://play.google.com/console and create a developer account. Choose **Organization** for Scale Shark; it needs a D-U-N-S number.
   - **Personal accounts** created after Nov 2023 must run a **closed test with at least 12 testers for 14 days** before production.
   - Organization accounts skip that.
2. **Create app**:
   - App name: `SharkHire`
   - Default language: English (United States)
   - App or game: App
   - Free or paid: Free
   - Accept the declarations.
3. In the left menu, **Dashboard → Set up your app**, complete every task:
   - **Privacy policy:** paste the URL.
   - **App access:** "All or some functionality is restricted". Add the reviewer demo login.
   - **Ads:** No.
   - **Content rating:** fill the questionnaire (see D5).
   - **Target audience:** 18 and over. This avoids Families policy requirements for a job platform.
   - **News app:** No.
   - **Data safety:** see D6.
   - **Government app:** No.
   - **Financial features:** none.
   - **Health:** none.
   - **App category:** Business. Add contact details.
   - **Store listing:** see D1–D3, with graphics.

### B6. Upload and test
1. **Testing → Internal testing → Create new release.**
2. Accept **Play App Signing** (Google keeps the app signing key; your file is the upload key).
3. Upload `app-release.aab`. Release name: `1.0.0 (1)`. Paste the release notes (D7). Click **Next → Save → Start rollout to Internal testing**.
4. Under **Testers**, add your email list and open the opt-in link on your phone to install from Play.
5. When internal testing looks good: **Production → Create new release → Add from library** (pick the same build) → **Next → Start rollout**. Your app then enters review (D8).

---

## Part C – iOS (App Store)

### C1. What you need
- A **Mac** with the latest **Xcode** from the Mac App Store, **or** a CI service such as **Codemagic** (it builds iOS in the cloud from your Git repository).
- **Apple Developer Program** membership (https://developer.apple.com/programs/, yearly fee). Enroll as an **Organization** for Scale Shark; it needs a D-U-N-S number.
- The project in Git (company GitHub), so you can clone it on the Mac or Codemagic.

### C2. First build on the Mac
```bash
git clone <company repo> && cd <repo>/mobile_app
flutter pub get
flutter run --dart-define-from-file=config/staging.json
```
For a real iPhone, connect it by USB, trust the Mac, and turn on **Settings → Privacy & Security → Developer Mode**.

### C3. Signing
1. Open the Xcode workspace:
   ```bash
   open ios/Runner.xcworkspace
   ```
2. Click **Runner** (blue icon, top left) → **Runner** target → **Signing & Capabilities**.
3. Tick **Automatically manage signing**. For **Team**, choose Scale Shark. Xcode creates the App ID `io.thescaleshark.sharkhire` and profiles for you.

### C4. Create the app in App Store Connect
https://appstoreconnect.apple.com → **Apps → + → New App**:
- Platform: iOS
- Name: `SharkHire`
- Primary language: English (U.S.)
- Bundle ID: `io.thescaleshark.sharkhire`
- SKU: `sharkhire-ios`
- User access: Full Access

### C5. Build and upload
**Option 1 – Xcode:**
1. Raise the build number (`1.0.0+2` …), then on the Mac run:
   ```bash
   flutter build ios --release --dart-define-from-file=config/production.json
   ```
2. In Xcode, choose **Any iOS Device (arm64)** as the destination → menu **Product → Archive**.
3. The Organizer opens. Select the archive → **Validate App** (fix anything it reports) → **Distribute App → App Store Connect → Upload**.

**Option 2 – IPA + Transporter:**
1. Build the IPA:
   ```bash
   flutter build ipa --release --dart-define-from-file=config/production.json
   ```
2. The IPA is at `build/ios/ipa/`. Open **Transporter** (free on the Mac App Store), sign in, drag the `.ipa` in and click **Deliver**.

The build appears in App Store Connect after 10–30 minutes of processing.

### C6. TestFlight
1. App Store Connect → your app → **TestFlight**.
2. **Internal testing:** create a group, add team members (up to 100). They install the **TestFlight** app and get the build right away.
3. **External testing:** create a group and add emails or a public link. The first build needs a short **Beta App Review**; fill in **Test Information** with the demo account.

### C7. Submit for review
1. App Store Connect → your app → **App Store** tab → version **1.0**:
   - screenshots
   - promotional text, description, keywords (D1–D3)
   - support URL, marketing URL (optional)
   - **Build:** click **+** and choose the uploaded build
2. **App Privacy:** fill in using D6.
3. **Age Rating:** fill in using D5. **Category:** Business.
4. **App Review Information:** sign-in required → enter the demo account and contact details. Add a note:
   > SharkHire is a job platform. Use the job-seeker demo account. Employer posting needs admin approval.
5. Click **Add for Review → Submit**.

---

## Part D – Store listing material (drafts – edit freely)

### D1. Names
- App name: **SharkHire**
- Apple subtitle (30 characters): `AI job matches from your CV` (27 characters)
- Google short description (80 characters): `Upload your CV once. Get jobs worldwide ranked by how well they fit you.` (72 characters)

### D2. Full description (both stores)
> SharkHire, by Scale Shark, matches you to jobs using your CV.
>
> Upload your CV once (PDF or Word) and SharkHire reads your skills, experience and education. You check and correct the details, then every job is ranked by how well it fits you, with a plain explanation of why.
>
> • Jobs worldwide in one place, from LinkedIn, Indeed, Glassdoor, ZipRecruiter, Monster, CareerBuilder and more
> • Match score and reasons for every job
> • Search and filter by job type, work mode, region and city (Karachi, Lahore, Islamabad and more)
> • Save jobs and set job alerts
> • Apply in-app to verified employers, or on the employer's own site for external jobs
> • Track every application: submitted, under review, shortlisted, interview, decision
> • Your CV stays private and is only shared with an employer when you apply
>
> For employers: post jobs, review applicants with match scores and manage each candidate's status. Every job is reviewed by SharkHire before it goes live.

Only describe Premium in the listing once real in-app purchases are connected; it's hidden in production builds until then. When it is live, say plainly: the free trial includes 5 job applications, and each Premium purchase adds 5 more.

Keep the job-sites line only if the backend really lists jobs from those sites (checklist B9).

### D3. Keywords (Apple, 100 characters, comma-separated)
`jobs,job search,careers,CV,resume,hiring,worldwide,Pakistan,remote jobs,recruitment,apply,job match`

### D4. Graphics

| Asset | Google Play | Apple App Store |
|---|---|---|
| App icon | 512×512 PNG, 32-bit. Export from the 1024 px icon in `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png` | Taken from the build automatically |
| Feature graphic | 1024×500 PNG/JPG (required) | – |
| Phone screenshots | 2–8, 9:16, each side 320–3840 px | 6.9" iPhone: 1320×2868 (or 1290×2796), 1–10 images |
| Tablet / iPad screenshots | Not needed (phone app) | Not needed (iPhone-only build) |
| App preview video | Optional (YouTube link) | Optional (15–30 s) |

Take store screenshots from the **production** build with real or representative data, on the profile/home, CV review, job details, applications and employer screens. The `frontend_showcase/` images show sample data and are 780×1688; use them as a guide, not as final store images.

### D5. Content / age rating guidance
Answer honestly for what the app does:
- no violence, sexual content, profanity, drugs, gambling or alcohol
- no unrestricted web browser inside the app (external jobs open in the phone's own browser)
- users do **not** chat with each other
- employers publish job posts, which admins moderate before publishing

Expected outcome: Apple **4+** (or 9+/12+ if you mark user-generated content); Google **Everyone** or **Teen**. Use whatever the questionnaire gives.

### D6. Data safety (Google) and App Privacy (Apple)
Fill in from what the app collects. **Confirm the server-side parts with the backend team** (where data is stored, retention, which AI service reads CVs):

| Data | Collected | Purpose | Shared |
|---|---|---|---|
| Name, email, phone (optional) | Yes | Account, app functionality | With employers **only when the user applies** |
| City / country (typed, not GPS) | Yes | Job matching | With employers when applying |
| CV files and extracted text (documents) | Yes | Job matching, applications | With employers when applying; with an AI parsing service **only if the user enables "AI-assisted CV reading"** |
| Job applications, saved jobs, preferences | Yes | App functionality | Application data with that employer |
| App interactions (external apply clicks) | Yes | Analytics for the platform | No |
| Precise location, contacts, photos, health, financial info | **No** | – | – |

- Tracking / ads: **No** (no ad SDKs, no third-party tracking).
- Encrypted in transit: **Yes** (production builds only accept https).
- Users can request deletion: **Yes**, in-app (Profile → Privacy & security → Delete account).

### D7. Release notes (1.0.0)
> First release of SharkHire: upload your CV, get jobs worldwide ranked by fit with clear reasons, filter by city, apply and track your applications. Employers can post jobs and manage applicants.

### D8. Review times
Google: a few hours to 7 days for a new app. Apple: usually 24–48 hours.

---

## Part E – If the app is rejected

1. Read the message fully.
   - Apple: **App Store Connect → App Review → Resolution Center**.
   - Google: **Play Console → Inbox / Policy status**.
2. Common causes and fixes for this app:

   | Message | Fix |
   |---|---|
   | Can't sign in / demo account doesn't work | Make sure the demo account exists on the **production** backend; update App Review Information / App access |
   | 5.1.1(v) account deletion | Show them Profile → Privacy & security → Delete account; the backend endpoint must work |
   | Missing privacy policy | Add a working public URL in the listing **and** check it opens from the app |
   | 4.8 Sign in with Apple | Only if Google sign-in is enabled. Add Sign in with Apple at the same time |
   | 2.1 incomplete / placeholder content | Premium and Google sign-in are already hidden in production; check no other screen shows sample data |
   | ITMS-90683 missing purpose string | Add the Info.plist key named in the email with a true, specific sentence |
   | Data safety mismatch (Google) | Update the Data safety form to match D6 and the backend's real behaviour |
   | Target API level too low (Google) | Update Flutter (`flutter upgrade`), rebuild, raise the build number |

3. Fix, raise the build number, rebuild, upload. Reply in the Resolution Center / appeal form explaining what changed.
4. If you disagree, reply politely with screenshots or a screen recording. Apple also has an appeal form.
