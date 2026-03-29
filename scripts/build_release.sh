#!/bin/bash
set -euo pipefail

# FrozenDock Release Build Script
# Usage: ./scripts/build_release.sh [--notarize]
#
# Prerequisites:
#   - Xcode installed
#   - For signing: Apple Developer certificate in Keychain
#   - For notarization: App-specific password in Keychain (see --notarize)

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
BUILD_DIR="$PROJECT_DIR/build"
ARCHIVE_PATH="$BUILD_DIR/FrozenDock.xcarchive"
EXPORT_DIR="$BUILD_DIR/export"
APP_NAME="FrozenDock"
SCHEME="FrozenDock"
PROJECT="$PROJECT_DIR/FrozenDock.xcodeproj"

NOTARIZE=false
if [[ "${1:-}" == "--notarize" ]]; then
    NOTARIZE=true
fi

echo "=== FrozenDock Release Build ==="
echo ""

# Clean build directory
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

# Step 1: Archive
echo "→ Archiving..."
xcodebuild archive \
    -project "$PROJECT" \
    -scheme "$SCHEME" \
    -configuration Release \
    -archivePath "$ARCHIVE_PATH" \
    -quiet \
    CODE_SIGN_IDENTITY="-" \
    CODE_SIGNING_REQUIRED=NO \
    CODE_SIGNING_ALLOWED=NO

echo "  Archive created at $ARCHIVE_PATH"

# Step 2: Export .app from archive
echo "→ Exporting .app..."
mkdir -p "$EXPORT_DIR"

# Copy the .app directly from the archive (works without signing)
cp -R "$ARCHIVE_PATH/Products/Applications/$APP_NAME.app" "$EXPORT_DIR/$APP_NAME.app"

echo "  App exported to $EXPORT_DIR/$APP_NAME.app"

# Step 3: Ad-hoc sign (allows running without Developer ID)
echo "→ Signing (ad-hoc)..."
codesign --force --deep --sign - "$EXPORT_DIR/$APP_NAME.app"
echo "  Signed (ad-hoc)"

# Step 4: Create DMG
echo "→ Creating DMG..."
DMG_PATH="$BUILD_DIR/$APP_NAME.dmg"
DMG_TEMP="$BUILD_DIR/dmg_temp"

mkdir -p "$DMG_TEMP"
cp -R "$EXPORT_DIR/$APP_NAME.app" "$DMG_TEMP/"

# Create a symlink to /Applications for easy drag-and-drop install
ln -s /Applications "$DMG_TEMP/Applications"

hdiutil create \
    -volname "$APP_NAME" \
    -srcfolder "$DMG_TEMP" \
    -ov \
    -format UDZO \
    "$DMG_PATH" \
    -quiet

rm -rf "$DMG_TEMP"
echo "  DMG created at $DMG_PATH"

# Step 5: Also create a zip
echo "→ Creating zip..."
ZIP_PATH="$BUILD_DIR/$APP_NAME.zip"
cd "$EXPORT_DIR"
zip -r -q "$ZIP_PATH" "$APP_NAME.app"
cd "$PROJECT_DIR"
echo "  Zip created at $ZIP_PATH"

# Step 6: Notarize (optional)
if $NOTARIZE; then
    echo "→ Notarizing..."
    echo "  Submitting DMG for notarization..."
    xcrun notarytool submit "$DMG_PATH" \
        --keychain-profile "AC_PASSWORD" \
        --wait
    echo "  Stapling notarization ticket..."
    xcrun stapler staple "$DMG_PATH"
    echo "  Notarization complete!"
fi

# Summary
echo ""
echo "=== Build Complete ==="
echo ""
echo "  App:  $EXPORT_DIR/$APP_NAME.app"
echo "  DMG:  $DMG_PATH"
echo "  Zip:  $ZIP_PATH"
echo ""

# Print sizes
echo "  Sizes:"
echo "    DMG: $(du -h "$DMG_PATH" | cut -f1)"
echo "    Zip: $(du -h "$ZIP_PATH" | cut -f1)"
echo ""
echo "Upload DMG and/or Zip to GitHub Releases."
