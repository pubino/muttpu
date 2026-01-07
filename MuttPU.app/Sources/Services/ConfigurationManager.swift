//
//  ConfigurationManager.swift
//  MuttPU
//
//  Manages OAuth2 configuration and token files
//

import Foundation

class ConfigurationManager {
    static let shared = ConfigurationManager()

    private let tokenFileName = "token.gpg"
    private let configDirName = "muttpu"

    private init() {}

    // MARK: - Token Management

    var tokenPath: String {
        let homeDir = FileManager.default.homeDirectoryForCurrentUser
        return homeDir.appendingPathComponent("Downloads/\(configDirName)/\(tokenFileName)").path
    }

    func checkTokenExists() -> Bool {
        return FileManager.default.fileExists(atPath: tokenPath)
    }

    func deleteToken() {
        try? FileManager.default.removeItem(atPath: tokenPath)
    }

    func getTokenDirectory() -> String {
        let homeDir = FileManager.default.homeDirectoryForCurrentUser
        return homeDir.appendingPathComponent("Downloads/\(configDirName)").path
    }

    func ensureConfigDirectory() throws {
        let configDir = getTokenDirectory()
        if !FileManager.default.fileExists(atPath: configDir) {
            try FileManager.default.createDirectory(
                atPath: configDir,
                withIntermediateDirectories: true
            )
        }
    }

    // MARK: - Settings Persistence

    private var settingsPath: String {
        let homeDir = FileManager.default.homeDirectoryForCurrentUser
        return homeDir.appendingPathComponent("Downloads/\(configDirName)/settings.json").path
    }

    func saveSettings(_ settings: AppSettings) throws {
        try ensureConfigDirectory()
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let data = try encoder.encode(settings)
        try data.write(to: URL(fileURLWithPath: settingsPath))
    }

    func loadSettings() -> AppSettings? {
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: settingsPath)) else {
            return nil
        }

        let decoder = JSONDecoder()
        return try? decoder.decode(AppSettings.self, from: data)
    }

    // MARK: - Dependencies Check

    func checkDependencies() -> [String] {
        var missing: [String] = []

        // Check for GPG
        if !isCommandAvailable("gpg") {
            missing.append("gpg")
        }

        // Check for NeoMutt (needed for OAuth2 script)
        if !isCommandAvailable("neomutt") {
            missing.append("neomutt")
        }

        return missing
    }

    private func isCommandAvailable(_ command: String) -> Bool {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/which")
        process.arguments = [command]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        do {
            try process.run()
            process.waitUntilExit()
            return process.terminationStatus == 0
        } catch {
            return false
        }
    }

    // MARK: - Configuration Validation

    func validateConfiguration() -> ConfigurationStatus {
        // Check token exists
        guard checkTokenExists() else {
            return .notConfigured
        }

        // Check dependencies
        let missingDeps = checkDependencies()
        if !missingDeps.isEmpty {
            return .missingDependencies(missingDeps)
        }

        // Token exists and dependencies are present
        return .configured
    }

    enum ConfigurationStatus {
        case configured
        case notConfigured
        case missingDependencies([String])

        var isReady: Bool {
            if case .configured = self {
                return true
            }
            return false
        }
    }
}
