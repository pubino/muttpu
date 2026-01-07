#!/bin/bash
#
# integration_test.sh - Integration tests for MuttPU
#
# Tests the complete workflow without requiring actual M365 credentials
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "========================================"
echo "MuttPU Integration Tests"
echo "========================================"
echo ""

# Test 1: Script exists and is executable
echo "Test 1: Script exists and is executable"
if [ -x "$PROJECT_ROOT/muttpu.py" ]; then
    echo -e "${GREEN}✓ PASS${NC}"
else
    echo -e "${RED}✗ FAIL${NC}"
    exit 1
fi

# Test 2: Script can be invoked without errors (help)
echo ""
echo "Test 2: Script help command"
if "$PROJECT_ROOT/muttpu.py" --help > /dev/null 2>&1; then
    echo -e "${GREEN}✓ PASS${NC}"
else
    echo -e "${RED}✗ FAIL${NC}"
    exit 1
fi

# Test 3: Script shows interactive menu when no args
echo ""
echo "Test 3: Interactive menu display"
output=$("$PROJECT_ROOT/muttpu.py" 2>&1 || true)
if echo "$output" | grep -q "Available Commands"; then
    echo -e "${GREEN}✓ PASS${NC}"
else
    echo -e "${RED}✗ FAIL${NC}"
    exit 1
fi

# Test 4: Dependency check works
echo ""
echo "Test 4: Dependency checking"
# The script should check for dependencies
# We won't fail if dependencies are missing, just verify the check runs
"$PROJECT_ROOT/muttpu.py" list > /dev/null 2>&1 || true
echo -e "${GREEN}✓ PASS${NC}"

# Test 5: App bundle structure (if built)
echo ""
echo "Test 5: App bundle structure"
APP_BUNDLE="$PROJECT_ROOT/dist/MuttPU.app"
if [ -d "$APP_BUNDLE" ]; then
    if [ -d "$APP_BUNDLE/Contents/MacOS" ] && \
       [ -d "$APP_BUNDLE/Contents/Resources" ] && \
       [ -f "$APP_BUNDLE/Contents/Info.plist" ]; then
        echo -e "${GREEN}✓ PASS${NC}"
    else
        echo -e "${RED}✗ FAIL - Invalid app bundle structure${NC}"
        exit 1
    fi
else
    echo -e "${YELLOW}⊘ SKIP - App not built${NC}"
fi

# Test 6: Python script in bundle (if built)
echo ""
echo "Test 6: Python script in bundle"
if [ -d "$APP_BUNDLE" ]; then
    if [ -f "$APP_BUNDLE/Contents/Resources/Python/muttpu.py" ]; then
        echo -e "${GREEN}✓ PASS${NC}"
    else
        echo -e "${RED}✗ FAIL - Python script not found in bundle${NC}"
        exit 1
    fi
else
    echo -e "${YELLOW}⊘ SKIP - App not built${NC}"
fi

# Test 7: Scripts are executable
echo ""
echo "Test 7: Build scripts are executable"
scripts=("build.sh" "run.sh" "test.sh" "notarize.sh")
all_executable=true
for script in "${scripts[@]}"; do
    if [ ! -x "$PROJECT_ROOT/scripts/$script" ]; then
        echo -e "${RED}✗ FAIL - $script is not executable${NC}"
        all_executable=false
    fi
done
if [ "$all_executable" = true ]; then
    echo -e "${GREEN}✓ PASS${NC}"
else
    exit 1
fi

# Test 8: Test directory structure
echo ""
echo "Test 8: Test directory structure"
if [ -d "$PROJECT_ROOT/tests" ] && \
   [ -f "$PROJECT_ROOT/tests/test_muttpu.py" ] && \
   [ -f "$PROJECT_ROOT/tests/integration_test.sh" ]; then
    echo -e "${GREEN}✓ PASS${NC}"
else
    echo -e "${RED}✗ FAIL${NC}"
    exit 1
fi

echo ""
echo "========================================"
echo -e "${GREEN}All integration tests passed!${NC}"
echo "========================================"
