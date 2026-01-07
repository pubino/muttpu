//
//  PythonBridgeTests.swift
//  MuttPU Tests
//
//  Tests for PythonBridge configuration
//

import XCTest
@testable import MuttPU

class PythonBridgeTests: XCTestCase {

    func testPythonPathUsesSystemPython() throws {
        // This test ensures we always use system Python3, not a bundled runtime
        // Regression test for: "Configuration error: The file python3 doesn't exist"

        let bridge = PythonBridge.shared
        let pythonPath = bridge.getPythonPath()

        // Should always use system Python
        XCTAssertEqual(pythonPath, "/usr/bin/python3",
                      "PythonBridge must use system Python3 at /usr/bin/python3")

        // Verify the Python binary exists
        let fileManager = FileManager.default
        XCTAssertTrue(fileManager.fileExists(atPath: pythonPath),
                     "System Python3 must exist at \(pythonPath)")
    }

    func testScriptPathInBundle() throws {
        // Test that script path points to bundled location when running from bundle
        let bridge = PythonBridge.shared
        let scriptPath = bridge.getScriptPath()

        if let resourcePath = Bundle.main.resourcePath {
            // When running from bundle, script should be in Resources/Python/
            let expectedPath = "\(resourcePath)/Python/muttpu.py"
            XCTAssertEqual(scriptPath, expectedPath,
                          "Script should be at \(expectedPath) when bundled")
        } else {
            // When not bundled (development), script should be in project root
            XCTAssertTrue(scriptPath.hasSuffix("muttpu.py"),
                         "Script path should end with muttpu.py")
        }
    }

    func testPythonPathDoesNotPointToBundledRuntime() throws {
        // Regression test: ensure we never look for Python/bin/python3 in bundle
        let bridge = PythonBridge.shared
        let pythonPath = bridge.getPythonPath()

        // Should NOT contain "Resources/Python/bin" or similar bundled path
        XCTAssertFalse(pythonPath.contains("Resources/Python/bin"),
                      "Python path must not point to non-existent bundled runtime")
        XCTAssertFalse(pythonPath.contains("/Python/bin/"),
                      "Python path must not point to non-existent bundled runtime")
    }
}
