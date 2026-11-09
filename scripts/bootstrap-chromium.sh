#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/config.sh"

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "ERROR: Chromium iOS builds require macOS + Xcode. Use a GitHub Actions macOS runner." >&2
  exit 2
fi

xcode_ver="$(xcodebuild -version | awk '/Xcode/ {print $2; exit}')"
python3 - "$xcode_ver" <<'PY'
import sys
v = tuple(int(x) for x in sys.argv[1].split(".")[:2])
if v < (26, 0):
    raise SystemExit(f"ERROR: Chromium's current iOS instructions require Xcode 26.0+. Found {sys.argv[1]}")
print(f"Using Xcode {sys.argv[1]}")
PY

mkdir -p "$CHROMIUM_WORK_ROOT"
cd "$CHROMIUM_WORK_ROOT"

if [[ ! -d "$CHROMIUM_WORK_ROOT/depot_tools" ]]; then
  git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git
fi
export PATH="$CHROMIUM_WORK_ROOT/depot_tools:$CHROMIUM_WORK_ROOT/depot_tools/python-bin:$PATH"
export DEPOT_TOOLS_UPDATE=1

if [[ ! -d "$CHROMIUM_SRC/.git" ]]; then
  fetch --no-history ios
fi

if [[ ! -d "$CHROMIUM_SRC" ]]; then
  echo "ERROR: expected Chromium source at $CHROMIUM_SRC" >&2
  exit 3
fi

# The .setup-gn file belongs beside src/, i.e. in the checkout root.
cat > "$CHROMIUM_WORK_ROOT/.setup-gn" <<EOF
[gn_args]
use_blink = true
ios_app_bundle_id_prefix = "$BUNDLE_ID_PREFIX"
ios_content_shell_bundle_identifier = "$CONTENT_SHELL_BUNDLE_ID"
ios_chromium_bundle_id = "$CHROMIUM_APP_BUNDLE_ID"
EOF

if [[ -n "${IOS_CODE_SIGNING_IDENTITY:-}" ]]; then
  printf 'ios_code_signing_identity = "%s"\\n' "$IOS_CODE_SIGNING_IDENTITY" >> "$CHROMIUM_WORK_ROOT/.setup-gn"
fi

cd "$CHROMIUM_SRC"
python3 ios/build/tools/setup-gn.py

echo "Chromium source: $CHROMIUM_SRC"
echo "Configured Blink-enabled iOS build directories."
