//
//  SettingsView.swift
//  MuttPU
//
//  Application settings
//

import SwiftUI
import AppKit

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @State private var showingResetAlert = false

    var body: some View {
        TabView {
            generalSettings
                .tabItem {
                    Label("General", systemImage: "gearshape")
                }

            exportSettings
                .tabItem {
                    Label("Export", systemImage: "square.and.arrow.up")
                }

            authenticationSettings
                .tabItem {
                    Label("Authentication", systemImage: "lock.shield")
                }

            advancedSettings
                .tabItem {
                    Label("Advanced", systemImage: "slider.horizontal.3")
                }
        }
        .frame(width: 550, height: 400)
        .onChange(of: appState.settings) { _, newSettings in
            appState.saveSettings()
        }
    }

    // MARK: - General Settings

    private var generalSettings: some View {
        Form {
            Section {
                Toggle("Hide non-mail Exchange folders", isOn: $appState.settings.hideNonMailFolders)

                Text("Hides folders like Calendar, Contacts, Tasks, etc.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } header: {
                Text("Mailbox Display")
            }

            Section {
                Picker("Auto-refresh interval", selection: $appState.settings.autoRefreshInterval) {
                    Text("Never").tag(nil as Int?)
                    Text("5 minutes").tag(5 as Int?)
                    Text("15 minutes").tag(15 as Int?)
                    Text("30 minutes").tag(30 as Int?)
                    Text("1 hour").tag(60 as Int?)
                }

                if appState.settings.autoRefreshInterval != nil {
                    Text("Mailbox counts will refresh automatically")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text("Refresh")
            }
        }
        .formStyle(.grouped)
        .padding()
    }

    // MARK: - Export Settings

    private var exportSettings: some View {
        Form {
            Section {
                Picker("Default format", selection: $appState.settings.defaultExportFormat) {
                    ForEach(ExportFormat.allCases, id: \.self) { format in
                        Text(format.description).tag(format)
                    }
                }

                Text(appState.settings.defaultExportFormat == .eml
                     ? "Individual .eml files (best for archival)"
                     : "Single .mbox file (best for backups)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } header: {
                Text("Format")
            }

            Section {
                HStack {
                    if let dir = appState.settings.defaultOutputDirectory {
                        Text(dir)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    } else {
                        Text("Prompt each time")
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Button("Choose...") {
                        selectDefaultDirectory()
                    }

                    if appState.settings.defaultOutputDirectory != nil {
                        Button("Clear") {
                            appState.settings.defaultOutputDirectory = nil
                        }
                        .buttonStyle(.bordered)
                    }
                }

                Text("Set a default directory or choose manually for each export")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } header: {
                Text("Output Directory")
            }

            Section {
                Picker("Resume behavior", selection: $appState.settings.defaultResumeMode) {
                    ForEach(ResumeMode.allCases, id: \.self) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }

                Text(appState.settings.defaultResumeMode.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } header: {
                Text("Resume Mode")
            }
        }
        .formStyle(.grouped)
        .padding()
    }

    // MARK: - Authentication Settings

    private var authenticationSettings: some View {
        Form {
            Section {
                LabeledContent("Status") {
                    HStack {
                        Image(systemName: appState.isConfigured
                              ? "checkmark.circle.fill"
                              : "xmark.circle.fill")
                            .foregroundStyle(appState.isConfigured ? .green : .red)

                        Text(appState.isConfigured ? "Configured" : "Not Configured")
                    }
                }

                LabeledContent("Token Location") {
                    Text(ConfigurationManager.shared.tokenPath)
                        .font(.caption)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
            } header: {
                Text("OAuth2")
            }

            Section {
                Button("Re-authorize") {
                    Task {
                        // Run setup
                        _ = try? await PythonBridge.shared.setupOAuth2()
                        await appState.checkConfiguration()
                    }
                }
                .buttonStyle(.bordered)

                Button("Reset Configuration", role: .destructive) {
                    showingResetAlert = true
                }
                .buttonStyle(.bordered)
            } header: {
                Text("Actions")
            }
        }
        .formStyle(.grouped)
        .padding()
        .alert("Reset Configuration?", isPresented: $showingResetAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Reset", role: .destructive) {
                Task {
                    await appState.resetConfiguration()
                }
            }
        } message: {
            Text("This will delete your OAuth2 token. You'll need to authenticate again.")
        }
    }

    // MARK: - Advanced Settings

    private var advancedSettings: some View {
        Form {
            Section {
                Text("Scheduled export jobs coming soon")
                    .foregroundStyle(.secondary)
                    .italic()
            } header: {
                Text("Scheduled Exports")
            }

            Section {
                LabeledContent("Python Path") {
                    Text("/usr/bin/python3")
                        .font(.caption)
                        .lineLimit(1)
                }

                LabeledContent("Config Directory") {
                    Text(ConfigurationManager.shared.getTokenDirectory())
                        .font(.caption)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
            } header: {
                Text("System")
            }
        }
        .formStyle(.grouped)
        .padding()
    }

    // MARK: - Actions

    private func selectDefaultDirectory() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = true
        panel.message = "Choose default export directory"

        if panel.runModal() == .OK, let url = panel.url {
            appState.settings.defaultOutputDirectory = url.path
        }
    }
}
