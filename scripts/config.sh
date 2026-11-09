#!/usr/bin/env bash
# Customize these values before device signing.
# BUNDLE_ID_PREFIX must be a reverse-DNS prefix you control.
export BUNDLE_ID_PREFIX="${BUNDLE_ID_PREFIX:-com.example}"
export CHROMIUM_APP_BUNDLE_ID="${CHROMIUM_APP_BUNDLE_ID:-${BUNDLE_ID_PREFIX}.chrome.ios.dev}"
export CONTENT_SHELL_BUNDLE_ID="${CONTENT_SHELL_BUNDLE_ID:-${BUNDLE_ID_PREFIX}.content-shell}"
export CHROMIUM_WORK_ROOT="${CHROMIUM_WORK_ROOT:-${RUNNER_TEMP:-$HOME}/chromium-ios-work}"
export CHROMIUM_SRC="${CHROMIUM_SRC:-${CHROMIUM_WORK_ROOT}/src}"
export BUILD_CONFIG="${BUILD_CONFIG:-Debug}"
