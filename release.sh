#!/bin/bash
# Usage:
# ./release.sh [-v version] [-a arm64|x86_64|universal] \
#   [-n output_name] [-p product] [-i bundle_id] [-I icon.icon]

set -Eeuo pipefail
cd "$(dirname "$0")"

VERSION=""
ARCH=""
OUT_NAME="YT-SwiftLP"
PRODUCT="YT-SwiftLP"
BUNDLE_ID=""
ICON="appicon.icon"

SU_FEED_URL="${SU_FEED_URL:-}"
SU_PUBLIC_KEY="${SU_PUBLIC_KEY:-}"
BUILD_NUMBER="${BUILD_NUMBER:-1}"

usage() {
  echo "Usage: $0 [-v version] [-a arm64|x86_64|universal] [-n output_name] [-p product] [-i bundle_id] [-I icon.icon]"
}

while getopts "v:a:n:p:i:I:h" opt; do
  case "$opt" in
    v) VERSION="$OPTARG" ;;
    a) ARCH="$OPTARG" ;;
    n) OUT_NAME="$OPTARG" ;;
    p) PRODUCT="$OPTARG" ;;
    i) BUNDLE_ID="$OPTARG" ;;
    I) ICON="$OPTARG" ;;
    h) usage; exit 0 ;;
    *) usage >&2; exit 2 ;;
  esac
done

# Version
if [ -z "$VERSION" ]; then
  read -r -p "Version [1.0.0]: " VERSION
  VERSION="${VERSION:-1.0.0}"
fi

if ! [[ "$VERSION" =~ ^[0-9]+(\.[0-9]+){0,2}(-[A-Za-z0-9]+(\.[A-Za-z0-9]+)*)?$ ]]; then
  echo "Invalid version: $VERSION" >&2
  exit 1
fi

# Build number
if ! [[ "$BUILD_NUMBER" =~ ^[0-9]+$ ]]; then
  echo "BUILD_NUMBER must be a numeric value: $BUILD_NUMBER" >&2
  exit 1
fi

# Architecture
if [ -z "$ARCH" ]; then
  echo "Architecture:"
  echo "  1) Apple Silicon (arm64)"
  echo "  2) Intel (x86_64)"
  echo "  3) Universal"
  read -r -p "Choice [3]: " choice

  case "${choice:-3}" in
    1) ARCH="arm64" ;;
    2) ARCH="x86_64" ;;
    3) ARCH="universal" ;;
    *) echo "Invalid choice" >&2; exit 1 ;;
  esac
fi

case "$ARCH" in
  arm64|x86_64|universal) ;;
  *) echo "Invalid architecture: $ARCH" >&2; exit 1 ;;
esac

# Sparkle configuration
if [ -z "$SU_PUBLIC_KEY" ] || [ -z "$SU_FEED_URL" ]; then
  echo "SU_PUBLIC_KEY and SU_FEED_URL must be defined." >&2
  echo "Example:" >&2
  echo "export SU_PUBLIC_KEY='your_public_key'" >&2
  echo "export SU_FEED_URL='https://github.com/OWNER/REPO/releases/latest/download/appcast.xml'" >&2
  exit 1
fi

# Output name
if [ -z "$OUT_NAME" ]; then
  read -r -p "Output app name [$PRODUCT]: " OUT_NAME
  OUT_NAME="${OUT_NAME:-$PRODUCT}"
fi

# Bundle identifier
if [ -z "$BUNDLE_ID" ]; then
  SAFE_ID=$(printf '%s' "$OUT_NAME" |
    tr -cd '[:alnum:]' | tr '[:upper:]' '[:lower:]')
  BUNDLE_ID="com.example.${SAFE_ID}"
fi

# Resolve and validate the Icon Composer package.
if [ -n "$ICON" ]; then
  if [[ "$ICON" != *.icon ]] || [ ! -d "$ICON" ]; then
    echo "Icon must be an existing .icon package: $ICON" >&2
    exit 1
  fi

  ICON="$(cd "$(dirname "$ICON")" && pwd)/$(basename "$ICON")"

  if ! xcrun --find actool >/dev/null 2>&1; then
    echo "actool not found. Check your Xcode installation." >&2
    exit 1
  fi
fi

APP_DIR="$OUT_NAME.app"

echo "Product:      $PRODUCT"
echo "App:          $APP_DIR"
echo "Version:      $VERSION (build $BUILD_NUMBER)"
echo "Architecture: $ARCH"
echo "Bundle ID:    $BUNDLE_ID"
echo "Icon:         ${ICON:-none}"
echo

