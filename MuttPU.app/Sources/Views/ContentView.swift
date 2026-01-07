//
//  ContentView.swift
//  MuttPU
//
//  Main content view with mailbox list
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedMailbox: Mailbox?
    @State private var showingExportSheet = false
    @State private var showingSetup = false
    @State private var searchText = ""

    var body: some View {
        NavigationSplitView {
            // Sidebar with mailbox list
            mailboxList
        } detail: {
            // Detail view
            if let mailbox = selectedMailbox {
                MailboxDetailView(mailbox: mailbox)
            } else {
                placeholderView
            }
        }
        .navigationTitle("MuttPU")
        .sheet(isPresented: $showingSetup) {
            SetupView()
        }
        .sheet(isPresented: $showingExportSheet) {
            if let mailbox = selectedMailbox {
                ExportView(mailbox: mailbox)
            }
        }
        .onAppear {
            if !appState.isConfigured {
                showingSetup = true
            }
        }
        .onChange(of: appState.isConfigured) { _, isConfigured in
            if isConfigured {
                Task {
                    await appState.refreshMailboxes()
                }
            }
        }
    }

    private var mailboxList: some View {
        List(selection: $selectedMailbox) {
            Section {
                ForEach(filteredMailboxes) { mailbox in
                    MailboxRow(mailbox: mailbox)
                        .tag(mailbox)
                }
            } header: {
                HStack {
                    Text("Mailboxes")
                    Spacer()
                    if appState.isLoadingMailboxes {
                        ProgressView()
                            .scaleEffect(0.7)
                    }
                }
            }
        }
        .searchable(text: $searchText, prompt: "Search mailboxes")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    Task {
                        await appState.refreshMailboxes()
                    }
                } label: {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
                .disabled(appState.isLoadingMailboxes || !appState.isConfigured)
            }

            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingExportSheet = true
                } label: {
                    Label("Export", systemImage: "square.and.arrow.up")
                }
                .disabled(selectedMailbox == nil)
            }
        }
    }

    private var filteredMailboxes: [Mailbox] {
        let mailboxes = appState.mailboxes

        // Filter by search
        let searched = searchText.isEmpty
            ? mailboxes
            : mailboxes.filter { $0.name.localizedCaseInsensitiveContains(searchText) }

        // Filter by settings
        if appState.settings.hideNonMailFolders {
            return searched.filter { !$0.isNonMailFolder }
        }

        return searched
    }

    private var placeholderView: some View {
        VStack(spacing: 20) {
            Image(systemName: "envelope.open")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)

            Text("Select a Mailbox")
                .font(.title2)
                .foregroundStyle(.secondary)

            if !appState.isConfigured {
                Button("Setup OAuth2") {
                    showingSetup = true
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct MailboxRow: View {
    let mailbox: Mailbox

    var body: some View {
        HStack {
            Image(systemName: mailboxIcon)
                .foregroundStyle(mailboxColor)
                .frame(width: 20)

            Text(mailbox.name)

            Spacer()

            if let count = mailbox.messageCount {
                Text("\(count.formatted())")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var mailboxIcon: String {
        switch mailbox.name.lowercased() {
        case "inbox":
            return "tray.fill"
        case "sent items", "sent":
            return "paperplane.fill"
        case "archive":
            return "archivebox.fill"
        case "deleted items", "trash":
            return "trash.fill"
        case "junk email", "spam":
            return "exclamationmark.octagon.fill"
        case "drafts":
            return "doc.text.fill"
        default:
            return "folder.fill"
        }
    }

    private var mailboxColor: Color {
        switch mailbox.name.lowercased() {
        case "inbox":
            return .blue
        case "sent items", "sent":
            return .green
        case "archive":
            return .purple
        case "deleted items", "trash":
            return .red
        case "junk email", "spam":
            return .orange
        case "drafts":
            return .yellow
        default:
            return .gray
        }
    }
}
