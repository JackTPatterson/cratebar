#!/usr/bin/env bash
#
# Build, sign (Developer ID), notarize, and staple Cratebar.app, then produce a
# distributable zip ready for a GitHub release / Homebrew cask.
#
# Prerequisites (one-time):
#   1. A "Developer ID Application" certificate installed in your login keychain.
#      Create via Xcode → Settings → Accounts → Manage Certificates → + →
#      "Developer ID Application".
#   2. A stored notarytool credential profile named "cratebar":
#        xcrun notarytool store-credentials cratebar \
#          --apple-id "you@email.com" --team-id "P8FLGJ3757" \
#          --password "<app-specific-password>"
#      (Generate an app-specific password at https://appleid.apple.com →
#       Sign-In and Security → App-Specific Passwords. Or use an App Store
#       Connect API key with --key/--key-id/--issuer instead.)
#
# Usage:
#   ./Scripts/notarize.sh
#
set -euo pipefail
cd "$(dirname "$0")/.."

TEAM_ID="${TEAM_ID:-P8FLGJ3757}"
NOTARY_PROFILE="${NOTARY_PROFILE:-cratebar}"
VERSION="${1:-1.0}"

# Resolve the Developer ID Application identity from the keychain.
SIGN_IDENTITY="${SIGN_IDENTITY:-$(security find-identity -v -p codesigning \
  | grep "Developer ID Application" | grep "${TEAM_ID}" | head -1 \
  | sed -E 's/.*"(.*)"/\1/')}"

if [[ -z "${SIGN_IDENTITY}" ]]; then
  echo "✗ No 'Developer ID Application' certificate found for team ${TEAM_ID}." >&2
  echo "  Create one in Xcode → Settings → Accounts → Manage Certificates → +." >&2
  exit 1
fi

echo "▸ Building + signing…"
SIGN_IDENTITY="${SIGN_IDENTITY}" ./Scripts/build-app.sh

APP="build/Cratebar.app"
ZIP="build/Cratebar-${VERSION}.zip"

echo "▸ Zipping for notarization…"
rm -f "${ZIP}"
ditto -c -k --keepParent "${APP}" "${ZIP}"

echo "▸ Submitting to Apple notary service (this can take a few minutes)…"
xcrun notarytool submit "${ZIP}" --keychain-profile "${NOTARY_PROFILE}" --wait

echo "▸ Stapling ticket to the app…"
xcrun stapler staple "${APP}"
xcrun stapler validate "${APP}"

echo "▸ Re-zipping the stapled app for distribution…"
rm -f "${ZIP}"
ditto -c -k --keepParent "${APP}" "${ZIP}"

echo "✅ Notarized + stapled: ${ZIP}"
echo "   sha256: $(shasum -a 256 "${ZIP}" | awk '{print $1}')"
echo "   Gatekeeper: $(spctl -a -vv -t install "${APP}" 2>&1 | tr '\n' ' ')"
