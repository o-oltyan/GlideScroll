#!/bin/bash
# Builds the app, packages a DMG, and publishes a GitHub release.
#   VERSION=1.0.0 Scripts/release.sh
set -euo pipefail
cd "$(dirname "$0")/.."

VERSION="${VERSION:-1.0.0}"

command -v create-dmg >/dev/null || { echo "create-dmg missing: brew install create-dmg"; exit 1; }

VERSION="$VERSION" Scripts/build-app.sh

DMG="dist/GlideScroll-$VERSION.dmg"
rm -f "$DMG"
create-dmg \
    --volname "GlideScroll" \
    --volicon dist/GlideScroll.icns \
    --window-size 640 400 \
    --icon-size 128 \
    --icon "GlideScroll.app" 160 185 \
    --app-drop-link 480 185 \
    "$DMG" dist/GlideScroll.app

NOTES="$(mktemp)"
cat > "$NOTES" <<EOF
Smooth, trackpad-like scrolling for your mouse on macOS.

**Install:** drag GlideScroll to Applications, right-click → Open (not notarized), grant Accessibility access when prompted.
EOF
gh release create "v$VERSION" "$DMG" \
    --repo o-oltyan/GlideScroll \
    --title "GlideScroll $VERSION" \
    --notes-file "$NOTES"
rm -f "$NOTES"
echo "Released v$VERSION"