# Build the Swift executable.
if [ "$ARCH" = "universal" ]; then
  swift build -c release --arch arm64 --arch x86_64
  BIN_PATH=$(swift build -c release --arch arm64 --arch x86_64 --show-bin-path)
else
  swift build -c release --arch "$ARCH"
  BIN_PATH=$(swift build -c release --arch "$ARCH" --show-bin-path)
fi

if [ ! -f "$BIN_PATH/$PRODUCT" ]; then
  echo "Executable not found: $BIN_PATH/$PRODUCT" >&2
  ls "$BIN_PATH" >&2
  exit 1
fi

# Create the application bundle.
rm -rf "$APP_DIR"

mkdir -p \
  "$APP_DIR/Contents/MacOS" \
  "$APP_DIR/Contents/Resources" \
  "$APP_DIR/Contents/Frameworks"

cp "$BIN_PATH/$PRODUCT" \
   "$APP_DIR/Contents/MacOS/$OUT_NAME"

# Embed Sparkle.
if [ ! -d "$BIN_PATH/Sparkle.framework" ]; then
  echo "Sparkle.framework not found in: $BIN_PATH" >&2
  ls "$BIN_PATH" >&2
  exit 1
fi

cp -R "$BIN_PATH/Sparkle.framework" \
      "$APP_DIR/Contents/Frameworks/Sparkle.framework"

# Add the Frameworks runtime search path.
install_name_tool \
  -add_rpath "@executable_path/../Frameworks" \
  "$APP_DIR/Contents/MacOS/$OUT_NAME" 2>/dev/null || true

# Generate Info.plist.
cat > "$APP_DIR/Contents/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>$OUT_NAME</string>
    <key>CFBundleDisplayName</key>
    <string>$OUT_NAME</string>
    <key>CFBundleExecutable</key>
    <string>$OUT_NAME</string>
    <key>CFBundleIdentifier</key>
    <string>$BUNDLE_ID</string>
    <key>CFBundleVersion</key>
    <string>$BUILD_NUMBER</string>
    <key>CFBundleShortVersionString</key>
    <string>$VERSION</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>SUFeedURL</key>
    <string>$SU_FEED_URL</string>
    <key>SUPublicEDKey</key>
    <string>$SU_PUBLIC_KEY</string>
</dict>
</plist>
EOF

# Compile the Icon Composer asset, if supplied.

# Compile the Icon Composer asset, if supplied.
if [ -n "$ICON" ]; then
  ICON_NAME="$(basename "$ICON" .icon)"
  TEMP_DIR="$(mktemp -d)"
  trap 'rm -rf "$TEMP_DIR"' EXIT

  mkdir -p "$APP_DIR/Contents/Resources"

  PARTIAL_PLIST="$TEMP_DIR/partial.plist"

  echo "Compiling Icon Composer icon: $ICON_NAME"

  xcrun actool "$ICON" \
    --compile "$APP_DIR/Contents/Resources" \
    --output-format xml1 \
    --notices \
    --warnings \
    --errors \
    --output-partial-info-plist "$PARTIAL_PLIST" \
    --app-icon "$ICON_NAME" \
    --include-all-app-icons \
    --enable-on-demand-resources NO \
    --development-region en \
    --target-device mac \
    --minimum-deployment-target 13.0 \
    --platform macosx

  # Do not silently ship an app without its compiled icon.
  if [ ! -f "$APP_DIR/Contents/Resources/Assets.car" ]; then
    echo "Error: actool did not generate Assets.car." >&2
    echo "Check the .icon package and your Xcode version." >&2
    exit 1
  fi

  # Merge the metadata generated by actool into Info.plist.
  if [ -f "$PARTIAL_PLIST" ]; then
    /usr/libexec/PlistBuddy \
      -c "Merge $PARTIAL_PLIST" \
      "$APP_DIR/Contents/Info.plist"
  fi

  echo "Compiled icon resources:"
  ls -lh "$APP_DIR/Contents/Resources/Assets.car"

  # Verify the icon name is present in Info.plist.
  /usr/libexec/PlistBuddy \
    -c "Print :CFBundleIconName" \
    "$APP_DIR/Contents/Info.plist"
fi

# Sign the completed bundle.
codesign --force --deep --sign - "$APP_DIR"

echo
echo "App created: $APP_DIR"
echo "Architectures: $(lipo -archs "$APP_DIR/Contents/MacOS/$OUT_NAME")"
