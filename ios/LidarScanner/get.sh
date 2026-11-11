#!/bin/bash
# Downloads (or updates) LiDAR Scanner into ~/LidarScanner, then builds it and
# installs it on the iPhone connected to this Mac. Run it with:
#
#   curl -fsSL https://raw.githubusercontent.com/MarioNodeFlow/MarioNodeFlow.github.io/refs/heads/claude/iphone-lidar-3d-mesh-7037om/ios/LidarScanner/get.sh | bash
#
set -uo pipefail
REPO="https://github.com/MarioNodeFlow/MarioNodeFlow.github.io.git"
BRANCH="claude/iphone-lidar-3d-mesh-7037om"
SRC="$HOME/LidarScanner"

if ! xcode-select -p >/dev/null 2>&1; then
  echo "Xcode isn't installed. Get it from the Mac App Store, open it once, then run this again."
  exit 1
fi

if [ -d "$SRC/.git" ]; then
  echo "Updating LiDAR Scanner…"
  git -C "$SRC" fetch -q --depth 1 origin "$BRANCH" && git -C "$SRC" reset -q --hard FETCH_HEAD \
    || echo "Couldn't update; installing the version already on this Mac."
elif [ -e "$SRC" ]; then
  echo "$SRC already exists and isn't a LiDAR Scanner download. Rename or remove it, then run this again."
  exit 1
else
  echo "Downloading LiDAR Scanner…"
  git clone -q --depth 1 -b "$BRANCH" "$REPO" "$SRC" || { echo "Download failed. Check your internet connection."; exit 1; }
fi

exec bash "$SRC/ios/LidarScanner/install.sh"
