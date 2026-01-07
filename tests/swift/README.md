# Swift Tests

This directory contains Swift unit tests for the MuttPU macOS app.

## Test Files

- `PythonBridgeTests.swift` - Tests for Python bridge configuration
- `SetupViewTests.swift` - Tests for OAuth setup UI behavior

## Purpose

These are **regression prevention tests** that validate code structure and configuration to prevent known bugs from reoccurring.

## Test Coverage

### PythonBridgeTests
Prevents the regression: "Configuration error: The file python3 doesn't exist"

- `testPythonPathUsesSystemPython()` - Ensures `/usr/bin/python3` is used
- `testScriptPathInBundle()` - Validates bundled script location
- `testPythonPathDoesNotPointToBundledRuntime()` - Prevents looking for non-existent bundled Python

### SetupViewTests
Prevents the regression: "Close button disappears when Start Setup is clicked"

- `testToolbarRemainsVisibleDuringSetup()` - Ensures toolbar is always visible
- `testCloseButtonDisabledDuringSetup()` - Validates button is disabled, not hidden
- `testSetupButtonDisabledDuringSetup()` - Ensures proper button state management

## Running Tests

These tests require XCTest infrastructure and are currently source-level validation tests. They validate the structure of the code to prevent regressions.

To run manually:
```bash
# Build and run with XCTest (requires Xcode)
swift test
```

## Adding New Tests

When fixing a bug:
1. Create a test that would have caught the bug
2. Verify the test fails with the buggy code
3. Fix the bug
4. Verify the test passes
5. Commit both the fix and the test

Example:
```swift
func testMyNewFeature() throws {
    // Arrange
    let expectedValue = "expected"

    // Act
    let actualValue = myFunction()

    // Assert
    XCTAssertEqual(actualValue, expectedValue)
}
```

## Notes

- Tests are designed to be fast and require no external dependencies
- Tests validate code structure, not runtime behavior
- Integration tests for runtime behavior are in `../integration_test.sh`
