# MuttPU SwiftUI Bundle - Development Notes

## Current Status

✅ **APP BUILDS, RUNS, AND HAS AN ICON!** The SwiftUI app successfully builds, runs, has settings persistence, bundles mutt_oauth2.py for OAuth2 authentication, includes auto-refresh functionality, and now has a professional app icon.

## What Has Been Done

### SwiftUI Application Structure
- Created complete app architecture in `MuttPU.app/Sources/`
- Main app (`MuttPUApp.swift`) with window management
- Models for app state, mailboxes, export jobs, and logs
- Services for Python bridge and configuration management
- Complete UI views: ContentView, MailboxDetail, Export, Setup, Settings, Queue, Log

### Python Integration
- `PythonBridge.swift` - @MainActor class-based bridge for async Python script execution
- Parses muttpu.py output for mailboxes, counts, and progress
- Handles OAuth2 setup flow
- Progress tracking for long-running exports

### OAuth2 Script Bundling (Latest)
- ✅ Bundle mutt_oauth2.py with the app in Resources/Python/
- ✅ Implemented find_oauth2_script() with multi-location search
- ✅ Search order: bundled → ~/Downloads/muttpu/ → Homebrew installations
- ✅ Updated build.sh to copy mutt_oauth2.py
- ✅ Handles missing __file__ gracefully (uses cwd as fallback)
- ✅ Better error messages showing all searched locations

### Settings Persistence
- ✅ Added settings loading in AppState init - settings are loaded from disk on app startup
- ✅ Added saveSettings() method to AppState
- ✅ Refactored SettingsView to use appState.settings directly (removed local @State copy)
- ✅ Settings auto-save when changed via onChange modifier
- ✅ All settings controls now bind to appState.settings

### Auto-Refresh Timer (Latest)
- ✅ Implemented Task-based auto-refresh timer in AppState
- ✅ Respects user's autoRefreshInterval setting (in minutes)
- ✅ Automatically restarts when settings change
- ✅ Properly cancels on app termination
- ✅ Only runs when app is configured and authenticated
- ✅ Logs refresh events to activity log

### Build Fixes (Previously Completed)
- ✅ Fixed PythonBridge to conform to ObservableObject (changed from actor to @MainActor class)
- ✅ Added AppKit imports to ExportView and SettingsView for NSOpenPanel
- ✅ Made AppSettings conform to Equatable for onChange modifier
- ✅ Removed iOS-specific navigationBarTitleDisplayMode from macOS views
- ✅ Fixed concurrency issues with nonisolated methods
- ✅ App builds successfully with only one minor warning about concurrency

### App Icon (Jan 7, 2026)
- ✅ Created professional envelope icon using SVG
- ✅ Generated .icns file with all required sizes (16x16 to 512x512@2x)
- ✅ Icon automatically bundled during build
- ✅ Added CFBundleIconFile to Info.plist
- ✅ Script: `scripts/generate_icon.py` (can regenerate anytime)

### Build System
- ✅ `scripts/build.sh` - Compiles Swift code, bundles Python script AND icon
- ✅ `scripts/run.sh` - Launches the built app
- ✅ `scripts/generate_icon.py` - Generates app icon from SVG
- `scripts/test.sh` - Runs unit and integration tests
- `scripts/notarize.sh` - Signs and notarizes for distribution

## What Needs to Be Done Next

### Critical - For Standalone Distribution
1. **Python Bundling**: Current approach copies script but uses system Python
   - App currently assumes system Python3 at /usr/bin/python3
   - For true standalone: use py2app, PyInstaller, or bundle Python.framework
   - Alternative: Document Python3 as system requirement (simpler, recommended)

### Important - Testing and Polish
2. **End-to-End Testing with M365 Account**: Requires valid OAuth token
   - Test OAuth2 authentication flow
   - Test mailbox listing and message counting
   - Test export functionality
   - Verify auto-refresh works correctly

