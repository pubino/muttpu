#!/bin/bash
#
# run.sh - Run the MuttPU app
#
# This script launches the built MuttPU.app
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
APP_BUNDLE="$PROJECT_ROOT/dist/MuttPU.app"

if [ ! -d "$APP_BUNDLE" ]; then
    echo "Error: App bundle not found at $APP_BUNDLE"
    echo ""
    echo "Please build the app first:"
    echo "  ./scripts/build.sh"
    echo ""
    exit 1
fi

echo "Launching MuttPU..."
open "$APP_BUNDLE"
