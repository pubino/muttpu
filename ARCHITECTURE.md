# MuttPU Architecture

## System Overview

```
┌─────────────────────────────────────────────────────────┐
│                    MuttPU.app                           │
│                                                         │
│  ┌───────────────────────────────────────────────┐     │
│  │           SwiftUI Layer                       │     │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────┐   │     │
│  │  │ Content  │  │  Export  │  │ Settings │   │     │
│  │  │   View   │  │   View   │  │   View   │   │     │
│  │  └────┬─────┘  └────┬─────┘  └────┬─────┘   │     │
│  │       │             │              │          │     │
│  │  ┌────▼──────┐  ┌──▼────┐  ┌─────▼─────┐   │     │
│  │  │  Queue    │  │  Log  │  │   Setup   │   │     │
│  │  │   View    │  │  View │  │   View    │   │     │
│  │  └───────────┘  └───────┘  └───────────┘   │     │
│  └───────────────────┬───────────────────────┘     │
│                      │                              │
│  ┌───────────────────▼───────────────────────┐     │
│  │          AppState (ObservableObject)      │     │
│  │  • Mailboxes                              │     │
│  │  • Export Queue                           │     │
│  │  • Activity Logs                          │     │
│  │  • Settings                               │     │
│  └───────────────────┬───────────────────────┘     │
│                      │                              │
│  ┌───────────────────▼───────────────────────┐     │
│  │         Services Layer                    │     │
│  │  ┌──────────────┐  ┌─────────────────┐   │     │
│  │  │ PythonBridge │  │ Configuration   │   │     │
│  │  │   (Actor)    │  │    Manager      │   │     │
│  │  └──────┬───────┘  └────────┬────────┘   │     │
│  └─────────┼──────────────────┼─────────────┘     │
│            │                  │                     │
│  ┌─────────▼──────────────────▼─────────────┐     │
│  │       Bundled Resources                   │     │
│  │  • Python interpreter                     │     │
│  │  • muttpu.py script                       │     │
│  │  • OAuth2 helper scripts                  │     │
│  └───────────────────┬───────────────────────┘     │
└────────────────────┼─────────────────────────────┘
                     │
          ┌──────────▼──────────┐
          │   System Python     │
          │   (Fallback)        │
          └──────────┬──────────┘
                     │
          ┌──────────▼──────────┐
          │   External Tools    │
          │  • GPG              │
          │  • NeoMutt          │
          └──────────┬──────────┘
                     │
          ┌──────────▼──────────┐
          │   M365 Services     │
          │  • IMAP Server      │
          │  • OAuth2 Endpoint  │
          └─────────────────────┘
```

## Component Architecture

### 1. SwiftUI Layer

**Purpose**: User interface and user interaction

**Components**:
- `MuttPUApp.swift` - App entry point, window management
- `ContentView.swift` - Main mailbox list
- `MailboxDetailView.swift` - Selected mailbox details
- `ExportView.swift` - Export configuration sheet
- `SetupView.swift` - OAuth2 setup wizard
- `SettingsView.swift` - App settings
- `QueueView.swift` - Export queue window
- `LogView.swift` - Activity log window

**Data Flow**:
- All views observe `AppState` via `@EnvironmentObject`
- User actions trigger `AppState` methods
- UI updates automatically via Combine publishers

### 2. State Management

**AppState** (MainActor class)
```swift
@MainActor
class AppState: ObservableObject {
    @Published var isConfigured: Bool
    @Published var mailboxes: [Mailbox]
    @Published var exportQueue: [ExportJob]
    @Published var logEntries: [LogEntry]
    @Published var settings: AppSettings
}
```

**Responsibilities**:
- Central source of truth for app state
- Coordinates between UI and services
- Manages export queue
- Maintains activity log
- Persists user settings

### 3. Services Layer

#### PythonBridge (Actor)

**Purpose**: Thread-safe Python script execution

**Methods**:
```swift
actor PythonBridge {
    func testConnection() async throws -> PythonResult<Bool>
    func listMailboxes() async throws -> [Mailbox]
    func countMessages(mailbox: String) async throws -> Int
    func exportMailbox(...) async throws
    func setupOAuth2() async throws -> String
}
```

**Features**:
- Async/await interface
- Parses Python script output
- Progress tracking for long operations
- Error handling and recovery

#### ConfigurationManager (Singleton)

**Purpose**: Manage configuration and settings

**Methods**:
```swift
class ConfigurationManager {
    func checkTokenExists() -> Bool
    func deleteToken()
    func saveSettings(_ settings: AppSettings) throws
    func loadSettings() -> AppSettings?
    func checkDependencies() -> [String]
    func validateConfiguration() -> ConfigurationStatus
}
```

### 4. Data Models

**Core Models**:
- `Mailbox` - Represents an email folder
- `ExportJob` - Tracks export operation
- `ExportOptions` - Export configuration
- `LogEntry` - Activity log entry
- `AppSettings` - User preferences

**Enums**:
- `ExportFormat` - EML or MBOX
- `ResumeMode` - Fresh, Resume, or Incremental
- `JobStatus` - Queued, Running, Completed, Failed, Cancelled
- `LogType` - Info, Success, Warning, Error

## Data Flow

### OAuth2 Setup Flow

```
User Clicks "Setup"
    ↓
SetupView → AppState.runSetup()
    ↓
PythonBridge.setupOAuth2()
    ↓
Execute: python3 muttpu.py setup
    ↓
Parse output for URL and device code
    ↓
Open browser with URL
    ↓
Poll for completion
    ↓
Token saved to ~/Downloads/muttpu/token.gpg
    ↓
AppState.checkConfiguration()
    ↓
UI updates (isConfigured = true)
```

