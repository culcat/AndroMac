#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

echo "==> Building AndroMac macOS Desktop App in apps/desktop..."
cd "${ROOT_DIR}/apps/desktop"
flutter build macos --release "$@"
echo "==> macOS build complete! Artifacts located in apps/desktop/build/macos/Build/Products/Release/"
