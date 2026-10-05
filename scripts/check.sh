#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
swift run --disable-sandbox CyberBlessingChecks
# Core checks also run without XCTest on Command Line Tools-only machines.
# Under full Xcode, run the same cases through XCTest as well.
DEVELOPER_DIR_PATH="$(xcode-select -p)"
if [[ "$DEVELOPER_DIR_PATH" == */Xcode*.app/Contents/Developer ]]; then
  swift test --disable-sandbox
else
  echo "XCTest unavailable in Command Line Tools-only environment; standalone regression checks ran above."
fi
swift build -c release --product CyberBlessing --disable-sandbox
bash -n scripts/package-macos.sh scripts/verify-package.sh scripts/check.sh
