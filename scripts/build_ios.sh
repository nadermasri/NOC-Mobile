#!/bin/bash
set -euo pipefail

# Production build for iOS
# Usage: ./scripts/build_ios.sh [api_url]
# Requires: Xcode with valid signing identity

API_URL="${1:-https://api.pocketnoc.app}"

echo "Building iOS with API_BASE_URL=$API_URL"

cd "$(dirname "$0")/.."

flutter clean
flutter pub get
flutter build ipa \
  --release \
  --dart-define=API_BASE_URL="$API_URL"

echo ""
echo "IPA built. Upload to App Store Connect via:"
echo "  open build/ios/ipa/*.ipa"
echo "  or use: xcrun altool --upload-app -f build/ios/ipa/*.ipa -t ios"
