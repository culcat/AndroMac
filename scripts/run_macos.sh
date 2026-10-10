#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

echo "==> Running AndroMac macOS Desktop App..."
cd "${ROOT_DIR}/apps/desktop"
flutter run -d macos "$@"
