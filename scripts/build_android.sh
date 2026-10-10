#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

echo "==> Building AndroMac Android App in apps/phone..."
cd "${ROOT_DIR}/apps/phone"
flutter build apk --flavor direct --release "$@"
echo "==> Android build complete! APK located in apps/phone/build/app/outputs/flutter-apk/app-direct-release.apk"
