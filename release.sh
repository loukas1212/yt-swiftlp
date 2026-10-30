#!/bin/bash
# Usage:
# ./release.sh [-v version] [-a arm64|x86_64|universal] \
#   [-n output_name] [-p product] [-i bundle_id] [-I icon.icon]
#
# Icon precompile (run locally with the newest Xcode, then commit the result):
# ./release.sh -C [-I icon.icon]

set -Eeuo pipefail
cd "$(dirname "$0")"

VERSION=""
ARCH=""
OUT_NAME="YT-SwiftLP"
PRODUCT="YT-SwiftLP"
BUNDLE_ID=""
ICON="appicon.icon"
PRECOMPILE_ONLY=0

# Precompiled icon output (committed to git, used on CI).
ICON_OUT_DIR="Resources/icon-out"

SU_FEED_URL="${SU_FEED_URL:-}"
SU_PUBLIC_KEY="${SU_PUBLIC_KEY:-}"
BUILD_NUMBER="${BUILD_NUMBER:-1}"

usage() {
  echo "Usage: $0 [-v version] [-a arm64|x86_64|universal] [-n output_name] [-p product] [-i bundle_id] [-I icon.icon] [-C]"
  echo "  -C  Compile the .icon into $ICON_OUT_DIR and exit (run locally, then commit)"
}

while getopts "v:a:n:p:i:I:Ch" opt; do
  case "$opt" in
    v) VERSION="$OPTARG" ;;
    a) ARCH="$OPTARG" ;;
    n) OUT_NAME="$OPTARG" ;;
    p) PRODUCT="$OPTARG" ;;
    i) BUNDLE_ID="$OPTARG" ;;
    I) ICON="$OPTARG" ;;
    C) PRECOMPILE_ONLY=1 ;;
    h) usage; exit 0 ;;
    *) usage >&2; exit 2 ;;
  esac
done

# Run actool on an .icon package: compile_icon <icon-path> <dest-dir> <partial-plist>
compile_icon() {
  local icon="$1" dest="$2" partial="$3"
  local name
  name="$(basename "$icon" .icon)"

  mkdir -p "$dest"
  xcrun actool "$icon" \
    --compile "$dest" \
    --output-format xml1 \
    --notices \
    --warnings \
    --errors \
    --output-partial-info-plist "$partial" \
    --app-icon "$name" \
    --include-all-app-icons \
    --enable-on-demand-resources NO \
    --development-region en \
    --target-device mac \
    --minimum-deployment-target 13.0 \
    --platform macosx
}

# Resolve and validate an Icon Composer package (sets ICON to an absolute path).
resolve_icon() {
  if [[ "$ICON" != *.icon ]] || [ ! -d "$ICON" ]; then
    echo "Icon must be an existing .icon package: $ICON" >&2
    exit 1
  fi
  ICON="$(cd "$(dirname "$ICON")" && pwd)/$(basename "$ICON")"
}

# Precompile mode: build the icon once locally and exit.
if [ "$PRECOMPILE_ONLY" -eq 1 ]; then
  resolve_icon
  if ! xcrun --find actool >/dev/null 2>&1; then
    echo "actool not found. Check your Xcode installation." >&2
    exit 1
  fi

  ICON_NAME="$(basename "$ICON" .icon)"
  rm -rf "$ICON_OUT_DIR"
  TMP_PLIST="$(mktemp)"
  echo "Precompiling icon: $ICON_NAME -> $ICON_OUT_DIR"
  compile_icon "$ICON" "$ICON_OUT_DIR" "$TMP_PLIST"
  rm -f "$TMP_PLIST"

  if [ ! -f "$ICON_OUT_DIR/Assets.car" ]; then
    echo "Error: actool did not generate Assets.car." >&2
    exit 1
  fi

  echo "Done. Commit these files:"
  ls -lh "$ICON_OUT_DIR"
  exit 0
fi

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

# Decide how the icon will be provided:
#   precompiled -> use $ICON_OUT_DIR (Assets.car + .icns), no actool needed
#   actool      -> compile the .icon package during this build
#   none        -> no icon
ICON_MODE="none"
if [ -f "$ICON_OUT_DIR/Assets.car" ]; then
  ICON_MODE="precompiled"
  ICON_NAME="$(basename "${ICON:-appicon.icon}" .icon)"
elif [ -n "$ICON" ]; then
  resolve_icon
  if ! xcrun --find actool >/dev/null 2>&1; then
    echo "actool not found. Check your Xcode installation." >&2
    exit 1
  fi
  ICON_MODE="actool"
  ICON_NAME="$(basename "$ICON" .icon)"
fi

APP_DIR="$OUT_NAME.app"

echo "Product:      $PRODUCT"
echo "App:          $APP_DIR"
echo "Version:      $VERSION (build $BUILD_NUMBER)"
echo "Architecture: $ARCH"
echo "Bundle ID:    $BUNDLE_ID"
echo "Icon:         $ICON_MODE${ICON:+ ($ICON)}"
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

# Set a string key in Info.plist (add it if missing).
plist_set() {
  local key="$1" value="$2" plist="$APP_DIR/Contents/Info.plist"
  /usr/libexec/PlistBuddy -c "Set :$key $value" "$plist" 2>/dev/null ||
    /usr/libexec/PlistBuddy -c "Add :$key string $value" "$plist"
}

# Install the app icon.
case "$ICON_MODE" in
  precompiled)
    echo "Using precompiled icon from $ICON_OUT_DIR"
    cp "$ICON_OUT_DIR/Assets.car" "$APP_DIR/Contents/Resources/"
    if [ -f "$ICON_OUT_DIR/$ICON_NAME.icns" ]; then
      cp "$ICON_OUT_DIR/$ICON_NAME.icns" "$APP_DIR/Contents/Resources/"
      plist_set CFBundleIconFile "$ICON_NAME"
    fi
    plist_set CFBundleIconName "$ICON_NAME"
    ;;

  actool)
    TEMP_DIR="$(mktemp -d)"
    trap 'rm -rf "$TEMP_DIR"' EXIT
    PARTIAL_PLIST="$TEMP_DIR/partial.plist"

    echo "Compiling Icon Composer icon: $ICON_NAME"
    compile_icon "$ICON" "$APP_DIR/Contents/Resources" "$PARTIAL_PLIST"

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
    ;;
esac

if [ "$ICON_MODE" != "none" ]; then
  echo "Icon resources:"
  ls -lh "$APP_DIR/Contents/Resources/"
  echo -n "CFBundleIconName: "
  /usr/libexec/PlistBuddy -c "Print :CFBundleIconName" "$APP_DIR/Contents/Info.plist"
fi

# Sign the completed bundle.
codesign --force --deep --sign - "$APP_DIR"

echo
echo "App created: $APP_DIR"
echo "Architectures: $(lipo -archs "$APP_DIR/Contents/MacOS/$OUT_NAME")"