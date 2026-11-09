# Chromium iOS Blink starter

This is a starter repository for building Chromium's **experimental Blink-enabled iOS targets** on GitHub Actions macOS runners. It is not a completed browser port and does not turn the upstream iOS Chrome app into a production Blink browser.

## Reality check

- Linux is suitable for editing this repository and dispatching workflows.
- Chromium's iOS build requires a Mac and Xcode 26 or newer.
- Upstream documents `use_blink = true` for iOS, but explicitly labels Blink-on-iOS experimental and intended for analysis.
- The documented Blink targets are `content_shell` and `chrome`. Start with simulator builds.
- Device builds require appropriate Apple signing assets and entitlements. In particular, upstream says the Chrome app needs the `com.apple.developer.kernel.extended-virtual-addressing` entitlement on a physical device, plus profiles for the app and its extensions.
- A compiled `.app` is not automatically an installable `.ipa`. The packaging script checks that the app is already signed before creating an IPA.

Your iPad Pro 12.9-inch (5th generation) has an Apple M1. This is an ARM64 device, but the experimental Blink target's physical-device support and the required entitlement must be validated independently. The iPadOS version alone does not guarantee compatibility.

## First run: simulator build

1. Create a GitHub repository and upload this starter.
2. Open **Actions** and run **Chromium iOS (Blink)** with `build_mode=simulator`.
3. The workflow fetches upstream Chromium with `fetch --no-history ios`, configures Blink, then builds `content_shell` and `chrome` for the iOS simulator.
4. Download the `blink-ios-simulator-apps` artifact. These are simulator `.app` bundles, **not an iPad IPA**.

The checkout and build are very large. A GitHub-hosted runner may run out of disk space, memory, or time. If that happens, use a larger/self-hosted macOS runner with sufficient free disk and RAM. The workflow intentionally does not cache the full Chromium source tree.

## Device build and IPA

The `device` workflow path is deliberately gated. Before using it:

1. Set a real bundle ID prefix in `scripts/config.sh` (for example, a domain you control).
2. Enroll/configure Apple signing for the iPad.
3. Obtain every provisioning profile required by the Chromium Chrome app and its extensions, with matching App Groups and capabilities.
4. Confirm that Apple has provisioned the extended-virtual-addressing entitlement for the app.
5. Store signing materials as GitHub Actions secrets. Do not commit certificates, private keys, profiles, or passwords.

The official Chromium instructions list these Chrome profile identifiers under the configured prefix:
- `${prefix}.chrome.ios.dev`
- `${prefix}.chrome.ios.dev.CredentialProviderExtension`
- `${prefix}.chrome.ios.dev.IntentsExtension`
- `${prefix}.chrome.ios.dev.OpenExtension`
- `${prefix}.chrome.ios.dev.ShareExtension`
- `${prefix}.chrome.ios.dev.WidgetKitExtension`

The app and extensions also require the documented App Groups. The Credential Provider extension and main app have additional capabilities. Review the current upstream instructions before attempting device signing.

The workflow's `device` option imports signing material, builds the upstream `chrome` target and packages `Chromium.app` only if it exists and is already signed. Upstream output names or signing requirements may change; check the build log and current Chromium docs if the script needs adjustment.

Configure these GitHub repository secrets:
- `IOS_SIGNING_CERTIFICATE_P12_BASE64`: base64-encoded Apple signing certificate `.p12`.
- `IOS_SIGNING_CERTIFICATE_PASSWORD`: password for that `.p12`.
- `IOS_PROVISIONING_PROFILES_ZIP_BASE64`: base64-encoded ZIP containing all required `.mobileprovision` files.
- `IOS_KEYCHAIN_PASSWORD`: temporary password used for the runner keychain.

Configure this repository variable:
- `IOS_BUNDLE_ID_PREFIX`: your reverse-DNS prefix (not `com.example`).

The provisioning ZIP must contain the profiles for the main app and all required extensions, matching the bundle IDs and capabilities in the current Chromium instructions. The build will fail if Apple has not enabled the required entitlements. Use short-lived/revocable signing credentials and never print or commit their contents.

## Configuration

Edit `scripts/config.sh`:

```bash
BUNDLE_ID_PREFIX="com.example"
CHROMIUM_APP_BUNDLE_ID="${BUNDLE_ID_PREFIX}.chrome.ios.dev"
CONTENT_SHELL_BUNDLE_ID="${BUNDLE_ID_PREFIX}.content-shell"
```

Replace `com.example` with an identifier you control before device signing. Do not use the example identifiers for distribution.

## Local Linux workflow

Linux can edit files and trigger GitHub Actions, but cannot run the iOS/Xcode build. Example:

```bash
git add .
git commit -m "Add Chromium iOS Blink build starter"
git push
```

## Security and scope

This is an experimental research build. Do not use it as your everyday browser or for sensitive accounts. A successful build is not evidence of production-grade browser security, sandboxing, process isolation, or compatibility.

## Upstream references

- [Chromium iOS build instructions](https://chromium.googlesource.com/chromium/src/+/main/docs/ios/build_instructions.md)
- [Chromium iOS build instructions on GitHub](https://github.com/chromium/chromium/blob/main/docs/ios/build_instructions.md)

Chromium is licensed under its upstream open-source licenses. This starter does not redistribute Chromium source or binaries.
