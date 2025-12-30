#!/bin/bash
# TranslateTopBar - Build and Create DMG Script
# Usage: ./build_dmg.sh [version]

set -e

VERSION=${1:-"1.0.0"}
PROJECT_NAME="TranslateTopBar"
APP_NAME="TranslateTopBarApp"
SCHEME="TranslateTopBarApp"
PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
BUILD_DIR="$PROJECT_DIR/build"
EXPORT_DIR="$BUILD_DIR/export"
DMG_NAME="${PROJECT_NAME}-${VERSION}.dmg"

echo "🏗️  Building ${PROJECT_NAME} v${VERSION}..."

# Clean previous builds
echo "🧹 Cleaning previous builds..."
rm -rf "$BUILD_DIR"
mkdir -p "$EXPORT_DIR"

# Build and archive
echo "📦 Creating archive..."
xcodebuild archive \
  -project "${PROJECT_NAME}.xcodeproj" \
  -scheme "$SCHEME" \
  -configuration Release \
  -archivePath "$BUILD_DIR/${APP_NAME}.xcarchive" \
  CODE_SIGN_IDENTITY="-" \
  CODE_SIGN_STYLE=Manual \
  DEVELOPMENT_TEAM="" \
  | xcpretty || echo "Note: xcpretty not installed, showing raw output"

# Export archive
echo "📤 Exporting application..."
xcodebuild -exportArchive \
  -archivePath "$BUILD_DIR/${APP_NAME}.xcarchive" \
  -exportPath "$EXPORT_DIR" \
  -exportOptionsPlist "$PROJECT_DIR/ExportOptions.plist"

# Check if app exists
if [ ! -d "$EXPORT_DIR/${APP_NAME}.app" ]; then
  echo "❌ Error: ${APP_NAME}.app not found in export directory"
  echo "📂 Contents of export directory:"
  ls -la "$EXPORT_DIR"
  exit 1
fi

echo "✅ App exported successfully to: $EXPORT_DIR/${APP_NAME}.app"

# Create DMG
echo "💿 Creating DMG..."
if command -v create-dmg &> /dev/null; then
  # Use create-dmg if available (more polished)
  create-dmg \
    --volname "$PROJECT_NAME" \
    --window-pos 200 120 \
    --window-size 600 400 \
    --icon-size 100 \
    --icon "${APP_NAME}.app" 175 120 \
    --app-drop-link 425 120 \
    --no-internet-enable \
    "$BUILD_DIR/$DMG_NAME" \
    "$EXPORT_DIR/${APP_NAME}.app" || {
      echo "⚠️  create-dmg failed, falling back to hdiutil"
      rm -f "$BUILD_DIR/$DMG_NAME"
      hdiutil create -volname "$PROJECT_NAME" \
        -srcfolder "$EXPORT_DIR/${APP_NAME}.app" \
        -ov -format UDZO \
        "$BUILD_DIR/$DMG_NAME"
    }
else
  # Fallback to hdiutil
  echo "ℹ️  create-dmg not found, using hdiutil (install with: brew install create-dmg)"
  hdiutil create -volname "$PROJECT_NAME" \
    -srcfolder "$EXPORT_DIR/${APP_NAME}.app" \
    -ov -format UDZO \
    "$BUILD_DIR/$DMG_NAME"
fi

echo ""
echo "✨ Build complete!"
echo "📦 DMG location: $BUILD_DIR/$DMG_NAME"
echo "📊 DMG size: $(du -h "$BUILD_DIR/$DMG_NAME" | cut -f1)"
echo ""
echo "🚀 To test the app:"
echo "   open \"$EXPORT_DIR/${APP_NAME}.app\""
echo ""
echo "📤 To install:"
echo "   1. Open $DMG_NAME"
echo "   2. Drag ${APP_NAME}.app to Applications folder"
