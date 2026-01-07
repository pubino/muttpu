//
//  LogView.swift
//  MuttPU
//
//  Activity log window
//

import SwiftUI

struct LogView: View {
    @EnvironmentObject var appState: AppState
    @State private var searchText = ""
    @State private var selectedType: LogEntry.LogType?

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Activity Log")
                    .font(.title2)
                    .fontWeight(.semibold)

                Spacer()

                // Filter buttons
                HStack(spacing: 8) {
                    ForEach([LogEntry.LogType.info, .success, .warning, .error], id: \.self) { type in
                        Button {
                            if selectedType == type {
                                selectedType = nil
                            } else {
                                selectedType = type
                            }
                        } label: {
                            Image(systemName: iconForType(type))
                        }
                        .buttonStyle(.bordered)
                        .tint(selectedType == type ? colorForType(type) : .gray)
                    }
                }

                Button {
                    appState.logEntries.removeAll()
                } label: {
                    Label("Clear", systemImage: "trash")
                }
                .buttonStyle(.bordered)
            }
            .padding()

            Divider()

            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)

                TextField("Search logs...", text: $searchText)
                    .textFieldStyle(.plain)

                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color(nsColor: .controlBackgroundColor))

            Divider()

            // Log list
            if filteredLogs.isEmpty {
                emptyState
            } else {
                logList
            }
        }
    }

    private var filteredLogs: [LogEntry] {
        var logs = appState.logEntries

        // Filter by type
        if let type = selectedType {
            logs = logs.filter { $0.type == type }
        }

        // Filter by search
        if !searchText.isEmpty {
            logs = logs.filter { $0.message.localizedCaseInsensitiveContains(searchText) }
        }

        return logs
    }

    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.text")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)

            if !searchText.isEmpty || selectedType != nil {
                Text("No Matching Logs")
                    .font(.title3)
                    .foregroundStyle(.secondary)

                Button("Clear Filters") {
                    searchText = ""
                    selectedType = nil
                }
                .buttonStyle(.bordered)
            } else {
                Text("No Activity Yet")
                    .font(.title3)
                    .foregroundStyle(.secondary)

                Text("Activity will be logged here")
                    .font(.subheadline)
                    .foregroundStyle(.tertiary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var logList: some View {
        List {
            ForEach(filteredLogs) { entry in
                LogEntryRow(entry: entry)
            }
        }
    }

    private func iconForType(_ type: LogEntry.LogType) -> String {
        switch type {
        case .info: return "info.circle"
        case .success: return "checkmark.circle"
        case .warning: return "exclamationmark.triangle"
        case .error: return "xmark.circle"
        }
    }

    private func colorForType(_ type: LogEntry.LogType) -> Color {
        switch type {
        case .info: return .blue
        case .success: return .green
        case .warning: return .orange
        case .error: return .red
        }
    }
}

struct LogEntryRow: View {
    let entry: LogEntry

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: entry.icon)
                .foregroundStyle(iconColor)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 4) {
                Text(entry.message)
                    .font(.body)
                    .textSelection(.enabled)

                Text(entry.timestamp.formatted(date: .abbreviated, time: .standard))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }

    private var iconColor: Color {
        switch entry.type {
        case .info: return .blue
        case .success: return .green
        case .warning: return .orange
        case .error: return .red
        }
    }
}
