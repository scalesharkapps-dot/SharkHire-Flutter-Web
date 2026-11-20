# SharkHire subscriptions & app access (frontend)

Paid app access for **job seekers**: a 3-day free trial from registration,
then one monthly subscription (target price USD 10 internationally,
PKR 499 in Pakistan, configured in the stores). Billing goes through
**RevenueCat** on top of Google Play Billing (Android) and StoreKit (iOS).
Employers and admins are not asked to subscribe.

> **Status (20 Nov 2026):** the frontend is built and tested with a mocked
> RevenueCat and a mocked backend. It is **switched off**
> (`SUBSCRIPTIONS_ENABLED=false`) because the backend does not have the
> subscription API yet. No real Google Play or App Store payment has been
> tested.

## How it works

```
Store (Play / App Store) ──► RevenueCat ──webhook/REST──► SharkHire backend
          ▲                                                  │
          │ purchase / restore (SDK)                         │ status
     Flutter app ◄───────── GET /subscriptions/status ◄──────┘
```

1. On sign-in, the app identifies the user to RevenueCat with the
   **backend (Supabase) user ID** as the App User ID (`Purchases.logIn`),
   and calls `Purchases.logOut` on sign-out.
2. The app asks the backend for the status. **Only the backend's answer
   grants access.** The app never trusts the device, the store response or
   RevenueCat's client-side entitlement for access.
3. Purchase: RevenueCat SDK → store payment sheet → on success the app calls
   `POST /subscriptions/sync`; access unlocks when the backend confirms.
4. Restore: `Purchases.restorePurchases()` then `POST /subscriptions/restore`.
5. The status is refreshed after sign-in and registration, app resume,
   purchase, restore and sync.
6. The trial is run by the backend (`trial_ends_at`), so it never restarts
   on sign-out / sign-in.

Web (Vercel) never loads RevenueCat or any other payment provider. It shows
the backend status, restore and history, and tells users to subscribe in the
mobile app.

## Code map (`lib/features/subscription/`)

| File | Role |
| --- | --- |
| `domain/subscription_status.dart` | `AccessState` (loading, trial_active, subscription_active, payment_required, subscription_expired, subscription_cancelled_but_active, billing_issue, error) and the access rule (fails closed). |
| `data/subscription_json.dart` | **PROPOSED** backend response shapes. The only file to change when the backend schema is final. |
| `data/subscription_repository.dart` | The 5 backend endpoints. 404 → "not available yet" (integration dependency), never "no subscription". Dev-only mock. |
| `data/billing_service.dart` | `RevenueCatBillingService` (Android/iOS), `UnavailableBillingService` (web, no key), dev-only demo. |
| `presentation/providers/subscription_providers.dart` | Riverpod controller: status, purchase, restore, sync, RevenueCat logIn/logOut. |
| `presentation/screens/subscription_screen.dart` | Paywall / subscription overview (`/subscription`). |
| `presentation/screens/subscription_history_screen.dart` | Billing history (`/subscription/history`). |
| `presentation/widgets/subscription_widgets.dart` | Trial banner on Home, refresh on app resume. |
| `core/routing/route_guard.dart` | Access guard. |

### Access guard

When enabled, a signed-in job seeker without confirmed access (including
while the status loads or after an error) is redirected to
`/subscription?next=<where they were going>`, and returns there once the
backend confirms access. This also covers deep links. Always reachable:
the paywall, billing history, profile and edit profile, settings,
privacy & security (account deletion), help, and the Terms / Privacy sheets.
`next` only accepts in-app paths, so it can't be used as an open redirect.

## Backend integration dependency

The frontend expects these endpoints (all authenticated with the user's
bearer token, wrapped in the usual `{success, message, data, error}`
envelope). **They don't exist yet** (404 on the live API). The shapes
below are a proposal; agree them with the backend and update
`subscription_json.dart` if they differ.

| Method & path | `data` |
| --- | --- |
| `GET /api/v1/subscriptions/status` | status object (below) |
| `POST /api/v1/subscriptions/sync` body `{"trigger": "purchase"}` | status object, after re-reading RevenueCat server-side |
| `POST /api/v1/subscriptions/restore` | status object |
| `GET /api/v1/subscriptions/history` | list (or `{items}`) of `{id, event, product_id, store, price, occurred_at, expires_at}` |
| `GET /api/v1/subscriptions/plans` | list (or `{items}`) of `{id, title, description, product_id}`; prices come from the store |

