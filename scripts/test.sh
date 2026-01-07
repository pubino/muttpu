#!/bin/bash
#
# test.sh - Run tests for MuttPU
#
# This script runs unit and integration tests
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
TESTS_DIR="$PROJECT_ROOT/tests"

echo "========================================"
echo "Running MuttPU Tests"
echo "========================================"
echo ""

# Check if tests directory exists
if [ ! -d "$TESTS_DIR" ]; then
    echo "Error: Tests directory not found at $TESTS_DIR"
    exit 1
fi

# Run Python script tests
echo "Running Python script tests..."
cd "$PROJECT_ROOT"

if [ -f "$TESTS_DIR/test_muttpu.py" ]; then
    python3 "$TESTS_DIR/test_muttpu.py"
    echo "✓ Python tests passed"
else
    echo "⚠ No Python tests found"
fi

echo ""

# Run integration tests
echo "Running integration tests..."
if [ -f "$TESTS_DIR/integration_test.sh" ]; then
    bash "$TESTS_DIR/integration_test.sh"
    echo "✓ Integration tests passed"
else
    echo "⚠ No integration tests found"
fi

echo ""
echo "========================================"
echo "✓ All tests passed!"
echo "========================================"
