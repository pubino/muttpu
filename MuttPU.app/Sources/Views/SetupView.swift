//
//  SetupView.swift
//  MuttPU
//
//  OAuth2 setup and first-launch configuration
//

import SwiftUI

struct SetupView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss

    @State private var isRunningSetup = false
    @State private var setupOutput = ""
    @State private var setupComplete = false
    @State private var showingError = false
    @State private var errorMessage = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                // Header
                VStack(spacing: 15) {
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 70))
                        .foregroundStyle(.blue)

                    Text("OAuth2 Setup")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    Text("Connect to your M365 account securely")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 40)

                // Setup status
                if appState.hasConfigurationError {
                    configurationErrorView
                } else if appState.isConfigured {
                    configuredView
                } else {
                    notConfiguredView
                }

                Spacer()

                // Setup output console
                if isRunningSetup && !setupOutput.isEmpty {
                    setupConsole
                }
            }
            .padding()
            .frame(minWidth: 600, minHeight: 500)
            .navigationTitle("Setup")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                    .disabled(isRunningSetup)
                }
            }
            .alert("Setup Error", isPresented: $showingError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }

    // MARK: - Status Views

    private var configuredView: some View {
        VStack(spacing: 20) {
            HStack(spacing: 10) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .font(.title)

                Text("OAuth2 Configured")
                    .font(.title3)
                    .fontWeight(.semibold)
            }

            Text("Your M365 account is connected and ready to use.")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Divider()
                .padding(.vertical)

            VStack(spacing: 15) {
                Button {
                    runSetup()
                } label: {
                    Label("Re-authorize", systemImage: "arrow.clockwise")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .disabled(isRunningSetup)

                Button(role: .destructive) {
                    Task {
                        await appState.resetConfiguration()
                    }
                } label: {
                    Label("Remove Configuration", systemImage: "trash")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .disabled(isRunningSetup)
            }
            .controlSize(.large)
        }
        .padding()
    }

    private var notConfiguredView: some View {
        VStack(spacing: 20) {
            HStack(spacing: 10) {
                Image(systemName: "exclamationmark.circle.fill")
                    .foregroundStyle(.orange)
                    .font(.title)

                Text("Not Configured")
                    .font(.title3)
                    .fontWeight(.semibold)
            }

            Text("Set up OAuth2 authentication to access your M365 mailboxes.")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Divider()
                .padding(.vertical)

            setupInstructions

            Button {
                runSetup()
            } label: {
                Label(isRunningSetup ? "Setting up..." : "Start Setup", systemImage: "play.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(isRunningSetup)
        }
        .padding()
    }

    private var configurationErrorView: some View {
        VStack(spacing: 20) {
            HStack(spacing: 10) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.red)
                    .font(.title)

                Text("Configuration Error")
                    .font(.title3)
                    .fontWeight(.semibold)
            }

            Text(appState.configurationErrorMessage)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.red.opacity(0.1))
                )

            Divider()
                .padding(.vertical)

            VStack(spacing: 15) {
                Button {
                    runSetup()
                } label: {
                    Label("Retry Setup", systemImage: "arrow.clockwise")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(isRunningSetup)

                Button(role: .destructive) {
                    Task {
                        await appState.resetConfiguration()
                    }
                } label: {
                    Label("Reset Configuration", systemImage: "trash")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .disabled(isRunningSetup)
            }
            .controlSize(.large)
        }
        .padding()
    }

    private var setupInstructions: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("What happens next:")
                .font(.headline)

            VStack(alignment: .leading, spacing: 8) {
                Label("A browser window will open", systemImage: "1.circle.fill")
                Label("Sign in with your M365 account", systemImage: "2.circle.fill")
                Label("Enter the device code shown", systemImage: "3.circle.fill")
                Label("Authorize the application", systemImage: "4.circle.fill")
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.blue.opacity(0.1))
        )
    }

    private var setupConsole: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Setup Progress")
                .font(.headline)

            ScrollView {
                ScrollViewReader { proxy in
                    Text(setupOutput)
                        .font(.system(.caption, design: .monospaced))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(10)
                        .id("bottom")
                        .onChange(of: setupOutput) { _, _ in
                            proxy.scrollTo("bottom")
                        }
                }
            }
            .frame(height: 200)
            .background(Color(nsColor: .textBackgroundColor))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
            )
        }
    }

    // MARK: - Actions

    private func runSetup() {
        isRunningSetup = true
        setupOutput = ""
        setupComplete = false

        Task {
            do {
                // Check dependencies first
                let missingDeps = ConfigurationManager.shared.checkDependencies()
                if !missingDeps.isEmpty {
                    await MainActor.run {
                        errorMessage = "Missing dependencies: \(missingDeps.joined(separator: ", "))\n\nPlease install them using:\nbrew install \(missingDeps.joined(separator: " "))"
                        showingError = true
                        isRunningSetup = false
                    }
                    return
                }

                // Run setup with streaming output
                let output = try await PythonBridge.shared.setupOAuth2WithStreaming { chunk in
                    Task { @MainActor in
                        self.setupOutput += chunk

                        // Debug: print what we're receiving
                        print("OAuth2 output chunk: \(chunk)")

                        // Look for Microsoft login URLs in the output
                        if let url = self.extractLoginURL(from: chunk) {
                            print("Found URL, opening browser: \(url)")
                            self.openBrowser(url: url)
                        } else if chunk.contains("microsoft") || chunk.contains("https://") {
                            print("Chunk contains microsoft or https but no URL extracted")
                        }
                    }
                }

                await MainActor.run {
                    setupOutput = output
                    setupComplete = true
                    isRunningSetup = false
                }

                // Re-check configuration
                await appState.checkConfiguration()

                if appState.isConfigured {
                    await MainActor.run {
                        dismiss()
                    }
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showingError = true
                    isRunningSetup = false
                }
            }
        }
    }

    private func extractLoginURL(from text: String) -> URL? {
        // Look for any Microsoft URLs (matches Python script pattern)
        // Python checks: 'https://' in line and 'microsoft.com' in line
        // Also handle login.microsoftonline.com
        guard text.contains("https://") &&
              (text.contains("microsoft.com") || text.contains("microsoftonline.com")) else {
            return nil
        }

        // Extract URL using same pattern as Python: r'(https://[^\s]+)'
        let pattern = #"(https://[^\s]+)"#
        if let range = text.range(of: pattern, options: .regularExpression) {
            let urlString = String(text[range])
            // Only return if it's a microsoft-related URL
            if urlString.contains("microsoft.com") || urlString.contains("microsoftonline.com") {
                return URL(string: urlString)
            }
        }
        return nil
    }

    private func openBrowser(url: URL) {
        NSWorkspace.shared.open(url)
    }
}
