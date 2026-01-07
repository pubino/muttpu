//
//  QueueView.swift
//  MuttPU
//
//  Export queue window
//

import SwiftUI

struct QueueView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Export Queue")
                    .font(.title2)
                    .fontWeight(.semibold)

                Spacer()

                Text("\(appState.exportQueue.count) jobs")
                    .foregroundStyle(.secondary)
            }
            .padding()

            Divider()

            // Queue list
            if appState.exportQueue.isEmpty {
                emptyState
            } else {
                queueList
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "tray")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)

            Text("No Export Jobs")
                .font(.title3)
                .foregroundStyle(.secondary)

            Text("Export jobs will appear here")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var queueList: some View {
        List {
            ForEach(appState.exportQueue) { job in
                QueueJobRow(job: job)
            }
        }
    }
}

struct QueueJobRow: View {
    let job: ExportJob

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header
            HStack {
                Image(systemName: statusIcon)
                    .foregroundStyle(statusColor)

                VStack(alignment: .leading, spacing: 2) {
                    Text(job.mailbox.name)
                        .font(.headline)

                    Text(job.options.format.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text(job.status.rawValue)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(statusColor.opacity(0.2))
                    )
                    .foregroundStyle(statusColor)
            }

            // Progress
            if job.status == .running {
                ProgressView(value: job.progress, total: 1.0) {
                    HStack {
                        Text("\(Int(job.progress * 100))%")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Spacer()

                        if let duration = job.formattedDuration {
                            Text(duration)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            // Error message
            if job.status == .failed, let error = job.error {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.red.opacity(0.1))
                    )
            }

            // Timestamps
            HStack(spacing: 15) {
                Label(job.createdAt.formatted(date: .omitted, time: .shortened), systemImage: "clock")
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                if let duration = job.formattedDuration, job.status == .completed {
                    Label(duration, systemImage: "timer")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if job.status == .completed {
                    Button {
                        revealInFinder(path: job.options.outputDirectory)
                    } label: {
                        Label("Show in Finder", systemImage: "folder")
                            .font(.caption)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }
        }
        .padding(.vertical, 8)
    }

    private var statusIcon: String {
        switch job.status {
        case .queued:
            return "clock.fill"
        case .running:
            return "arrow.clockwise.circle.fill"
        case .completed:
            return "checkmark.circle.fill"
        case .failed:
            return "xmark.circle.fill"
        case .cancelled:
            return "stop.circle.fill"
        }
    }

    private var statusColor: Color {
        switch job.status {
        case .queued:
            return .orange
        case .running:
            return .blue
        case .completed:
            return .green
        case .failed:
            return .red
        case .cancelled:
            return .gray
        }
    }

    private func revealInFinder(path: String) {
        NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: path)
    }
}
