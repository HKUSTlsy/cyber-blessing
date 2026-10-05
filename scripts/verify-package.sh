#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP="${1:-$ROOT/dist/CyberBlessing.app}"
RESOURCE_DIR="$ROOT/Sources/CyberBlessing/Resources"
VERSION="$(tr -d '\r\n' < "$RESOURCE_DIR/VERSION")"
INFO="$APP/Contents/Info.plist"
[[ "$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$INFO")" == "$VERSION" ]] || { echo "App version mismatch" >&2; exit 1; }
[[ "$(/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' "$INFO")" == "$VERSION" ]] || { echo "Build version mismatch" >&2; exit 1; }
[[ "$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIconFile' "$INFO")" == "AppIcon" ]] || { echo "Missing app icon declaration" >&2; exit 1; }
[[ -s "$APP/Contents/Resources/AppIcon.icns" ]] || { echo "Missing app icon" >&2; exit 1; }
ARCHS="$(lipo -archs "$APP/Contents/MacOS/CyberBlessing")"
[[ "$ARCHS" == *arm64* && "$ARCHS" == *x86_64* ]] || { echo "Expected universal binary, got $ARCHS" >&2; exit 1; }
[[ "$(/usr/libexec/PlistBuddy -c 'Print :LSMinimumSystemVersion' "$INFO")" == "13.0" ]] || { echo "Minimum system declaration mismatch" >&2; exit 1; }
MINIMUMS="$(xcrun vtool -show-build "$APP/Contents/MacOS/CyberBlessing" | awk '$1 == "minos" { print $2 }')"
[[ "$MINIMUMS" == $'13.0\n13.0' ]] || { echo "Binary minimum system mismatch: $MINIMUMS" >&2; exit 1; }
cmp -s "$ROOT/LICENSE" "$APP/Contents/Resources/LICENSE" || { echo "Missing or mismatched bundled license" >&2; exit 1; }
# Scan raw bytes as well as Mach-O sections, including fat-binary trailing data.
if LC_ALL=C grep -aqE '/Users/|/var/folders/' "$APP/Contents/MacOS/CyberBlessing"; then
  echo "Local machine paths remain in binary" >&2; exit 1
else
  SCAN_STATUS=$?
  [[ "$SCAN_STATUS" == "1" ]] || { echo "Binary path scan failed" >&2; exit 1; }
fi
while IFS= read -r -d '' FILE; do
  [[ "$(basename "$FILE")" == .DS_Store ]] && continue
  cmp -s "$FILE" "$APP/Contents/Resources/${FILE#"$RESOURCE_DIR/"}" || { echo "Resource mismatch: ${FILE#"$RESOURCE_DIR/"}" >&2; exit 1; }
done < <(find "$RESOURCE_DIR" -type f -print0)
codesign --verify --deep --strict "$APP"
echo "PASS package $VERSION: universal binary, macOS 13, resources, license, icon, signature and no local paths"
