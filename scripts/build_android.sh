#!/bin/bash
set -euo pipefail

# Production build for Android
# Usage: ./scripts/build_android.sh [api_url]

API_URL="${1:-https://api.pocketnoc.app}"

echo "Building Android APK with API_BASE_URL=$API_URL"

cd "$(dirname "$0")/.."

flutter clean
flutter pub get
flutter build appbundle \
  --release \
  --dart-define=API_BASE_URL="$API_URL"

echo ""
echo "App bundle built at:"
echo "  build/app/outputs/bundle/release/app-release.aab"
echo ""
echo "To also build an APK for testing:"
echo "  flutter build apk --release --dart-define=API_BASE_URL=$API_URL"
