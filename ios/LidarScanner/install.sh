#!/bin/bash
# Builds LiDAR Scanner and installs it on the iPhone connected to this Mac.
#
#   bash install.sh
#
# One-time setup: install Xcode, open it once, and add your Apple ID in
# Xcode › Settings › Accounts. Then plug in your iPhone and run this script.
# Run it again any time to install a newer version (or to renew the 7-day
# signature you get with a free Apple ID).
#
# Optional overrides: LIDAR_TEAM_ID, LIDAR_BUNDLE_ID, LIDAR_DEVICE (UDID).

set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUNDLE_ID="${LIDAR_BUNDLE_ID:-com.marionodeflow.lidarscanner}"
BUILD_DIR="$PROJECT_DIR/build"
LOG="$BUILD_DIR/build.log"

step() { printf '\n\033[1;36m▶ %s\033[0m\n' "$1"; }
ok()   { printf '\033[1;32m✓ %s\033[0m\n' "$1"; }
fail() { printf '\n\033[1;31m✖ %s\033[0m\n\n' "$1" >&2; exit 1; }

cd "$PROJECT_DIR"
mkdir -p "$BUILD_DIR"

# ---------------------------------------------------------------- Xcode
step "Checking Xcode"
if ! xcodebuild -version >/dev/null 2>&1; then
  if [ -d /Applications/Xcode.app ]; then
    fail "Xcode is installed but not selected. Run this, then try again:
    sudo xcode-select -s /Applications/Xcode.app"
  fi
  fail "Xcode isn't installed. Get it from the Mac App Store, open it once, then run this again."
fi
if ! xcodebuild -checkFirstLaunchStatus >/dev/null 2>&1; then
  fail "Xcode needs to finish its first-launch setup. Open Xcode once, let it install its components, then run this again."
fi
if ! xcodebuild -showsdks 2>/dev/null | grep -q iphoneos; then
  step "Downloading the iOS platform for Xcode (one time, a few GB)"
  xcodebuild -downloadPlatform iOS
fi
ok "$(xcodebuild -version | head -1)"

# --------------------------------------------------------------- iPhone
step "Looking for your iPhone"
DEVICES_JSON="$BUILD_DIR/devices.json"
xcrun devicectl list devices --json-output "$DEVICES_JSON" >/dev/null 2>&1 || true

field() { plutil -extract "result.devices.$1.$2" raw -o - "$DEVICES_JSON" 2>/dev/null || true; }

UDID="${LIDAR_DEVICE:-}"
DEVICE_NAME=""
DEV_MODE=""
if [ -z "$UDID" ] && [ -f "$DEVICES_JSON" ]; then
  i=0
  while [ -n "$(field "$i" identifier)" ]; do
    if [ "$(field "$i" hardwareProperties.platform)" = "iOS" ] \
       && [ "$(field "$i" connectionProperties.pairingState)" = "paired" ]; then
      UDID="$(field "$i" hardwareProperties.udid)"
      DEVICE_NAME="$(field "$i" deviceProperties.name)"
      DEV_MODE="$(field "$i" deviceProperties.developerModeStatus)"
      break
    fi
    i=$((i + 1))
  done
fi

if [ -z "$UDID" ]; then
  fail "No iPhone found. Plug it in with a cable, unlock it, and tap \"Trust This Computer\".
  Then run this again."
fi
ok "Found ${DEVICE_NAME:-device} ($UDID)"

if [ "$DEV_MODE" = "disabled" ]; then
  fail "Developer Mode is off on your iPhone. Turn it on in
  Settings › Privacy & Security › Developer Mode, let the iPhone restart, then run this again."
fi

# ----------------------------------------------------------------- Team
step "Finding your Apple developer team"
TEAM_ID="${LIDAR_TEAM_ID:-}"
if [ -z "$TEAM_ID" ]; then
  TEAM_ID="$(security find-certificate -a -c "Apple Development" -p 2>/dev/null \
    | openssl x509 -noout -subject 2>/dev/null \
    | sed -n 's/.*OU *= *\([A-Z0-9]\{10\}\).*/\1/p' | head -1 || true)"
fi
if [ -z "$TEAM_ID" ]; then
  for key in IDEProvisioningTeamByIdentifier IDEProvisioningTeams; do
    TEAM_ID="$(defaults read com.apple.dt.Xcode "$key" 2>/dev/null \
      | sed -n 's/.*teamID = "*\([A-Z0-9]\{10\}\)"*;.*/\1/p' | head -1 || true)"
    [ -n "$TEAM_ID" ] && break
  done
fi
if [ -z "$TEAM_ID" ]; then
  open -a Xcode || true
  fail "No Apple ID found in Xcode. In Xcode open Settings › Accounts, click +, sign in
  with your Apple ID (a free one works), then run this again."
fi
ok "Team $TEAM_ID"

# ---------------------------------------------------------------- Build
step "Building LiDAR Scanner (the first build takes a minute or two)"
set +e
xcodebuild \
  -project LidarScanner.xcodeproj \
  -scheme LidarScanner \
  -configuration Release \
  -destination "id=$UDID" \
  -derivedDataPath "$BUILD_DIR" \
  -allowProvisioningUpdates \
  -allowProvisioningDeviceRegistration \
  DEVELOPMENT_TEAM="$TEAM_ID" \
  CODE_SIGN_STYLE=Automatic \
  PRODUCT_BUNDLE_IDENTIFIER="$BUNDLE_ID" \
  build >"$LOG" 2>&1
BUILD_STATUS=$?
set -e

if [ $BUILD_STATUS -ne 0 ]; then
  ERRORS="$(grep -E "error:|BUILD FAILED" "$LOG" | sort -u | head -40)"
  printf '%s\n' "$ERRORS"
  printf '%s\n' "$ERRORS" | pbcopy
  fail "Build failed. The errors are copied to your clipboard: paste them into Claude.
  Full log: $LOG"
fi
ok "Build succeeded"

APP="$BUILD_DIR/Build/Products/Release-iphoneos/LidarScanner.app"
[ -d "$APP" ] || fail "Build finished but the app wasn't found at $APP"

# -------------------------------------------------------------- Install
step "Installing on ${DEVICE_NAME:-your iPhone}"
if ! xcrun devicectl device install app --device "$UDID" "$APP" >"$BUILD_DIR/install.log" 2>&1; then
  cat "$BUILD_DIR/install.log"
  fail "Install failed. Make sure the iPhone is unlocked, then run this again."
fi
ok "Installed"

step "Opening the app"
if xcrun devicectl device process launch --device "$UDID" "$BUNDLE_ID" >/dev/null 2>&1; then
  ok "LiDAR Scanner is running on your iPhone"
else
  printf '%s\n' "The app is installed, but iOS has to trust your developer certificate first:
  On the iPhone open Settings › General › VPN & Device Management,
  tap your Apple ID under \"Developer App\" and tap Trust.
  Then open LiDAR Scanner from the home screen."
fi

printf '\n%s\n\n' "Done. With a free Apple ID the app works for 7 days; run this again to renew it."
