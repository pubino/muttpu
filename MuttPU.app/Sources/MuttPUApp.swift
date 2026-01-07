//
//  MuttPUApp.swift
//  MuttPU
//
//  SwiftUI application for MuttPU mail archiving utility
//

import SwiftUI

@main
struct MuttPUApp: App {
    @StateObject private var appState = AppState()
    @StateObject private var pythonBridge = PythonBridge.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .environmentObject(pythonBridge)
                .onAppear {
                    Task {
                        await appState.checkConfiguration()
                    }
                }
        }
        .commands {
            CommandGroup(replacing: .newItem) {}
            CommandMenu("Mailboxes") {
                Button("Refresh") {
                    Task {
                        await appState.refreshMailboxes()
                    }
                }
                .keyboardShortcut("r", modifiers: .command)
            }
        }

        // Settings window
        Settings {
            SettingsView()
                .environmentObject(appState)
                .environmentObject(pythonBridge)
        }

        // Queue window
        Window("Export Queue", id: "queue") {
            QueueView()
                .environmentObject(appState)
                .frame(minWidth: 600, minHeight: 400)
        }

        // Log window
        Window("Activity Log", id: "log") {
            LogView()
                .environmentObject(appState)
                .frame(minWidth: 700, minHeight: 500)
        }
    }
}
