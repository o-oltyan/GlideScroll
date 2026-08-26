#!/bin/bash
# Builds GlideScroll.app into dist/.
#
#   VERSION=1.0.0 Scripts/build-app.sh
#   SIGN_IDENTITY="GlideScroll Dev" Scripts/build-app.sh   # stable identity so
#   Accessibility permission survives rebuilds; defaults to ad-hoc ("-").
set -euo pipefail
cd "$(dirname "$0")/.."

VERSION="${VERSION:-1.0.0}"
BUILD_NUM="${BUILD_NUM:-$(git rev-list --count HEAD 2>/dev/null || echo 1)}"
IDENTITY="${SIGN_IDENTITY:--}"

swift build -c release --arch arm64

APP=dist/GlideScroll.app
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp .build/arm64-apple-macosx/release/GlideScroll "$APP/Contents/MacOS/"

if [ ! -f dist/GlideScroll.icns ] && [ -f Scripts/make-icon.swift ]; then
    swift Scripts/make-icon.swift dist
fi
[ -f dist/GlideScroll.icns ] && cp dist/GlideScroll.icns "$APP/Contents/Resources/"

sed -e "s/__VERSION__/$VERSION/" -e "s/__BUILD__/$BUILD_NUM/" \
    Support/Info.plist > "$APP/Contents/Info.plist"

codesign --force -s "$IDENTITY" "$APP"
echo "Built $APP (version $VERSION, build $BUILD_NUM, identity: $IDENTITY)"
