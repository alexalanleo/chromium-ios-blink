#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config.sh"

export PATH="$CHROMIUM_WORK_ROOT/depot_tools:$CHROMIUM_WORK_ROOT/depot_tools/python-bin:$PATH"
if [[ ! -d "$CHROMIUM_SRC" ]]; then
  "$(dirname "$0")/bootstrap-chromium.sh"
fi

if ! security find-identity -v -p codesigning | grep -q ' valid identities found'; then
  echo "ERROR: no valid Apple code-signing identity is installed in this runner keychain." >&2
  exit 5
fi

cd "$CHROMIUM_SRC"
OUT="out/Release-iphoneos"

# Physical-device Chrome requires provisioning profiles for the main app and
# its extensions, plus the entitlements described in upstream documentation.
autoninja -C "$OUT" chrome

APP="$OUT/Chromium.app"
if [[ ! -d "$APP" ]]; then
  echo "ERROR: expected $APP. Inspect the GN/Ninja output; upstream target output may have changed." >&2
  exit 6
fi

mkdir -p "${ARTIFACTS_DIR:-$CHROMIUM_WORK_ROOT/artifacts/device}"
"$SCRIPT_DIR/package-ipa.sh" "$APP" "${ARTIFACTS_DIR:-$CHROMIUM_WORK_ROOT/artifacts/device}/ChromiumIOS.ipa"
