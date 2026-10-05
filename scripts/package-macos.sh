#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
RESOURCE_DIR="$ROOT/Sources/CyberBlessing/Resources"
VERSION="$(tr -d '\r\n' < "$RESOURCE_DIR/VERSION")"
if [[ ! "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then echo "Invalid resource VERSION" >&2; exit 1; fi
if [[ -n "${1:-}" && "$1" != "$VERSION" ]]; then echo "Requested version $1 differs from source VERSION $VERSION" >&2; exit 1; fi
mkdir -p "${2:-$ROOT/dist}"
OUTDIR="$(cd "${2:-$ROOT/dist}" && pwd)"
APP_NAME="CyberBlessing"
APP_BUNDLE="$OUTDIR/$APP_NAME.app"
ZIP_NAME="$APP_NAME-$VERSION-macOS.zip"
STAGE="$(mktemp -d "$OUTDIR/.package-XXXXXX")"
trap 'rm -rf "$STAGE"' EXIT
cd "$ROOT"

# A dedicated, relocatable build directory avoids copied legacy .build caches.
BUILD_DIR="$ROOT/.work/package-build"
CACHE_ROOT_FILE="$ROOT/.work/package-build-root"
if [[ -f "$CACHE_ROOT_FILE" && "$(cat "$CACHE_ROOT_FILE")" != "$ROOT" && -d "$BUILD_DIR" ]]; then
  mv "$BUILD_DIR" "$ROOT/.work/package-build-retired-$(date +%Y%m%d-%H%M%S)"
fi
mkdir -p "$ROOT/.work"
printf '%s\n' "$ROOT" > "$CACHE_ROOT_FILE"
# Separate native builds also work with Command Line Tools; SwiftPM's
# multi-arch build mode requires XCBuild from full Xcode.
for ARCH in arm64 x86_64; do
  BUILD_ARGS=(-c release --product CyberBlessing --disable-sandbox --scratch-path "$BUILD_DIR/$ARCH" --arch "$ARCH"
    -Xswiftc -DAPP_BUNDLE -Xswiftc -gnone)
  swift build "${BUILD_ARGS[@]}"
  BIN_DIR="$(swift build "${BUILD_ARGS[@]}" --show-bin-path)"
  [[ -x "$BIN_DIR/$APP_NAME" ]] || { echo "Missing $ARCH executable" >&2; exit 1; }
  cp "$BIN_DIR/$APP_NAME" "$STAGE/$APP_NAME-$ARCH"
done
BINARY="$STAGE/$APP_NAME-universal"
lipo -create "$STAGE/$APP_NAME-arm64" "$STAGE/$APP_NAME-x86_64" -output "$BINARY"
STAGED_APP="$STAGE/$APP_NAME.app"
mkdir -p "$STAGED_APP/Contents/MacOS" "$STAGED_APP/Contents/Resources"
cp "$BINARY" "$STAGED_APP/Contents/MacOS/$APP_NAME"
ditto "$RESOURCE_DIR" "$STAGED_APP/Contents/Resources"
cp "$ROOT/LICENSE" "$STAGED_APP/Contents/Resources/LICENSE"
find "$STAGED_APP/Contents/Resources" -name .DS_Store -delete
cat > "$STAGED_APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>CFBundleExecutable</key><string>$APP_NAME</string>
  <key>CFBundleIdentifier</key><string>dev.cyberblessing.menubar</string>
  <key>CFBundleName</key><string>赛博祈福</string>
  <key>CFBundleDisplayName</key><string>赛博祈福</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>$VERSION</string>
  <key>CFBundleVersion</key><string>$VERSION</string>
  <key>CFBundleIconFile</key><string>AppIcon</string>
  <key>LSMinimumSystemVersion</key><string>13.0</string>
  <key>LSUIElement</key><true/>
  <key>NSHighResolutionCapable</key><true/>
</dict></plist>
PLIST
plutil -lint "$STAGED_APP/Contents/Info.plist"
codesign --force --sign - "$STAGED_APP"
"$ROOT/scripts/verify-package.sh" "$STAGED_APP"
/usr/bin/ditto -c -k --sequesterRsrc --keepParent "$STAGED_APP" "$STAGE/$ZIP_NAME"
mkdir "$STAGE/unpacked"
/usr/bin/ditto -x -k "$STAGE/$ZIP_NAME" "$STAGE/unpacked"
"$ROOT/scripts/verify-package.sh" "$STAGE/unpacked/$APP_NAME.app"
(cd "$STAGE" && shasum -a 256 "$ZIP_NAME" > "$ZIP_NAME.sha256")

# Publish only a verified package, retaining the previous app for rollback.
if [[ -d "$APP_BUNDLE" ]]; then
  ARCHIVE_DIR="$OUTDIR/archive-$(date +%Y%m%d-%H%M%S)"
  mkdir -p "$ARCHIVE_DIR"
  mv "$APP_BUNDLE" "$ARCHIVE_DIR/"
fi
mv "$STAGED_APP" "$APP_BUNDLE"
mv "$STAGE/$ZIP_NAME" "$STAGE/$ZIP_NAME.sha256" "$OUTDIR/"
SOURCE_ZIP="$OUTDIR/$APP_NAME-$VERSION-source.zip"
if [[ -f "$SOURCE_ZIP" ]]; then mv "$SOURCE_ZIP" "$SOURCE_ZIP.previous-$(date +%Y%m%d-%H%M%S)"; fi
COPYFILE_DISABLE=1 /usr/bin/zip -q -r "$SOURCE_ZIP" Package.swift Sources Tests Tools scripts README.md DEVELOPMENT.md DESIGN.md ASSETS.md ASSETS_0.7.0.md CHANGELOG.md LICENSE .gitignore RELEASE_CHECK.md "RELEASE_NOTES_$VERSION.md" -x '*/.DS_Store' '*/__pycache__/*'
(cd "$OUTDIR" && shasum -a 256 "$(basename "$SOURCE_ZIP")" > "$(basename "$SOURCE_ZIP").sha256")
printf 'Created: %s\n' "$APP_BUNDLE" "$OUTDIR/$ZIP_NAME" "$SOURCE_ZIP"
echo "Universal arm64/x86_64; ad-hoc signed. Developer ID signing and notarization require a developer account."
