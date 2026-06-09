#!/usr/bin/env bash
#
# Shared notarytool helper, sourced by notarize.sh and make-dmg.sh.
#
# Submits a file to the Apple notary service and waits for the verdict, using
# whichever credentials are available:
#   - explicit Apple ID creds (APPLE_ID + APPLE_APP_PASSWORD + TEAM_ID) — used in CI
#   - otherwise a stored keychain profile (NOTARY_PROFILE, default "cratebar") — local
#
notarize_file() {
  local file="$1"
  if [[ -n "${APPLE_ID:-}" && -n "${APPLE_APP_PASSWORD:-}" && -n "${TEAM_ID:-}" ]]; then
    echo "  (notarizing with Apple ID ${APPLE_ID})"
    xcrun notarytool submit "$file" \
      --apple-id "$APPLE_ID" --team-id "$TEAM_ID" --password "$APPLE_APP_PASSWORD" --wait
  else
    echo "  (notarizing with keychain profile ${NOTARY_PROFILE:-cratebar})"
    xcrun notarytool submit "$file" --keychain-profile "${NOTARY_PROFILE:-cratebar}" --wait
  fi
}
