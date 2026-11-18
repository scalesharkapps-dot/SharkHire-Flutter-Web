# SharkHire – Web Deployment Guide (Vercel)

**Nothing has been deployed.** You push to GitHub and deploy on Vercel yourself.

## How it works
- **Building:** Vercel builds the Flutter web app from your GitHub repository. Vercel has no Flutter, so `mobile_app/tool/vercel_build.sh` downloads Flutter **3.50.0** (the version the app is built with) and builds into **`build/web`**.
- **Talking to the backend:** the web app calls **its own site** (`https://<your-site>.vercel.app/api/...`). A rewrite in `mobile_app/vercel.json` forwards every `/api/*` request to the backend (`https://backend-job-search.onrender.com/api/*`). Vercel makes that request server-side, so the browser never makes a cross-site call, and **no CORS change is needed on the backend**.
- **Pages and refreshes:** every other path that isn't a real file is served `index.html`, so direct links and page refreshes always open the app.
- **No secrets:** none are needed or stored. The web build only knows `API_BASE_URL=same-origin`. Android and iOS still use the full backend URL from their own config files.

| File | Purpose |
|---|---|
| `mobile_app/vercel.json` | Build command, output `build/web`, `/api` rewrite, app fallback, security and cache headers |
| `mobile_app/tool/vercel_build.sh` | Downloads Flutter 3.50.0, builds `build/web`, fails the deploy if files are missing |
| `mobile_app/.vercelignore` | Keeps Android/iOS folders, local builds, keys and real config files out of the upload |
| `mobile_app/tool/serve_like_render.py` | Local preview that behaves like Vercel (serves files, forwards `/api`, app fallback) |

## 1. Put the project on GitHub (once)
From the `frontend` folder:
1. Create the repository:
   ```bash
   git init
   ```
2. Stage everything:
   ```bash
   git add .
   ```
3. Check that no secrets are staged. This must print nothing:
   ```bash
   git status --short | grep -E "key.properties|\.jks|config/(production|staging|render|web-local)\.json"
   ```
4. Make the first commit:
   ```bash
   git commit -m "SharkHire frontend"
   ```
5. Create an **empty private repository** on GitHub, e.g. under the company account.
6. Connect it, using your repository's URL:
   ```bash
   git remote add origin https://github.com/<owner>/<repo>.git
   ```
7. Rename the branch to `main`:
   ```bash
   git branch -M main
   ```
8. Push:
   ```bash
   git push -u origin main
   ```

## 2. Create the project on Vercel
1. Go to https://vercel.com/new and **Import** the GitHub repository.
2. On the configuration screen:

   | Setting | Value |
   |---|---|
   | **Root Directory** | `mobile_app` (click **Edit** and select it, **this is required**) |
   | Framework Preset | **Other** |
   | Build / Output / Install commands | leave as they are; `vercel.json` sets them (build `bash tool/vercel_build.sh`, output `build/web`) |
   | Environment Variables | none needed |

3. Click **Deploy**. The first build takes about **5–8 minutes**: it downloads Flutter, then builds.
4. When it says **Ready**, open the URL (e.g. `https://sharkhire.vercel.app`).

## 3. Check it works
1. **App opens:** the site shows the splash, then the Welcome screen.
2. **Page refresh:** press **F5** on any screen; the app must reload, not show a 404.
3. **Backend proxy:** this should return the backend's job filters as JSON:
   ```bash
   curl https://<your-site>.vercel.app/api/v1/jobs/filters
   ```
4. **Login:** it should work with no connection error.
5. **CV upload:** works once the backend's file storage is set up (see the backend section below).

## 4. Updating the site
Every push to `main` deploys automatically:
```bash
git add .
```
```bash
git commit -m "Update"
```
```bash
git push
```
Pushes to other branches get their own **Preview** URL.

## 5. Rolling back
Vercel dashboard → your project → **Deployments** → pick an earlier deployment → **⋯ → Promote to Production**.

## 6. Custom domain (optional)
Project → **Settings → Domains → Add**, then add the DNS record Vercel shows at your registrar. HTTPS is automatic.

## Test locally before pushing (optional)
From `mobile_app/`, build exactly like Vercel:
```bash
flutter build web --release --dart-define=APP_ENV=production --dart-define=USE_MOCK_DATA=false --dart-define=API_BASE_URL=same-origin --output build/web
```
Serve it like Vercel, then open http://localhost:5240:
```bash
python tool/serve_like_render.py 5240 build/web
```

## Backend items (for the backend team)
- **CORS:** *not needed* with this setup, because the browser only talks to the Vercel site. Only add it if you ever want the web app to call the backend directly (instead of through `/api`). In that case, allow the Vercel domain:
  ```python
  from fastapi.middleware.cors import CORSMiddleware
  app.add_middleware(
      CORSMiddleware,
      allow_origins=os.getenv("CORS_ALLOWED_ORIGINS", "").split(","),
      allow_credentials=False,
      allow_methods=["GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"],
      allow_headers=["Authorization", "Content-Type", "Accept"],
      max_age=600,
  )
  ```
  For example: `CORS_ALLOWED_ORIGINS=https://sharkhire.vercel.app,https://<custom-domain>`. Never use `*`.
- **CV upload:** returns `503 storage_not_configured`. Supabase Storage must be set up on the backend.
- **Cold starts:** the backend is on a free Render plan and sleeps when idle; the first request took ~30 s in testing. Vercel stops waiting for proxied requests after a limit, so a sleeping backend can make the first request fail. **Use an always-on backend plan for launch.**
- **Large uploads through the proxy:** Vercel may limit the size of requests it forwards. CVs are at most 5 MB. After deploying, test a CV close to 5 MB. If it fails, switch to direct calls:
  1. Enable the CORS config above on the backend.
  2. In Vercel, go to **Settings → Environment Variables** and set `API_BASE_URL` = `https://backend-job-search.onrender.com`.
  3. Redeploy. `vercel_build.sh` uses this variable instead of `same-origin`.

## Render (previous option)
`render.yaml` and the Render steps are no longer used. They're kept in case you switch back.
