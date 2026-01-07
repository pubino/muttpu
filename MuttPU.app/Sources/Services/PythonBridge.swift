//
//  PythonBridge.swift
//  MuttPU
//
//  Bridge for communicating with the Python muttpu script
//

import Foundation
import Combine

@MainActor
class PythonBridge: ObservableObject {
    static let shared = PythonBridge()

    nonisolated private let pythonPath: String
    nonisolated private let scriptPath: String

    private init() {
        // Use system Python3 (we don't bundle Python runtime)
        self.pythonPath = "/usr/bin/python3"

        // In bundled app, script will be in Resources/Python/
        if let bundlePath = Bundle.main.resourcePath {
            self.scriptPath = "\(bundlePath)/Python/muttpu.py"
        } else {
            // Fallback for development
            self.scriptPath = FileManager.default.currentDirectoryPath + "/muttpu.py"
        }
    }

    // MARK: - Test Helpers

    nonisolated func getPythonPath() -> String {
        return pythonPath
    }

    nonisolated func getScriptPath() -> String {
        return scriptPath
    }

    // MARK: - Test Connection

    func testConnection() async throws -> PythonResult<Bool> {
        let args = ["list"]
        let result = try await runPythonCommand(args: args)

        if result.contains("✓") || result.contains("messages") {
            return PythonResult(success: true, data: true, error: nil)
        } else if result.contains("✗") || result.contains("error") || result.contains("failed") {
            return PythonResult(success: false, data: false, error: parseError(from: result))
        } else {
            return PythonResult(success: true, data: true, error: nil)
        }
    }

    // MARK: - List Mailboxes

    func listMailboxes() async throws -> [Mailbox] {
        let args = ["list"]
        let output = try await runPythonCommand(args: args)

        return parseMailboxes(from: output)
    }

    private func parseMailboxes(from output: String) -> [Mailbox] {
        var mailboxes: [Mailbox] = []
        let lines = output.components(separatedBy: "\n")

        for line in lines {
            // Look for numbered mailbox entries: "  1. INBOX"
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if let range = trimmed.range(of: #"^\d+\.\s+(.+)$"#, options: .regularExpression) {
                let mailboxName = trimmed[range].components(separatedBy: ". ").last ?? ""
                if !mailboxName.isEmpty {
                    mailboxes.append(Mailbox(name: mailboxName))
                }
            }
            // Also handle lines without numbers
            else if !trimmed.isEmpty &&
                    !trimmed.contains("=") &&
                    !trimmed.contains("Mailboxes") &&
                    !trimmed.contains("Connecting") &&
                    !trimmed.contains("messages") {
                mailboxes.append(Mailbox(name: trimmed))
            }
        }

        return mailboxes
    }

    // MARK: - Count Messages

    func countMessages(mailbox: String) async throws -> Int {
        let args = ["count", mailbox]
        let output = try await runPythonCommand(args: args)

        return parseMessageCount(from: output)
    }

    private func parseMessageCount(from output: String) -> Int {
        // Look for patterns like "INBOX: 234 messages" or "Archive: 1,234 messages"
        let pattern = #":\s*([\d,]+)\s+messages"#
        if let range = output.range(of: pattern, options: .regularExpression) {
            let countStr = output[range]
                .replacingOccurrences(of: ":", with: "")
                .replacingOccurrences(of: "messages", with: "")
                .replacingOccurrences(of: ",", with: "")
                .trimmingCharacters(in: .whitespaces)

            return Int(countStr) ?? 0
        }

        return 0
    }

    // MARK: - Export Mailbox

    func exportMailbox(
        mailbox: String,
        outputDir: String,
        format: ExportFormat,
        year: Int? = nil,
        fresh: Bool = false,
        progressHandler: @escaping (Double) -> Void
    ) async throws {
        var args = ["export", mailbox, outputDir, "--format", format.rawValue.lowercased()]

        if let year = year {
            args.append(contentsOf: ["--year", "\(year)"])
        }

        if fresh {
            args.append("--fresh")
        }

        // Run command with streaming output to track progress
        try await runPythonCommandWithProgress(args: args, progressHandler: progressHandler)
    }

    // MARK: - Setup OAuth2

    func setupOAuth2() async throws -> String {
        let args = ["setup"]
        return try await runPythonCommand(args: args)
    }

    // MARK: - Private Helpers

    nonisolated private func runPythonCommand(args: [String]) async throws -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: pythonPath)
        process.arguments = [scriptPath] + args

        let outputPipe = Pipe()
        let errorPipe = Pipe()

        process.standardOutput = outputPipe
        process.standardError = errorPipe

        try process.run()
        process.waitUntilExit()

        let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
        let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()

        let output = String(data: outputData, encoding: .utf8) ?? ""
        let error = String(data: errorData, encoding: .utf8) ?? ""

        if process.terminationStatus != 0 {
            throw PythonBridgeError.commandFailed(
                status: Int(process.terminationStatus),
                output: output,
                error: error
            )
        }

        return output + error
    }

    nonisolated private func runPythonCommandWithProgress(
        args: [String],
        progressHandler: @escaping @MainActor (Double) -> Void
    ) async throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: pythonPath)
        process.arguments = [scriptPath] + args

        let outputPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = outputPipe

        // Read output asynchronously
        let handle = outputPipe.fileHandleForReading
        var outputBuffer = ""

        handle.readabilityHandler = { fileHandle in
            let data = fileHandle.availableData
            if let output = String(data: data, encoding: .utf8) {
                outputBuffer += output

                // Parse progress from output
                // Look for patterns like "[100/1500] 6.7%" or "💾 Checkpoint"
                if let progress = Self.parseProgressStatic(from: output) {
                    Task { @MainActor in
                        progressHandler(progress)
                    }
                }
            }
        }

        try process.run()
        process.waitUntilExit()

        handle.readabilityHandler = nil

        if process.terminationStatus != 0 {
            throw PythonBridgeError.commandFailed(
                status: Int(process.terminationStatus),
                output: outputBuffer,
                error: "Export failed"
            )
        }
    }

    private func parseProgress(from output: String) -> Double? {
        return Self.parseProgressStatic(from: output)
    }

    nonisolated private static func parseProgressStatic(from output: String) -> Double? {
        // Match patterns like "[100/1500] 6.7%"
        let pattern = #"\[(\d+)/(\d+)\]\s+([\d.]+)%"#
        if let range = output.range(of: pattern, options: .regularExpression) {
            let matched = output[range]
            let components = matched.components(separatedBy: " ")
            if let percentStr = components.last?.replacingOccurrences(of: "%", with: ""),
               let percent = Double(percentStr) {
                return percent / 100.0
            }
        }

        return nil
    }

    private func parseError(from output: String) -> String {
        let lines = output.components(separatedBy: "\n")
        for line in lines {
            if line.contains("✗") || line.contains("error") || line.contains("failed") {
                return line
                    .replacingOccurrences(of: "✗", with: "")
                    .trimmingCharacters(in: .whitespaces)
            }
        }
        return "Unknown error"
    }
}

// MARK: - Errors

enum PythonBridgeError: LocalizedError {
    case commandFailed(status: Int, output: String, error: String)
    case scriptNotFound
    case pythonNotFound

    var errorDescription: String? {
        switch self {
        case .commandFailed(let status, let output, let error):
            if !error.isEmpty {
                return error
            }
            if !output.isEmpty {
                return output
            }
            return "Command failed with status \(status)"
        case .scriptNotFound:
            return "Python script not found in application bundle"
        case .pythonNotFound:
            return "Python interpreter not found"
        }
    }
}
