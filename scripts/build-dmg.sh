#!/bin/bash
set -e

APP_NAME="DevKit"
SCHEME="DevKit"
BUILD_DIR="./build/Build/Products/Release"
DMG_NAME="DevKit-1.0.0.dmg"
DMG_DIR="./dist"

echo "=== Building $APP_NAME (Release) ==="
xcodebuild -project DevKit.xcodeproj \
    -scheme "$SCHEME" \
    -configuration Release \
    -derivedDataPath ./build \
    clean build

APP_PATH="$BUILD_DIR/$APP_NAME.app"

if [ ! -d "$APP_PATH" ]; then
    echo "ERROR: $APP_PATH not found"
    exit 1
fi

echo "=== Code Signing (ad-hoc) ==="
codesign --force --deep --sign - "$APP_PATH"
codesign --verify "$APP_PATH" && echo "Code signing verified."

echo "=== Creating DMG ==="
mkdir -p "$DMG_DIR"
rm -f "$DMG_DIR/$DMG_NAME"

# Create temporary DMG directory
DMG_TMP="./build/dmg_tmp"
rm -rf "$DMG_TMP"
mkdir -p "$DMG_TMP"
cp -R "$APP_PATH" "$DMG_TMP/"
ln -s /Applications "$DMG_TMP/Applications"

hdiutil create -volname "$APP_NAME" \
    -srcfolder "$DMG_TMP" \
    -ov -format UDZO \
    "$DMG_DIR/$DMG_NAME"

rm -rf "$DMG_TMP"

echo ""
echo "=== Done ==="
echo "App:  $APP_PATH"
echo "DMG:  $DMG_DIR/$DMG_NAME"
echo ""
echo "To install: open $DMG_DIR/$DMG_NAME and drag to Applications"
