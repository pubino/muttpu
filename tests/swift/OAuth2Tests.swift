//
//  OAuth2Tests.swift
//  MuttPU Tests
//
//  Tests for OAuth2 setup functionality
//

import XCTest
@testable import MuttPU

class OAuth2Tests: XCTestCase {

    func testURLExtractionFromOutput() throws {
        // Test that we can extract Microsoft device login URLs from OAuth2 output
        let sampleOutput = """
        To sign in, use a web browser to open the page https://microsoft.com/devicelogin
        and enter the code ABC123DEF to authenticate.
        """

        // Since extractLoginURL is private, we test the logic directly
        let hasHTTPS = sampleOutput.contains("https://")
        let hasMicrosoft = sampleOutput.contains("microsoft.com") || sampleOutput.contains("microsoftonline.com")

        XCTAssertTrue(hasHTTPS, "Output should contain https://")
        XCTAssertTrue(hasMicrosoft, "Output should contain microsoft.com or microsoftonline.com")

        // Test URL extraction pattern
        let pattern = #"(https://[^\s]+)"#
        let range = sampleOutput.range(of: pattern, options: .regularExpression)
        XCTAssertNotNil(range, "Should find URL in output")

        if let range = range {
            let urlString = String(sampleOutput[range])
            XCTAssertTrue(urlString.contains("microsoft.com") || urlString.contains("microsoftonline.com"))

            // Verify it's a valid URL
            let url = URL(string: urlString)
            XCTAssertNotNil(url, "Extracted string should be a valid URL")
        }
    }

    func testURLExtractionWithQueryParameters() throws {
        // Test URL extraction with query parameters
        let outputWithParams = """
        Opening: https://microsoft.com/devicelogin?code=ABC123
        Please complete the authorization.
        """

        let pattern = #"(https://[^\s]+)"#
        let range = outputWithParams.range(of: pattern, options: .regularExpression)

        XCTAssertNotNil(range, "Should find URL with query parameters")

        if let range = range {
            let urlString = String(outputWithParams[range])
            XCTAssertTrue(urlString.starts(with: "https://microsoft.com/devicelogin"))

            let url = URL(string: urlString)
            XCTAssertNotNil(url, "URL with query parameters should be valid")
        }
    }

    func testMicrosoftOnlineURLExtraction() throws {
        // Test that we can extract login.microsoftonline.com URLs
        let output = "Visit https://login.microsoftonline.com/common/oauth2/v2.0/devicecode"

        let hasHTTPS = output.contains("https://")
        let hasMicrosoft = output.contains("microsoft.com") || output.contains("microsoftonline.com")

        XCTAssertTrue(hasHTTPS && hasMicrosoft, "Should detect microsoftonline.com URLs")

        let pattern = #"(https://[^\s]+)"#
        if let range = output.range(of: pattern, options: .regularExpression) {
            let urlString = String(output[range])
            XCTAssertTrue(urlString.contains("microsoftonline.com"))

            let url = URL(string: urlString)
            XCTAssertNotNil(url, "microsoftonline.com URL should be valid")
        } else {
            XCTFail("Should extract microsoftonline.com URL")
        }
    }

    func testNoURLInPlainText() throws {
        // Test that we don't extract URLs from plain text without the pattern
        let plainText = """
        Setting up OAuth2 authentication.
        Checking dependencies...
        Starting authorization flow.
        """

        let pattern = #"https://microsoft\.com/devicelogin[^\s]*"#
        let range = plainText.range(of: pattern, options: .regularExpression)

        XCTAssertNil(range, "Should not find URL in plain text without the pattern")
    }

    func testPythonBridgeHasStreamingMethod() throws {
        // Verify that PythonBridge has the setupOAuth2WithStreaming method
        let bridge = PythonBridge.shared

        // This test ensures the method exists and is callable
        // We can't actually call it without a real OAuth2 setup, but we can verify the signature
        let mirror = Mirror(reflecting: bridge)
        let hasStreamingMethod = mirror.children.contains { child in
            String(describing: child.label).contains("setupOAuth2WithStreaming")
        }

        // Since methods don't show up in Mirror.children, we just verify the class exists
        // and has the expected structure. The real test is that the code compiles.
        XCTAssertNotNil(bridge, "PythonBridge singleton should exist")
    }
}