3. **First Launch Experience**: Polish setup flow
   - Test OAuth2 setup works from bundled app
   - Test dependency checking (GPG, NeoMutt)
   - Improve error messages for missing dependencies

### Nice to Have - Enhancement Features
4. **Scheduled Exports**: Placeholder exists in settings
   - Design scheduler system
   - Store schedule in config

5. **Enhanced Progress Tracking**: Current implementation is basic
   - Better parsing of Python script output
   - Real-time progress updates during exports

## File Structure

```
muttpu/
├── MuttPU.app/
│   ├── Sources/
│   │   ├── MuttPUApp.swift           # Main app entry
│   │   ├── Models/
│   │   │   ├── AppState.swift        # Global state management
│   │   │   └── Models.swift          # Data models
│   │   ├── Services/
│   │   │   ├── PythonBridge.swift    # Python script interface
│   │   │   └── ConfigurationManager.swift
│   │   └── Views/
│   │       ├── ContentView.swift     # Main window
│   │       ├── MailboxDetailView.swift
│   │       ├── ExportView.swift
│   │       ├── SetupView.swift       # OAuth2 setup
│   │       ├── SettingsView.swift
│   │       ├── QueueView.swift       # Export queue window
│   │       └── LogView.swift         # Activity log window
├── scripts/
│   ├── build.sh        # ✅ Works! Builds the app
│   ├── run.sh          # Launch the app
│   ├── test.sh         # Run tests
│   └── notarize.sh     # Sign and notarize
├── tests/
│   ├── test_muttpu.py          # Python unit tests
│   ├── integration_test.sh     # Integration tests
│   └── README.md
├── muttpu.py           # Original Python script
└── dist/MuttPU.app     # ✅ Built app bundle
```

## Quick Start for Next Developer

### To Build
```bash
./scripts/build.sh
# ✅ This now works!
```

### To Run
```bash
./scripts/run.sh
# or: open dist/MuttPU.app
```

### To Test
```bash
./scripts/test.sh
```

## Important Notes

1. **Build Success**: App now builds successfully via swiftc
2. **System Requirements**: Python3, GPG, and NeoMutt needed at runtime
3. **Configuration Location**: `~/Downloads/muttpu/` (matches original script)
4. **First Launch**: App will detect missing token and show setup wizard

## Recent Testing (Jan 7, 2026 - Latest)

- ✅ App builds successfully via `./scripts/build.sh`
- ✅ App launches and runs via `./scripts/run.sh`
- ✅ App process runs without crashes
- ✅ App icon created and bundled successfully
- ✅ Icon generation script (`scripts/generate_icon.py`) working
- ✅ All Python unit tests passing (8/8 tests)
- ✅ All code committed to git (5 commits)
- ⚠️ OAuth token authentication test requires fresh token (existing token expired)
- ✅ Auto-refresh feature implemented and compiles successfully

## Known Minor Issues

1. One warning about concurrency in PythonBridge (not critical, will be error in Swift 6)
2. Python not bundled - relies on system Python3 (acceptable for initial release)
3. Requires valid OAuth token for end-to-end testing

## Next Immediate Steps

1. **Test with fresh M365 credentials** - Full OAuth2 flow from scratch
   - Current token is expired (expected behavior)
   - Need to run OAuth2 setup through the app UI
   - Verify mailbox listing and message counting work
2. **Test auto-refresh functionality** - Verify timer works with valid token
3. **Test export functionality** - Try exporting a mailbox to verify end-to-end flow
4. **Decide on Python bundling strategy**:
   - Option A: Document Python3 as system requirement (simpler)
   - Option B: Bundle Python.framework for true standalone distribution
5. **Code signing and notarization** - Prepare for distribution
   - Update notarize.sh with valid Developer ID
   - Test notarization workflow

## Resources

- Original Python script: `muttpu.py`
- Build output: `dist/MuttPU.app`
- SwiftUI docs: https://developer.apple.com/documentation/swiftui
