#!/bin/bash
#
# build.sh - Build MuttPU.app with embedded Python
#
# This script:
# 1. Compiles the SwiftUI application
# 2. Bundles Python and dependencies
# 3. Creates a standalone .app bundle
#

set -e  # Exit on error

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
APP_NAME="MuttPU"
BUILD_DIR="$PROJECT_ROOT/build"
DIST_DIR="$PROJECT_ROOT/dist"
APP_BUNDLE="$DIST_DIR/$APP_NAME.app"

echo "========================================"
echo "Building $APP_NAME"
echo "========================================"
echo ""

# Clean previous builds
echo "Cleaning previous builds..."
rm -rf "$BUILD_DIR" "$DIST_DIR"
mkdir -p "$BUILD_DIR" "$DIST_DIR"

# Step 1: Build Swift application
echo ""
echo "Step 1: Building Swift application..."
cd "$PROJECT_ROOT"

swiftc \
    -o "$BUILD_DIR/$APP_NAME" \
    -framework SwiftUI \
    -framework Foundation \
    -framework AppKit \
    "$PROJECT_ROOT/MuttPU.app/Sources/MuttPUApp.swift" \
    "$PROJECT_ROOT/MuttPU.app/Sources/Models/AppState.swift" \
    "$PROJECT_ROOT/MuttPU.app/Sources/Models/Models.swift" \
    "$PROJECT_ROOT/MuttPU.app/Sources/Services/PythonBridge.swift" \
    "$PROJECT_ROOT/MuttPU.app/Sources/Services/ConfigurationManager.swift" \
    "$PROJECT_ROOT/MuttPU.app/Sources/Views/ContentView.swift" \
    "$PROJECT_ROOT/MuttPU.app/Sources/Views/MailboxDetailView.swift" \
    "$PROJECT_ROOT/MuttPU.app/Sources/Views/ExportView.swift" \
    "$PROJECT_ROOT/MuttPU.app/Sources/Views/SetupView.swift" \
    "$PROJECT_ROOT/MuttPU.app/Sources/Views/SettingsView.swift" \
    "$PROJECT_ROOT/MuttPU.app/Sources/Views/QueueView.swift" \
    "$PROJECT_ROOT/MuttPU.app/Sources/Views/LogView.swift"

echo "✓ Swift compilation complete"

# Step 2: Create app bundle structure
echo ""
echo "Step 2: Creating app bundle structure..."
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources/Python"
mkdir -p "$APP_BUNDLE/Contents/Frameworks"

# Copy executable
cp "$BUILD_DIR/$APP_NAME" "$APP_BUNDLE/Contents/MacOS/$APP_NAME"
chmod +x "$APP_BUNDLE/Contents/MacOS/$APP_NAME"

# Copy app icon if it exists
if [ -f "$PROJECT_ROOT/MuttPU.app/Resources/AppIcon.icns" ]; then
    cp "$PROJECT_ROOT/MuttPU.app/Resources/AppIcon.icns" "$APP_BUNDLE/Contents/Resources/AppIcon.icns"
    echo "✓ App icon bundled"
fi

echo "✓ App bundle structure created"

# Step 3: Bundle Python
echo ""
echo "Step 3: Bundling Python..."

# Check if python3 is available
if ! command -v python3 &> /dev/null; then
    echo "Error: python3 not found"
    exit 1
fi

PYTHON_VERSION=$(python3 -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")')
echo "Using Python $PYTHON_VERSION"

# Create a minimal Python environment
# Note: For a truly standalone app, we would use py2app or create a relocatable Python
# For now, we'll copy the Python scripts and assume system Python is available

cp "$PROJECT_ROOT/muttpu.py" "$APP_BUNDLE/Contents/Resources/Python/muttpu.py"
chmod +x "$APP_BUNDLE/Contents/Resources/Python/muttpu.py"

# Copy mutt_oauth2.py if it exists
if [ -f "$PROJECT_ROOT/mutt_oauth2.py" ]; then
    cp "$PROJECT_ROOT/mutt_oauth2.py" "$APP_BUNDLE/Contents/Resources/Python/mutt_oauth2.py"
    chmod +x "$APP_BUNDLE/Contents/Resources/Python/mutt_oauth2.py"
    echo "✓ Python scripts bundled (including mutt_oauth2.py)"
else
    echo "⚠ mutt_oauth2.py not found - will rely on system NeoMutt installation"
    echo "✓ Python script bundled"
fi

# Step 4: Create Info.plist
echo ""
echo "Step 4: Creating Info.plist..."

cat > "$APP_BUNDLE/Contents/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>$APP_NAME</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleIdentifier</key>
    <string>com.muttpu.app</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>$APP_NAME</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
    <key>NSHumanReadableCopyright</key>
    <string>Copyright © 2026 MuttPU. All rights reserved.</string>
</dict>
</plist>
EOF

echo "✓ Info.plist created"

# Step 5: Create PkgInfo
echo ""
echo "Step 5: Creating PkgInfo..."
echo -n "APPL????" > "$APP_BUNDLE/Contents/PkgInfo"
echo "✓ PkgInfo created"

# Step 6: Set permissions
echo ""
echo "Step 6: Setting permissions..."
chmod -R 755 "$APP_BUNDLE"
echo "✓ Permissions set"

echo ""
echo "========================================"
echo "✓ Build complete!"
echo "========================================"
echo ""
echo "Application bundle: $APP_BUNDLE"
echo ""
echo "Next steps:"
echo "  1. Test the app: ./scripts/run.sh"
echo "  2. Run tests: ./scripts/test.sh"
echo "  3. Notarize: ./scripts/notarize.sh"
echo ""
