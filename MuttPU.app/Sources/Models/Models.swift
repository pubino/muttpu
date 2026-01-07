//
//  Models.swift
//  MuttPU
//
//  Data models for the application
//

import Foundation

// MARK: - Mailbox

struct Mailbox: Identifiable, Codable, Hashable {
    let id: UUID
    let name: String
    var messageCount: Int?
    var isHidden: Bool

    init(id: UUID = UUID(), name: String, messageCount: Int? = nil, isHidden: Bool = false) {
        self.id = id
        self.name = name
        self.messageCount = messageCount
        self.isHidden = isHidden
    }

    var displayName: String {
        if let count = messageCount {
            return "\(name) (\(count.formatted()))"
        }
        return name
    }

    // Common non-mail Exchange folders to potentially hide
    static let nonMailFolders = [
        "Calendar",
        "Contacts",
        "Tasks",
        "Notes",
        "Journal",
        "RSS Feeds",
        "Conversation History"
    ]

    var isNonMailFolder: Bool {
        Mailbox.nonMailFolders.contains(where: { name.contains($0) })
    }
}

// MARK: - Export Options

struct ExportOptions: Codable {
    var format: ExportFormat
    var outputDirectory: String
    var year: Int?
    var resumeMode: ResumeMode
    var includeNonMailFolders: Bool

    init(
        format: ExportFormat = .eml,
        outputDirectory: String = "",
        year: Int? = nil,
        resumeMode: ResumeMode = .resume,
        includeNonMailFolders: Bool = false
    ) {
        self.format = format
        self.outputDirectory = outputDirectory
        self.year = year
        self.resumeMode = resumeMode
        self.includeNonMailFolders = includeNonMailFolders
    }
}

enum ExportFormat: String, Codable, CaseIterable {
    case eml = "EML"
    case mbox = "MBOX"

    var description: String {
        switch self {
        case .eml:
            return "EML (Individual files)"
        case .mbox:
            return "MBOX (Single file)"
        }
    }
}

enum ResumeMode: String, Codable, CaseIterable {
    case resume = "Resume"
    case fresh = "Start Fresh"
    case incremental = "Incremental"

    var description: String {
        switch self {
        case .resume:
            return "Resume interrupted exports"
        case .fresh:
            return "Start over, ignore previous state"
        case .incremental:
            return "Only export new messages"
        }
    }
}

// MARK: - Export Job

struct ExportJob: Identifiable, Codable {
    let id: UUID
    let mailbox: Mailbox
    let options: ExportOptions
    var status: JobStatus
    var progress: Double
    var error: String?
    let createdAt: Date
    var startedAt: Date?
    var completedAt: Date?

    enum JobStatus: String, Codable {
        case queued = "Queued"
        case running = "Running"
        case completed = "Completed"
        case failed = "Failed"
        case cancelled = "Cancelled"
    }

    var duration: TimeInterval? {
        guard let started = startedAt else { return nil }
        let end = completedAt ?? Date()
        return end.timeIntervalSince(started)
    }

    var formattedDuration: String? {
        guard let duration = duration else { return nil }
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: duration)
    }
}

// MARK: - Log Entry

struct LogEntry: Identifiable, Codable {
    let id: UUID
    let type: LogType
    let message: String
    let timestamp: Date

    init(id: UUID = UUID(), type: LogType, message: String, timestamp: Date) {
        self.id = id
        self.type = type
        self.message = message
        self.timestamp = timestamp
    }

    enum LogType: String, Codable {
        case info = "Info"
        case success = "Success"
        case warning = "Warning"
        case error = "Error"
    }

    var icon: String {
        switch type {
        case .info: return "info.circle"
        case .success: return "checkmark.circle"
        case .warning: return "exclamationmark.triangle"
        case .error: return "xmark.circle"
        }
    }
}

// MARK: - App Settings

struct AppSettings: Codable, Equatable {
    var hideNonMailFolders: Bool
    var defaultExportFormat: ExportFormat
    var defaultOutputDirectory: String?
    var defaultResumeMode: ResumeMode
    var autoRefreshInterval: Int? // minutes

    init(
        hideNonMailFolders: Bool = true,
        defaultExportFormat: ExportFormat = .eml,
        defaultOutputDirectory: String? = nil,
        defaultResumeMode: ResumeMode = .resume,
        autoRefreshInterval: Int? = nil
    ) {
        self.hideNonMailFolders = hideNonMailFolders
        self.defaultExportFormat = defaultExportFormat
        self.defaultOutputDirectory = defaultOutputDirectory
        self.defaultResumeMode = defaultResumeMode
        self.autoRefreshInterval = autoRefreshInterval
    }
}

// MARK: - Python Bridge Result

struct PythonResult<T: Decodable>: Decodable {
    let success: Bool
    let data: T?
    let error: String?
}
