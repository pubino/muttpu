//
//  SetupViewTests.swift
//  MuttPU Tests
//
//  Tests for SetupView functionality
//

import XCTest
import SwiftUI
@testable import MuttPU

class SetupViewTests: XCTestCase {

    func testToolbarRemainsVisibleDuringSetup() throws {
        // Regression test: toolbar (with Close button) must remain visible during setup
        // Previously, the toolbar would disappear when isRunningSetup became true

        // This test verifies that the toolbar item is NOT conditionally rendered
        // based on isRunningSetup state

        let setupViewSource = try readSetupViewSource()

        // Check that toolbar is NOT wrapped in "if !isRunningSetup"
        XCTAssertFalse(setupViewSource.contains(".toolbar {") &&
                      setupViewSource.contains("if !isRunningSetup") &&
                      setupViewSource.range(of: "if !isRunningSetup",
                                           range: setupViewSource.range(of: ".toolbar {")!.lowerBound..<setupViewSource.endIndex) != nil,
                      "Toolbar must not be conditionally shown based on isRunningSetup state")

        // The correct implementation: toolbar is always shown, button is disabled
        let toolbarPattern = #"\.toolbar\s*\{[^}]*ToolbarItem[^}]*Button.*\.disabled\(isRunningSetup\)"#
        XCTAssertTrue(setupViewSource.range(of: toolbarPattern, options: .regularExpression) != nil,
                     "Toolbar should always be visible with disabled button during setup")
    }

    func testCloseButtonDisabledDuringSetup() throws {
        // Test that Close button is properly disabled during setup, not hidden
        let setupViewSource = try readSetupViewSource()

        // Should have .disabled(isRunningSetup) on the Close button
        XCTAssertTrue(setupViewSource.contains(".disabled(isRunningSetup)"),
                     "Close button must be disabled during setup")
    }

    func testSetupButtonDisabledDuringSetup() throws {
        // Test that Start Setup button is disabled when setup is running
        let setupViewSource = try readSetupViewSource()

        // Should have multiple .disabled(isRunningSetup) for different buttons
        let disabledCount = setupViewSource.components(separatedBy: ".disabled(isRunningSetup)").count - 1
        XCTAssertGreaterThanOrEqual(disabledCount, 2,
                                   "Multiple buttons should be disabled during setup")
    }

    // MARK: - Helper Methods

    private func readSetupViewSource() throws -> String {
        let sourceFile = URL(fileURLWithPath: #file)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("MuttPU.app")
            .appendingPathComponent("Sources")
            .appendingPathComponent("Views")
            .appendingPathComponent("SetupView.swift")

        return try String(contentsOf: sourceFile, encoding: .utf8)
    }
}