Status object:

```json
{
  "status": "trial_active | subscription_active | payment_required | subscription_expired | subscription_cancelled_but_active | billing_issue",
  "has_access": true,
  "trial_ends_at": "2026-11-23T10:00:00Z",
  "current_period_ends_at": null,
  "will_renew": null,
  "product_id": null,
  "store": "play_store | app_store | null",
  "management_url": null
}
```

An unknown `status` is treated as an error and grants no access. The
backend should also enforce access on its own job, CV and recommendation
endpoints; the app's guard is only for navigation.

## Configuration (build time, `--dart-define`)

| Name | Value |
| --- | --- |
| `SUBSCRIPTIONS_ENABLED` | `false` (default). `true` turns on the guard and automatic status checks. |
| `REVENUECAT_ANDROID_KEY` | RevenueCat **public** Google Play SDK key (`goog_…`). |
| `REVENUECAT_IOS_KEY` | RevenueCat **public** App Store SDK key (`appl_…`). |

Fixed in code: entitlement `app_access`, offering `default`.

**Never put a RevenueCat secret key (`sk_…`) or any other secret in the
app.** Production builds refuse to start with one, and the billing service
ignores it. Webhook secrets and RevenueCat REST keys belong to the backend.

```bash
flutter build appbundle --release --dart-define-from-file=config/production.json
# config/production.json (git-ignored) holds SUBSCRIPTIONS_ENABLED and the public keys.
```

Vercel: `SUBSCRIPTIONS_ENABLED` can be set as a project environment
variable (read by `tool/vercel_build.sh`). No RevenueCat key is needed on
web.

## Store & RevenueCat setup (to do, outside this repo)

1. **Google Play Console**: an auto-renewing subscription, e.g.
   `sharkhire_monthly`, base plan monthly; prices USD 10 / PKR 499. Upload a
   build to an internal testing track (billing only works for installed
   Play builds). Add license testers.
2. **App Store Connect**: an auto-renewable subscription in a subscription
   group, e.g. `sharkhire_monthly`, with the same prices; Paid Applications
   agreement signed; sandbox testers created.
3. **RevenueCat**: add both apps; create the entitlement `app_access`;
   attach both products; create the offering `default` with a monthly
   package; copy the two **public** SDK keys into the build config.
4. **Backend**: RevenueCat webhook + the endpoints above; run the 3-day
   trial from registration.
5. The trial is the backend's own trial. Don't also add a store free trial
   (introductory offer) unless the backend is meant to combine them.

## Sandbox testing checklist

- [ ] Android internal-testing build with `SUBSCRIPTIONS_ENABLED=true` and
      the Play key; tester account signed in to Play.
- [ ] iOS TestFlight / sandbox build with the App Store key.
- [ ] New user: trial banner shows 3 days; sign out and in: same count.
- [ ] Trial ended (backend): paywall shows the store's local price.
- [ ] Purchase → store sheet → back in the app, access unlocks only after
      the backend confirms.
- [ ] Cancel at the store sheet: nothing changes, no error.
- [ ] Pending payment (Play "slow test card"): pending message, no access.
- [ ] Declined card: error message, no access.
- [ ] Restore on a second device / after reinstall.
- [ ] Cancel in store settings → `subscription_cancelled_but_active`, then
      expiry → paywall.
- [ ] Billing problem (Play test card "declined renewal") → banner and
      "Update payment method".
- [ ] Deep link to `/jobs/<id>` while unpaid → paywall → after purchase
      returns to the job.
- [ ] Web: no purchase button; status, restore and history work.

## Production checklist

- [ ] Backend endpoints live and matching `subscription_json.dart`.
- [ ] Store products approved; RevenueCat entitlement & offering set.
- [ ] Public SDK keys in the production build config (never committed).
- [ ] `SUBSCRIPTIONS_ENABLED=true` for the release builds.
- [ ] Sandbox checklist passed on both platforms.
- [ ] Terms of Use and Privacy Policy include subscription terms;
      App Store review notes describe the trial and subscription.
- [ ] Support contact can handle refund / billing questions.

## Tests

`test/subscription_test.dart` uses a fake RevenueCat (`BillingService`) and
a fake backend: status mapping, fail-closed access, 404 handling, purchase
success / cancel / pending / failure, backend confirmation before access,
restore, RevenueCat logIn/logOut, the access guard (deep links, allowlist,
employers), web behaviour, store-price display and the trial banner.
