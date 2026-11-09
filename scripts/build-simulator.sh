#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/config.sh"

export PATH="$CHROMIUM_WORK_ROOT/depot_tools:$CHROMIUM_WORK_ROOT/depot_tools/python-bin:$PATH"
if [[ ! -d "$CHROMIUM_SRC" ]]; then
  "$(dirname "$0")/bootstrap-chromium.sh"
fi

cd "$CHROMIUM_SRC"
OUT="out/${BUILD_CONFIG}-iphonesimulator"
mkdir -p "$OUT"

# These are the upstream-documented Blink-capable iOS targets.
autoninja -C "$OUT" content_shell chrome

ARTIFACTS="${ARTIFACTS_DIR:-$CHROMIUM_WORK_ROOT/artifacts/simulator}"
mkdir -p "$ARTIFACTS"
find "$OUT" -maxdepth 1 -type d -name '*.app' -print0 |
while IFS= read -r -d '' app; do
  ditto "$app" "$ARTIFACTS/$(basename "$app")"
done

if [[ -z "$(find "$ARTIFACTS" -maxdepth 1 -type d -name '*.app' -print -quit)" ]]; then
  echo "ERROR: build completed but no .app bundles were found in $OUT" >&2
  exit 4
fi

echo "Simulator app bundles copied to $ARTIFACTS"
