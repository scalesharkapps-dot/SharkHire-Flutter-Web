# Email links, password reset and account deletion

How SharkHire handles the links in Supabase emails (confirm email, reset
password), and what has to be configured **outside the Flutter app** for them
to work. Checked against the live API on 24 Nov 2026.

## Why the links opened `localhost:3000`

The Flutter app never calls Supabase directly: there is no
`resetPasswordForEmail()` and no `redirectTo` in the app. Every email is sent
by the backend, which passes `redirect_to` = `AUTH_EMAIL_REDIRECT_URL` /
`AUTH_PASSWORD_RESET_REDIRECT_URL` to Supabase. Supabase **silently ignores**
a `redirect_to` that isn't in its Redirect URLs allow-list and uses the
**Site URL** instead, which was `http://localhost:3000`.

On 24 Nov 2026 `GET /api/v1/health/auth` reports both values as configured.
The backend docs give `sharkhire://auth/reset-password` as the example value.
If that is what's set, the Supabase allow-list must contain it **exactly**.
Otherwise the link falls back to the Site URL. Emails sent before a settings
change keep their old link, so always test with a new email.

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

Settings → Change password (`/settings/password`) calls
`POST /api/v1/auth/change-password` `{current_password, new_password}` with the
user's session. A wrong current password (`403 invalid_password`) shows "Your
current password is incorrect." and nothing changes. Reusing the old password
shows "Choose a password different from your current one". If the backend
returns a fresh `data.session`, the app stores it. "Forgot your current
password?" sends the reset email.

## 6. Delete account

Privacy & security → Delete account (`/settings/delete-account`):

* The screen lists what gets deleted.
* The user ticks "I understand", enters their **password**, types `DELETE`,
  and taps one final button.
* A spinner shows while it runs, and a second tap is ignored.
* The request is `POST /api/v1/auth/delete-account`
  `{password, confirmation: "DELETE"}`.
* A wrong password (`403 invalid_password`) shows "That password is
  incorrect. Nothing was deleted." Other errors (`409`, `422`, `503`) show the
  backend's message, and the user stays signed in.
* On success the server has already ended every session. The app forgets the
  tokens locally (no logout call), resets the session, and shows the welcome
  screen with "Your SharkHire account was deleted". If
  `active_store_subscription` is true, the message also says to cancel Premium
  in Google Play or the App Store.

## 7. Password reset details

* The app sends the recovery link's `access_token` as the Bearer token, or
  `token_hash` in the body. It uses a separate client that never sends the
  device's own session, so a bad link can't sign anyone out.
* On `200` the backend revokes **every** session of the account. The app
  clears any session stored on the device and asks the user to log in.
* `401` means the link is invalid, expired or already used: the app shows
  "This reset link has expired" with "Send a new link". `422` shows the
  backend's password-policy message.
* Confirmation links with `token_hash` are exchanged with
  `POST /api/v1/auth/verify-email`. Implicit links (`#access_token=`) are used
  directly.
