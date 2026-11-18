#!/usr/bin/env bash
# Vercel build for the SharkHire Flutter web app (Vercel has no Flutter).
# Vercel project settings: Root Directory = mobile_app. vercel.json runs this.
#
# Downloads the Flutter version the project is developed with, then builds
# the production web app into build/web. No secrets are needed: the web app
# calls its own site under /api, which vercel.json forwards to the backend.
set -euo pipefail

FLUTTER_VERSION="${FLUTTER_VERSION:-3.50.0}"
SDK_DIR="$PWD/.flutter-sdk"

if [ ! -x "$SDK_DIR/bin/flutter" ]; then
  echo "Downloading Flutter $FLUTTER_VERSION..."
  git clone https://github.com/flutter/flutter.git \
    --branch "$FLUTTER_VERSION" --depth 1 "$SDK_DIR"
fi
export PATH="$SDK_DIR/bin:$PATH"

flutter config --no-analytics --enable-web
flutter --version
flutter pub get
flutter build web --release \
  --dart-define=APP_ENV=production \
  --dart-define=USE_MOCK_DATA=false \
  --dart-define=API_BASE_URL="${API_BASE_URL:-same-origin}" \
  --output build/web

# Fail the deployment if the output is incomplete.
for f in index.html main.dart.js flutter_bootstrap.js assets/FontManifest.json assets/AssetManifest.bin; do
  [ -f "build/web/$f" ] || { echo "Missing build/web/$f"; exit 1; }
done
echo "Built build/web"
