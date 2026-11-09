\
#!/usr/bin/env bash
set -euo pipefail

: "${IOS_SIGNING_CERTIFICATE_P12_BASE64:?Missing P12 base64 secret}"
: "${IOS_SIGNING_CERTIFICATE_PASSWORD:?Missing P12 password secret}"
: "${IOS_PROVISIONING_PROFILES_ZIP_BASE64:?Missing provisioning-profiles ZIP base64 secret}"
: "${IOS_KEYCHAIN_PASSWORD:?Missing temporary keychain password}"

KEYCHAIN="$RUNNER_TEMP/chromium-build.keychain-db"
P12="$RUNNER_TEMP/signing.p12"
PROFILE_ZIP="$RUNNER_TEMP/profiles.zip"

printf '%s' "$IOS_SIGNING_CERTIFICATE_P12_BASE64" | base64 --decode > "$P12"
printf '%s' "$IOS_PROVISIONING_PROFILES_ZIP_BASE64" | base64 --decode > "$PROFILE_ZIP"

security create-keychain -p "$IOS_KEYCHAIN_PASSWORD" "$KEYCHAIN"
security set-keychain-settings -lut 21600 "$KEYCHAIN"
security unlock-keychain -p "$IOS_KEYCHAIN_PASSWORD" "$KEYCHAIN"
security import "$P12" -k "$KEYCHAIN" -P "$IOS_SIGNING_CERTIFICATE_PASSWORD" -T /usr/bin/codesign -T /usr/bin/security
security set-key-partition-list -S apple-tool:,apple: -s -k "$IOS_KEYCHAIN_PASSWORD" "$KEYCHAIN"
security list-keychains -d user -s "$KEYCHAIN" login.keychain-db

PROFILE_DIR="$RUNNER_TEMP/profiles"
mkdir -p "$PROFILE_DIR" "$HOME/Library/MobileDevice/Provisioning Profiles"
unzip -q "$PROFILE_ZIP" -d "$PROFILE_DIR"

installed=0
while IFS= read -r -d '' profile; do
  uuid=$(/usr/libexec/PlistBuddy -c 'Print :UUID' /dev/stdin < <(security cms -D -i "$profile"))
  cp "$profile" "$HOME/Library/MobileDevice/Provisioning Profiles/$uuid.mobileprovision"
  installed=$((installed + 1))
done < <(find "$PROFILE_DIR" -type f \( -name '*.mobileprovision' -o -name '*.provisionprofile' \) -print0)

if [[ "$installed" -lt 1 ]]; then
  echo "ERROR: no provisioning profiles found in the supplied ZIP." >&2
  exit 7
fi

identity="$(security find-identity -v -p codesigning "$KEYCHAIN" | awk '/ valid identities found/ {next} /"[^\"]+"/ {print $2; exit}')"
if [[ -z "$identity" ]]; then
  echo "ERROR: imported certificate did not produce a valid signing identity." >&2
  exit 8
fi

echo "IOS_CODE_SIGNING_IDENTITY=$identity" >> "$GITHUB_ENV"
echo "Imported signing identity and $installed provisioning profile(s)."