### Mailbox Listing Flow

```
User Clicks "Refresh"
    ↓
ContentView → AppState.refreshMailboxes()
    ↓
PythonBridge.listMailboxes()
    ↓
Execute: python3 muttpu.py list
    ↓
Parse output for mailbox names
    ↓
For each mailbox:
    PythonBridge.countMessages()
        ↓
    Execute: python3 muttpu.py count <mailbox>
        ↓
    Parse message count
    ↓
Update AppState.mailboxes
    ↓
UI updates automatically
```

### Export Flow

```
User Configures Export
    ↓
ExportView → AppState.exportMailbox()
    ↓
Create ExportJob and add to queue
    ↓
AppState.processExportJob()
    ↓
PythonBridge.exportMailbox()
    ↓
Execute: python3 muttpu.py export <mailbox> <output> [options]
    ↓
Stream output and parse progress
    ↓
Update job.progress
    ↓
QueueView shows progress bar
    ↓
On completion:
    - Mark job complete
    - Add log entry
    - UI updates
```

## File System Layout

```
MuttPU.app/
├── Contents/
│   ├── MacOS/
│   │   └── MuttPU                    # Main executable
│   ├── Resources/
│   │   ├── Python/
│   │   │   ├── bin/python3           # Bundled interpreter
│   │   │   ├── muttpu.py             # Main script
│   │   │   └── mutt_oauth2.py        # OAuth2 helper
│   │   └── Assets.car                # App icon/assets
│   ├── Frameworks/                   # Python frameworks
│   ├── Info.plist                    # App metadata
│   └── PkgInfo                       # Package type

User Configuration (~/Downloads/muttpu/):
├── token.gpg                         # Encrypted OAuth2 token
└── settings.json                     # User preferences

Export Destinations (user chosen):
└── <output_dir>/
    ├── .export_state.json            # Resume state
    ├── messages.mbox                 # or...
    └── *.eml                         # Individual messages
```

## Security Architecture

### OAuth2 Token Protection

1. **Storage**: Token encrypted with GPG
2. **Location**: User's home directory (not app bundle)
3. **Access**: Only via GPG decrypt (user's key)
4. **Transmission**: Never leaves machine, used only for IMAP auth

### Sandboxing Considerations

**App Sandbox**: Currently NOT sandboxed (requires broader access)
- File system: User selects directories via NSOpenPanel
- Network: IMAP connection to M365
- Process: Spawns Python subprocess

**Future**: Consider sandbox with proper entitlements:
- `com.apple.security.files.user-selected.read-write`
- `com.apple.security.network.client`
- `com.apple.security.temporary-exception.subprocess`

## Threading Model

### Main Thread (MainActor)
- All UI updates
- AppState property changes
- User interaction handling

### Background (Actor)
- PythonBridge operations
- Long-running Python scripts
- File I/O operations

### Async/Await
- All Python operations use async
- UI remains responsive during exports
- Progress updates via async streams

## Error Handling

### Levels

1. **Python Script Errors**:
   - Caught by PythonBridge
   - Parsed from stderr
   - Converted to Swift errors

2. **Service Errors**:
   - Wrapped in domain-specific errors
   - Logged to activity log
   - Shown to user via alerts

3. **UI Errors**:
   - Displayed inline in views
   - Non-blocking where possible
   - Clear recovery actions

### Recovery Strategies

- **Token Expired**: Show setup wizard
- **Network Error**: Suggest VPN, retry
- **Export Failed**: Keep job in queue, show error, allow retry
- **Missing Dependencies**: Show install instructions

## Performance Considerations

### Optimization Points

1. **Mailbox Counting**: Can be slow for large folders
   - Consider caching with TTL
   - Optional auto-refresh

2. **Export Progress**: Currently parses every line
   - Could batch updates (e.g., every 100 messages)
   - Reduce UI update frequency

3. **Log Entries**: Unbounded growth
   - Currently limited to 1000 entries
   - Consider database for persistence

4. **Python Subprocess**: New process per operation
   - Could use persistent process with IPC
   - Trade-off: complexity vs. startup cost

## Testing Strategy

### Unit Tests (`test_muttpu.py`)
- Python script functionality
- Data parsing
- State management logic

### Integration Tests (`integration_test.sh`)
- End-to-end workflows
- Build process
- App bundle structure

### Manual Testing Checklist
- [ ] OAuth2 setup flow
- [ ] Mailbox listing
- [ ] Message counting
- [ ] Export to EML
- [ ] Export to MBOX
- [ ] Year filtering
- [ ] Resume/incremental modes
- [ ] Settings persistence
- [ ] Error scenarios

## Build System

### Current (Shell Script)
```bash
swiftc → Compile sources
       → Create .app bundle
       → Copy Python files
       → Generate Info.plist
```

### Future (Xcode)
```
Xcode Project
  → Build Phases
      → Compile Swift sources
      → Bundle Python (custom script)
      → Copy resources
      → Code signing
  → Schemes
      → MuttPU (Release)
      → MuttPU (Debug)
```

## Deployment Pipeline

```
Development
    ↓
./scripts/build.sh
    ↓
./scripts/test.sh
    ↓
Manual testing
    ↓
./scripts/notarize.sh
    ↓
Distribution (DMG)
```

## Future Enhancements

### Short Term
1. Xcode project setup
2. Python bundling (py2app)
3. App icon
4. Settings persistence on launch

### Medium Term
1. Scheduled exports
2. Enhanced progress tracking
3. Export templates
4. Multiple account support

### Long Term
1. Direct Swift IMAP implementation (no Python)
2. Cloud backup integration
3. Search across archives
4. Email viewer within app
