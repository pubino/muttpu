//
//  MailboxDetailView.swift
//  MuttPU
//
//  Detail view for selected mailbox
//

import SwiftUI

struct MailboxDetailView: View {
    let mailbox: Mailbox
    @EnvironmentObject var appState: AppState
    @State private var showingExportSheet = false

    var body: some View {
        VStack(spacing: 20) {
            // Mailbox info
            VStack(spacing: 10) {
                Image(systemName: "envelope.open.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.blue)

                Text(mailbox.name)
                    .font(.title)
                    .fontWeight(.semibold)

                if let count = mailbox.messageCount {
                    Text("\(count.formatted()) messages")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
            }
            .padding()

            Divider()

            // Actions
            VStack(spacing: 15) {
                Button {
                    showingExportSheet = true
                } label: {
                    Label("Export Mailbox", systemImage: "square.and.arrow.up")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                Button {
                    Task {
                        await refreshCount()
                    }
                } label: {
                    Label("Refresh Count", systemImage: "arrow.clockwise")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
            }
            .padding(.horizontal, 40)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .sheet(isPresented: $showingExportSheet) {
            ExportView(mailbox: mailbox)
        }
    }

    private func refreshCount() async {
        guard let index = appState.mailboxes.firstIndex(where: { $0.id == mailbox.id }) else {
            return
        }

        do {
            let count = try await PythonBridge.shared.countMessages(mailbox: mailbox.name)
            await MainActor.run {
                appState.mailboxes[index].messageCount = count
            }
        } catch {
            await MainActor.run {
                appState.addLog(
                    type: .error,
                    message: "Failed to refresh count for \(mailbox.name): \(error.localizedDescription)"
                )
            }
        }
    }
}
