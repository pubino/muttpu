//
//  ExportView.swift
//  MuttPU
//
//  Export configuration sheet
//

import SwiftUI
import AppKit

struct ExportView: View {
    let mailbox: Mailbox
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss

    @State private var format: ExportFormat
    @State private var outputDirectory: String
    @State private var useDefaultDirectory: Bool
    @State private var filterByYear: Bool = false
    @State private var selectedYear: Int
    @State private var resumeMode: ResumeMode

    init(mailbox: Mailbox) {
        self.mailbox = mailbox

        // Initialize from app settings
        let settings = AppSettings()
        _format = State(initialValue: settings.defaultExportFormat)
        _outputDirectory = State(initialValue: settings.defaultOutputDirectory ?? "")
        _useDefaultDirectory = State(initialValue: settings.defaultOutputDirectory != nil)
        _selectedYear = State(initialValue: Calendar.current.component(.year, from: Date()))
        _resumeMode = State(initialValue: settings.defaultResumeMode)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Mailbox") {
                    LabeledContent("Name", value: mailbox.name)
                    if let count = mailbox.messageCount {
                        LabeledContent("Messages", value: "\(count.formatted())")
                    }
                }

                Section("Export Format") {
                    Picker("Format", selection: $format) {
                        ForEach(ExportFormat.allCases, id: \.self) { format in
                            Text(format.description).tag(format)
                        }
                    }
                    .pickerStyle(.segmented)

                    Text(formatDescription)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("Output Directory") {
                    if useDefaultDirectory && !appState.settings.defaultOutputDirectory.isNilOrEmpty {
                        LabeledContent("Directory", value: appState.settings.defaultOutputDirectory ?? "")
                        Toggle("Use default directory", isOn: $useDefaultDirectory)
                    } else {
                        HStack {
                            TextField("Select output directory", text: $outputDirectory)
                                .disabled(true)

                            Button("Choose...") {
                                selectOutputDirectory()
                            }
                        }

                        if !appState.settings.defaultOutputDirectory.isNilOrEmpty {
                            Toggle("Use default directory", isOn: $useDefaultDirectory)
                        }
                    }
                }

                Section("Date Filter") {
                    Toggle("Filter by year", isOn: $filterByYear)

                    if filterByYear {
                        Picker("Year", selection: $selectedYear) {
                            ForEach((2000...Calendar.current.component(.year, from: Date())).reversed(), id: \.self) { year in
                                Text(String(year)).tag(year)
                            }
                        }
                    }
                }

                Section("Resume Behavior") {
                    Picker("Mode", selection: $resumeMode) {
                        ForEach(ResumeMode.allCases, id: \.self) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }

                    Text(resumeMode.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .formStyle(.grouped)
            .navigationTitle("Export \(mailbox.name)")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Export") {
                        startExport()
                        dismiss()
                    }
                    .disabled(!canExport)
                }
            }
        }
        .frame(minWidth: 500, minHeight: 500)
    }

    private var formatDescription: String {
        switch format {
        case .eml:
            return "Each message saved as a separate .eml file. Best for archival and selective access."
        case .mbox:
            return "All messages in a single .mbox file. Best for backups and importing to email clients."
        }
    }

    private var canExport: Bool {
        if useDefaultDirectory {
            return appState.settings.defaultOutputDirectory != nil
        } else {
            return !outputDirectory.isEmpty
        }
    }

    private var effectiveOutputDirectory: String {
        if useDefaultDirectory {
            return appState.settings.defaultOutputDirectory ?? ""
        } else {
            return outputDirectory
        }
    }

    private func selectOutputDirectory() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = true
        panel.message = "Choose export destination"

        if panel.runModal() == .OK, let url = panel.url {
            outputDirectory = url.path
        }
    }

    private func startExport() {
        let options = ExportOptions(
            format: format,
            outputDirectory: effectiveOutputDirectory,
            year: filterByYear ? selectedYear : nil,
            resumeMode: resumeMode,
            includeNonMailFolders: !appState.settings.hideNonMailFolders
        )

        appState.exportMailbox(mailbox, options: options)
    }
}

// Helper extension
extension Optional where Wrapped == String {
    var isNilOrEmpty: Bool {
        return self?.isEmpty ?? true
    }
}
