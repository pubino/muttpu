#!/bin/bash
#
# notarize.sh - Notarize MuttPU.app for distribution
#
# This script:
# 1. Signs the application with your Developer ID
# 2. Creates a DMG for distribution
# 3. Notarizes the DMG with Apple
# 4. Staples the notarization ticket
#
# Prerequisites:
# - Xcode and command line tools installed
# - Valid Apple Developer ID certificate
# - App-specific password for notarization
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
APP_BUNDLE="$PROJECT_ROOT/dist/MuttPU.app"
DMG_NAME="MuttPU-1.0.0.dmg"
DMG_PATH="$PROJECT_ROOT/dist/$DMG_NAME"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "========================================"
echo "Notarizing MuttPU"
echo "========================================"
echo ""

# Check if app bundle exists
if [ ! -d "$APP_BUNDLE" ]; then
    echo -e "${RED}Error: App bundle not found at $APP_BUNDLE${NC}"
    echo ""
    echo "Please build the app first:"
    echo "  ./scripts/build.sh"
    echo ""
    exit 1
fi

# Step 1: Check for signing certificate
echo "Step 1: Checking for signing certificate..."
CERT_NAME=$(security find-identity -v -p codesigning | grep "Developer ID Application" | head -1 | sed 's/.*"\(.*\)".*/\1/' || echo "")

if [ -z "$CERT_NAME" ]; then
    echo -e "${YELLOW}⚠ No Developer ID certificate found${NC}"
    echo ""
    echo "To notarize, you need:"
    echo "  1. An Apple Developer account"
    echo "  2. A Developer ID Application certificate"
    echo ""
    echo "Skipping signing and notarization..."
    echo ""
    echo "The app will still work but won't be notarized for distribution."
    exit 0
fi

echo -e "${GREEN}✓ Found certificate: $CERT_NAME${NC}"

# Step 2: Sign the application
echo ""
echo "Step 2: Signing application..."

codesign --deep --force --verify --verbose \
    --sign "$CERT_NAME" \
    --options runtime \
    "$APP_BUNDLE"

echo -e "${GREEN}✓ Application signed${NC}"

# Step 3: Verify signature
echo ""
echo "Step 3: Verifying signature..."
codesign --verify --deep --strict --verbose=2 "$APP_BUNDLE"
echo -e "${GREEN}✓ Signature verified${NC}"

# Step 4: Create DMG
echo ""
echo "Step 4: Creating DMG..."

# Remove old DMG if exists
rm -f "$DMG_PATH"

# Create DMG
hdiutil create -volname "MuttPU" -srcfolder "$APP_BUNDLE" -ov -format UDZO "$DMG_PATH"

echo -e "${GREEN}✓ DMG created: $DMG_PATH${NC}"

# Step 5: Notarize
echo ""
echo "Step 5: Notarizing with Apple..."
echo ""
echo -e "${YELLOW}Note: You need to set up notarization credentials:${NC}"
echo "  1. Create an app-specific password at appleid.apple.com"
echo "  2. Store credentials in keychain:"
echo "     xcrun notarytool store-credentials \"notarytool-profile\" \\"
echo "       --apple-id \"your@email.com\" \\"
echo "       --team-id \"YOUR_TEAM_ID\" \\"
echo "       --password \"app-specific-password\""
echo ""

read -p "Have you set up notarization credentials? (y/N) " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo ""
    echo "Skipping notarization. The signed app is ready at:"
    echo "  $APP_BUNDLE"
    echo ""
    exit 0
fi

# Submit for notarization
echo "Submitting to Apple for notarization..."
xcrun notarytool submit "$DMG_PATH" \
    --keychain-profile "notarytool-profile" \
    --wait

echo -e "${GREEN}✓ Notarization complete${NC}"

# Step 6: Staple notarization ticket
echo ""
echo "Step 6: Stapling notarization ticket..."
xcrun stapler staple "$DMG_PATH"
echo -e "${GREEN}✓ Ticket stapled${NC}"

# Step 7: Verify notarization
echo ""
echo "Step 7: Verifying notarization..."
spctl -a -t open --context context:primary-signature -v "$DMG_PATH"
echo -e "${GREEN}✓ Notarization verified${NC}"

echo ""
echo "========================================"
echo -e "${GREEN}✓ Notarization complete!${NC}"
echo "========================================"
echo ""
echo "Distribution file: $DMG_PATH"
echo ""
echo "This DMG is:"
echo "  ✓ Signed with Developer ID"
echo "  ✓ Notarized by Apple"
echo "  ✓ Ready for distribution"
echo ""
