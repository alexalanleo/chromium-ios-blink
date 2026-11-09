#!/usr/bin/env bash
set -euo pipefail

APP_PATH="${1:?Usage: package-ipa.sh /path/to/Chromium.app [output.ipa]}"
OUTPUT_IPA="${2:-ChromiumIOS.ipa}"
OUTPUT_IPA="$(python3 -c 'import os,sys; print(os.path.abspath(sys.argv[1]))' "$OUTPUT_IPA")"

if [[ ! -d "$APP_PATH" ]]; then
  echo "ERROR: app bundle not found: $APP_PATH" >&2
  exit 2
fi
if [[ ! -f "$APP_PATH/Info.plist" ]]; then
  echo "ERROR: not an iOS .app bundle: $APP_PATH" >&2
  exit 2
fi

# Never package an unsigned simulator build as if it were device-installable.
if ! /usr/bin/codesign --verify --deep --strict "$APP_PATH"; then
  echo "ERROR: app is not validly signed. Install the correct identity, profiles and entitlements first." >&2
  exit 3
fi
if [[ ! -f "$APP_PATH/embedded.mobileprovision" ]]; then
  echo "ERROR: embedded.mobileprovision is missing; this is not a provisioned device app." >&2
  exit 4
fi

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/Payload"
ditto "$APP_PATH" "$tmp/Payload/$(basename "$APP_PATH")"
(
  cd "$tmp"
  /usr/bin/zip -qry "$tmp/ChromiumIOS.ipa" Payload
)
mkdir -p "$(dirname "$OUTPUT_IPA")"
mv "$tmp/ChromiumIOS.ipa" "$OUTPUT_IPA"
echo "Created $OUTPUT_IPA"
