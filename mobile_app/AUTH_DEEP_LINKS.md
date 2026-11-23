# Email links, password reset and account deletion

How SharkHire handles the links in Supabase emails (confirm email, reset
password), and what has to be configured **outside the Flutter app** for them
to work. Checked against the live API on 23 Nov 2026.

## Why the links opened `localhost:3000`

The backend tells Supabase where to send users after they click a link
(`backend_job_search/app/services/supabase_auth.py`):

| Backend env var | Used by | Currently |
|---|---|---|
| `AUTH_EMAIL_REDIRECT_URL` | sign-up, resend verification | **not set** |
| `AUTH_PASSWORD_RESET_REDIRECT_URL` | forgot password | **not set** |

When they are empty Supabase falls back to the project's **Site URL**, which
is still the default `http://localhost:3000`. The Flutter app can't change
this. The backend developer must set the values below. No backend code
changes are needed.

## 1. Values to set (backend developer, Render)

Web and mobile can't share one URL until App Links are verified (step 4), so
pick by platform:

| Env var | Web (works now) | Android / iOS app |
|---|---|---|
| `AUTH_EMAIL_REDIRECT_URL` | `https://sharkhire.vercel.app/auth/callback` | `sharkhire://auth/callback` |
| `AUTH_PASSWORD_RESET_REDIRECT_URL` | `https://sharkhire.vercel.app/auth/reset-password` | `sharkhire://auth/reset-password` |

**Recommended:** use the `https://sharkhire.vercel.app/...` URLs. They work in
any browser today. Once step 4 is done, the same URLs open the installed app
on Android and iOS.

## 2. Supabase dashboard → Authentication → URL Configuration

* **Site URL:** `https://sharkhire.vercel.app` (replaces `http://localhost:3000`).
* **Redirect URLs:** add every URL from the table:
  `https://sharkhire.vercel.app/auth/callback`,
  `https://sharkhire.vercel.app/auth/reset-password`,
  `sharkhire://auth/callback`, `sharkhire://auth/reset-password`.
* The email templates can stay on the default `{{ .ConfirmationURL }}`
  (implicit flow). The app also accepts `token_hash` links.

## 3. What the app does with a link

`lib/features/authentication/presentation/providers/auth_link_provider.dart`

* The GoRouter `redirect` first calls `AuthLinkController.capture`. It reads
  the link's query and `#fragment`, stores it in memory, and replaces the
  location with a clean `/auth/callback` or `/auth/reset-password`, so tokens
  never stay in the address bar, the history or logs. `AuthLink.toString()`
  never prints tokens.
* Android and iOS: Flutter passes deep links to GoRouter in all three cases:
  app closed (initial route), in the background, and running
  (`pushRouteInformation`). Custom-scheme links arrive as `/callback`,
  which is accepted too. A repeated delivery of the same link is handled
  once.
* Web: the app uses hash routing, so the controller reads the page URL
  (`Uri.base`) on the first navigation.
* **Confirm email** (`AuthCallbackScreen`): if the link carries a session
  (`access_token`), it is saved like a sign-in and the user continues to
  onboarding or their home. If there is no session, a device in the middle of
  sign-up re-checks and continues; otherwise the user is asked to log in.
  Expired, used and broken links each get their own message.
* **Reset password** (`ResetPasswordScreen`): new password plus
  confirmation, checked with the backend's policy (8–72 characters, upper and
  lower case, a number, not a common password). The request is
  `POST /api/v1/auth/reset-password`, sent with `token_hash` in the body or
  with the link's access token as `Authorization: Bearer`. An expired or used
  link (401) shows "This reset link has expired" with "Send a new link".
* The guard lets `/auth/callback` and `/auth/reset-password` open in every
  sign-in state.

## 4. Native configuration

**Android** (`android/app/src/main/AndroidManifest.xml`, done):

* `sharkhire://auth/...` intent filter: works as soon as the app is installed.
* `https://${appLinkHost}/auth/...` intent filter with `autoVerify`. The host
  comes from `-PappLinkHost=<host>` and defaults to `sharkhire.vercel.app`.
* **To do before release:** serve `https://sharkhire.vercel.app/.well-known/assetlinks.json`
  with package `io.thescaleshark.sharkhire` and the **SHA-256 of the
  release/Play signing key** (Play Console → App integrity). Until then the
  https links open the website, not the app.

**iOS** (`ios/Runner/Info.plist`, done):

* URL scheme `sharkhire` (`CFBundleURLTypes`) and `FlutterDeepLinkingEnabled`.
* **To do for https links (Universal Links):** in Xcode → Runner →
  Signing & Capabilities, add *Associated Domains* with
  `applinks:sharkhire.vercel.app`. Then serve
  `https://sharkhire.vercel.app/.well-known/apple-app-site-association` with
  `appID` `<TEAM_ID>.io.thescaleshark.sharkhire` and paths `/auth/*`. This
  needs the Apple Team ID.

## 5. Change password

Settings → Change password (`/settings/password`). The live API has no
change-password endpoint, so the app uses the existing endpoints:

1. `POST /auth/login` with the current password, which proves it's the user
   and renews this device's session. A wrong password gives "Your current
   password is incorrect." and nothing changes.
2. `POST /auth/reset-password` `{new_password}`, authorised by that session's
   Bearer token. The backend updates the password of whoever owns the token
   (Supabase `PUT /user`), so a user can only change their own password.

"Forgot your current password?" sends the reset email.

## 6. Delete account: backend endpoint still missing

Privacy & security → Delete account (`/settings/delete-account`):

* The screen lists what gets deleted.
* The user ticks "I understand", types `DELETE`, and taps one final button.
* A spinner shows while it runs, and a second tap is ignored.
* Errors are shown in a banner.
* On success it signs out: tokens are removed from secure storage, the
  session and user data are reset, and the user lands on the welcome screen
  with "Your SharkHire account was deleted".

**The live API has no account-deletion endpoint** (OpenAPI re-checked 23 Nov
2026, and none on any backend branch). So `ApiAccountRepository.requestDeletion`
says honestly that nothing was deleted, keeps the user signed in, and offers
**Email support**.

**Backend developer, to finish this:** add an authenticated endpoint, for
example `DELETE /api/v1/auth/me`. It should delete the profile, CVs (database
rows and Storage files), saved jobs, applications and preferences, then the
Supabase user (service-role `DELETE /admin/users/{id}`), and return the usual
`{success, message}`. Then replace the body of `requestDeletion()` in
`lib/features/settings/data/repositories/account_repository.dart` with
`await _api.delete(<path>)`. The UI and sign-out are already in place and
tested. Apple (5.1.1(v)) and Google Play both require in-app deletion before
release.
