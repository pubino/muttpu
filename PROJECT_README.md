# MuttPU - SwiftUI App Bundle

A native macOS application for archiving Microsoft 365 email, wrapping the MuttPU Python utility with a modern SwiftUI interface.

## Overview

MuttPU combines a powerful Python-based email archiving backend with a beautiful macOS-native SwiftUI frontend. Users can:

- Authenticate with M365 using OAuth2 (secure, no passwords)
- Browse mailboxes with message counts
- Export mailboxes to EML or MBOX format
- Filter exports by year/date range
- Track export progress in real-time
- View activity logs
- Configure settings for automated workflows

## Project Structure

```
muttpu/
├── MuttPU.app/               # SwiftUI application
│   ├── Sources/              # Swift source code
│   │   ├── MuttPUApp.swift
│   │   ├── Models/
│   │   ├── Services/
│   │   └── Views/
│   ├── Resources/            # App resources
│   └── Python/               # Bundled Python scripts
├── scripts/                  # Build and utility scripts
│   ├── build.sh             # Build the app
│   ├── run.sh               # Run the app
│   ├── test.sh              # Run tests
│   └── notarize.sh          # Sign and notarize
├── tests/                    # Unit and integration tests
│   ├── test_muttpu.py
│   ├── integration_test.sh
│   └── README.md
├── muttpu.py                 # Original Python CLI tool
├── README.md                 # Original Python tool docs
├── PROJECT_README.md         # This file (project overview)
└── SHARED_TASK_NOTES.md      # Development notes
```

## Features

### Implemented

✅ **OAuth2 Setup Flow**
- First-launch detection
- Interactive setup wizard
- Configuration validation
- Error recovery options

✅ **Mailbox Management**
- List all mailboxes
- Display message counts
- Refresh counts on demand
- Hide non-mail folders (Calendar, Contacts, etc.)

✅ **Export Functionality**
- EML or MBOX format selection
- Year/date range filtering
- Resume interrupted exports
- Incremental backup mode
- Progress tracking
- Queue management

✅ **Settings**
- Default export format
- Default output directory
- Resume behavior configuration
- Non-mail folder visibility
- Auto-refresh intervals (placeholder)

✅ **Activity Logging**
- Real-time activity log
- Filter by type (info, success, warning, error)
- Search logs
- Persistent history

✅ **Queue Window**
- View active and completed exports
- Progress indicators
- Duration tracking
- Quick access to exported files

### In Progress

🚧 **Build System**
- Swift compilation working
- Need Xcode project for proper builds
- Python bundling needs implementation

🚧 **Python Integration**
- Bridge layer complete
- Need bundled Python interpreter
- OAuth2 script needs bundling

### Planned

📋 **Scheduled Exports**
- Automated export jobs
- Recurring schedules
- Background execution

📋 **Enhanced Progress**
- Estimated time remaining
- Detailed export statistics
- Pause/resume controls

## Building the App

### Prerequisites

- macOS 13.0 or later
- Xcode 14+ (for SwiftUI)
- Python 3.x
- Homebrew (for dependencies)

### Dependencies

Install required tools:

```bash
brew install neomutt gpg
```

### Build Steps

1. **Create Xcode Project** (TODO - see SHARED_TASK_NOTES.md)

2. **Build the App**
   ```bash
   ./scripts/build.sh
   ```

3. **Run Tests**
   ```bash
   ./scripts/test.sh
   ```

4. **Launch App**
   ```bash
   ./scripts/run.sh
   ```

5. **Notarize for Distribution** (requires Apple Developer account)
   ```bash
   ./scripts/notarize.sh
   ```

## Development

### Architecture

**SwiftUI Layer**
- `MuttPUApp.swift` - Main app with window management
- `AppState.swift` - Global state using Combine
- Views for each screen (mailboxes, export, settings, etc.)

**Bridge Layer**
- `PythonBridge.swift` - Actor-based async Python execution
- Parses Python script output
- Manages export jobs and progress

**Configuration Layer**
- `ConfigurationManager.swift` - Handles OAuth2 tokens and settings
- Settings persistence (JSON)
- Dependency checking

**Python Backend**
- `muttpu.py` - Original CLI tool
- Handles IMAP/OAuth2 communication
- Email parsing and export logic

### Key Design Decisions

1. **Actor for Python Bridge**: Ensures thread-safe Python execution
2. **No External Swift Dependencies**: Uses only Apple frameworks
3. **Async/Await Throughout**: Modern concurrency for UI responsiveness
4. **State Management**: Single source of truth in AppState
5. **Separate Windows**: Queue and logs in dedicated windows for better UX

### Testing

Run all tests:
```bash
./scripts/test.sh
```

Run specific test suites:
```bash
# Python unit tests
python3 tests/test_muttpu.py

# Integration tests
bash tests/integration_test.sh
```

See `tests/README.md` for detailed testing documentation.

## User Guide

### First Launch

1. Double-click MuttPU.app
2. Setup wizard appears
3. Click "Start Setup"
4. Browser opens for M365 authentication
5. Sign in and authorize
6. Return to app - setup complete

### Daily Use

1. **View Mailboxes**: See all folders with message counts
2. **Export Mailbox**: Select folder, choose format and destination
3. **Track Progress**: Open Queue window to monitor exports
4. **View Logs**: Open Activity Log to see history

### Settings

- **General**: Control folder visibility, auto-refresh
- **Export**: Set default format, output directory, resume behavior
- **Authentication**: View status, re-authorize, reset config
- **Advanced**: Scheduled exports (coming soon)

## Configuration

### Files

- OAuth2 Token: `~/Downloads/muttpu/token.gpg`
- Settings: `~/Downloads/muttpu/settings.json`
- Export State: `<output_dir>/.export_state.json`

### Environment

The app bundles Python and dependencies, requiring no system configuration. However, GPG and NeoMutt must be installed for OAuth2 functionality.

## Distribution

### Notarization

For distribution outside the Mac App Store:

1. Sign with Developer ID certificate
2. Submit for notarization
3. Staple notarization ticket
4. Create DMG

Script automates this: `./scripts/notarize.sh`

### Requirements

- Apple Developer account
- Developer ID Application certificate
- App-specific password for notarization

## Contributing

See `SHARED_TASK_NOTES.md` for current development status and next steps.

### Adding Features

1. Add models to `Models.swift` if needed
2. Update `AppState.swift` for state management
3. Create views in `Views/` directory
4. Wire up in `MuttPUApp.swift`
5. Add tests in `tests/`
6. Update SHARED_TASK_NOTES.md

### Code Style

- Swift: Follow Apple's Swift style guide
- Python: PEP 8
- Comments: Explain why, not what
- Documentation: Keep README files updated

## License

See LICENSE.md

## Credits

Built on the MuttPU Python utility, which uses:
- NeoMutt for OAuth2 implementation
- Thunderbird OAuth2 credentials (public client ID)
- Python standard library (imaplib, email, json)

## Support

For issues, see the activity log in the app or check:
- OAuth2 token validity
- GPG installation
- NeoMutt installation
- Network connectivity to M365

## Version History

- v1.0.0 (In Development) - Initial SwiftUI app with core features
