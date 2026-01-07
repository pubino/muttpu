//
//  AppState.swift
//  MuttPU
//
//  Main application state management
//

import Foundation
import SwiftUI

@MainActor
class AppState: ObservableObject {
    @Published var isConfigured: Bool = false
    @Published var hasConfigurationError: Bool = false
    @Published var configurationErrorMessage: String = ""
    @Published var mailboxes: [Mailbox] = []
    @Published var isLoadingMailboxes: Bool = false
    @Published var exportQueue: [ExportJob] = []
    @Published var logEntries: [LogEntry] = []
    @Published var settings: AppSettings = AppSettings() {
        didSet {
            // Restart auto-refresh timer when settings change
            restartAutoRefreshTimer()
        }
    }

    private let pythonBridge = PythonBridge.shared
    private let configManager = ConfigurationManager.shared
    private var autoRefreshTask: Task<Void, Never>?

    init() {
        // Load saved settings on initialization
        if let savedSettings = configManager.loadSettings() {
            self.settings = savedSettings
        }

        // Start auto-refresh timer if enabled
        startAutoRefreshTimer()
    }

    deinit {
        autoRefreshTask?.cancel()
    }

    func checkConfiguration() async {
        // Check if OAuth2 token exists
        let tokenExists = configManager.checkTokenExists()

        if !tokenExists {
            isConfigured = false
            return
        }

        // Verify token is valid by testing connection
        do {
            let result = try await pythonBridge.testConnection()
            if result.success {
                isConfigured = true
                hasConfigurationError = false
                addLog(type: .info, message: "Configuration validated successfully")
            } else {
                isConfigured = false
                hasConfigurationError = true
                configurationErrorMessage = result.error ?? "Unknown authentication error"
                addLog(type: .error, message: "Configuration error: \(configurationErrorMessage)")
            }
        } catch {
            isConfigured = false
            hasConfigurationError = true
            configurationErrorMessage = error.localizedDescription
            addLog(type: .error, message: "Configuration check failed: \(error.localizedDescription)")
        }
    }

    func refreshMailboxes() async {
        guard isConfigured else { return }

        isLoadingMailboxes = true
        addLog(type: .info, message: "Refreshing mailboxes...")

        do {
            let result = try await pythonBridge.listMailboxes()
            mailboxes = result

            // Get message counts for each mailbox
            for i in 0..<mailboxes.count {
                if let count = try? await pythonBridge.countMessages(mailbox: mailboxes[i].name) {
                    mailboxes[i].messageCount = count
                }
            }

            isLoadingMailboxes = false
            addLog(type: .success, message: "Loaded \(mailboxes.count) mailboxes")
        } catch {
            isLoadingMailboxes = false
            addLog(type: .error, message: "Failed to refresh mailboxes: \(error.localizedDescription)")
        }
    }

    func exportMailbox(_ mailbox: Mailbox, options: ExportOptions) {
        let job = ExportJob(
            id: UUID(),
            mailbox: mailbox,
            options: options,
            status: .queued,
            progress: 0.0,
            createdAt: Date()
        )

        exportQueue.append(job)
        addLog(type: .info, message: "Queued export for \(mailbox.name)")

        Task {
            await processExportJob(job)
        }
    }

    private func processExportJob(_ job: ExportJob) async {
        guard let index = exportQueue.firstIndex(where: { $0.id == job.id }) else { return }

        exportQueue[index].status = .running
        exportQueue[index].startedAt = Date()
        addLog(type: .info, message: "Starting export of \(job.mailbox.name)")

        do {
            try await pythonBridge.exportMailbox(
                mailbox: job.mailbox.name,
                outputDir: job.options.outputDirectory,
                format: job.options.format,
                year: job.options.year,
                progressHandler: { progress in
                    Task { @MainActor in
                        if let idx = self.exportQueue.firstIndex(where: { $0.id == job.id }) {
                            self.exportQueue[idx].progress = progress
                        }
                    }
                }
            )

            exportQueue[index].status = .completed
            exportQueue[index].completedAt = Date()
            addLog(type: .success, message: "Completed export of \(job.mailbox.name)")
        } catch {
            exportQueue[index].status = .failed
            exportQueue[index].error = error.localizedDescription
            addLog(type: .error, message: "Export failed for \(job.mailbox.name): \(error.localizedDescription)")
        }
    }

    func addLog(type: LogEntry.LogType, message: String) {
        let entry = LogEntry(type: type, message: message, timestamp: Date())
        logEntries.insert(entry, at: 0)

        // Keep only last 1000 entries
        if logEntries.count > 1000 {
            logEntries.removeLast()
        }
    }

    func resetConfiguration() async {
        configManager.deleteToken()
        isConfigured = false
        hasConfigurationError = false
        mailboxes = []
        addLog(type: .warning, message: "Configuration reset")
    }

    func saveSettings() {
        do {
            try configManager.saveSettings(settings)
            addLog(type: .info, message: "Settings saved")
        } catch {
            addLog(type: .error, message: "Failed to save settings: \(error.localizedDescription)")
        }
    }

    // MARK: - Auto-Refresh Timer

    private func startAutoRefreshTimer() {
        guard let interval = settings.autoRefreshInterval, interval > 0 else {
            return
        }

        autoRefreshTask = Task { @MainActor in
            while !Task.isCancelled {
                // Wait for the specified interval (in minutes)
                try? await Task.sleep(nanoseconds: UInt64(interval) * 60 * 1_000_000_000)

                guard !Task.isCancelled, isConfigured else {
                    continue
                }

                // Refresh mailboxes
                await refreshMailboxes()
            }
        }

        addLog(type: .info, message: "Auto-refresh enabled (every \(interval) minutes)")
    }

    private func restartAutoRefreshTimer() {
        // Cancel existing timer
        autoRefreshTask?.cancel()
        autoRefreshTask = nil

        // Start new timer if enabled
        startAutoRefreshTimer()
    }

    func stopAutoRefreshTimer() {
        autoRefreshTask?.cancel()
        autoRefreshTask = nil
        addLog(type: .info, message: "Auto-refresh disabled")
    }
}
