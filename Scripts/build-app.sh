#!/usr/bin/env bash
#
# Build Cratebar and wrap it into a proper macOS .app bundle (menu-bar only).
# Usage: ./Scripts/build-app.sh [--debug]
#
set -euo pipefail

cd "$(dirname "$0")/.."

CONFIG="release"
SWIFT_FLAGS="-c release"
if [[ "${1:-}" == "--debug" ]]; then
  CONFIG="debug"
  SWIFT_FLAGS=""
fi

APP_NAME="Cratebar"
APP_DIR="build/${APP_NAME}.app"
MACOS_DIR="${APP_DIR}/Contents/MacOS"
RES_DIR="${APP_DIR}/Contents/Resources"

echo "▸ Building (${CONFIG})…"
# shellcheck disable=SC2086
swift build ${SWIFT_FLAGS}

BIN_PATH="$(swift build ${SWIFT_FLAGS} --show-bin-path)/${APP_NAME}"

echo "▸ Assembling ${APP_DIR}…"
rm -rf "${APP_DIR}"
mkdir -p "${MACOS_DIR}" "${RES_DIR}"
cp "${BIN_PATH}" "${MACOS_DIR}/${APP_NAME}"

cat > "${APP_DIR}/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleName</key>            <string>Cratebar</string>
  <key>CFBundleDisplayName</key>     <string>Cratebar</string>
  <key>CFBundleIdentifier</key>      <string>com.jackpatterson.cratebar</string>
  <key>CFBundleVersion</key>         <string>1.0</string>
  <key>CFBundleShortVersionString</key><string>1.0</string>
  <key>CFBundlePackageType</key>     <string>APPL</string>
  <key>CFBundleExecutable</key>      <string>Cratebar</string>
  <key>LSMinimumSystemVersion</key>  <string>14.0</string>
  <key>LSUIElement</key>             <true/>
  <key>NSHighResolutionCapable</key> <true/>
</dict>
</plist>
PLIST

# Sign with a Developer ID identity when provided (enables notarization),
# otherwise fall back to an ad-hoc signature (still runnable, but Gatekeeper
# will quarantine downloads).
#   SIGN_IDENTITY="Developer ID Application: Name (TEAMID)" ./Scripts/build-app.sh
if [[ -n "${SIGN_IDENTITY:-}" ]]; then
  echo "▸ Signing with Developer ID + hardened runtime…"
  echo "  identity: ${SIGN_IDENTITY}"
  codesign --force --deep --timestamp --options runtime \
    --sign "${SIGN_IDENTITY}" "${APP_DIR}"
  codesign --verify --deep --strict --verbose=1 "${APP_DIR}"
else
  echo "▸ Ad-hoc code signing…"
  codesign --force --deep --sign - "${APP_DIR}" >/dev/null 2>&1 || \
    echo "  (codesign skipped — app still runnable)"
fi

echo "✅ Built ${APP_DIR}"
echo "   Run it:        open ${APP_DIR}"
echo "   Install it:    cp -R ${APP_DIR} /Applications/"
