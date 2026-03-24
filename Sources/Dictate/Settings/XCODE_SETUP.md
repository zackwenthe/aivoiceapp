# Xcode Project Setup Guide for Dictate

This guide will help you set up and run the Dictate app in Xcode.

## Prerequisites

- macOS 15 (Sequoia) or later (targets macOS 26/Tahoe at runtime)
- Xcode 16 or later
- Apple Silicon Mac (M1/M2/M3/M4)
- Command Line Tools installed

## Quick Setup (5 minutes)

### 1. Open the Project in Xcode

```bash
# From the project directory
open Package.swift
```

This opens the Swift Package in Xcode. Xcode will automatically:
- Resolve package dependencies (MLX, MLX-LM, KeyboardShortcuts)
- Index the project
- Set up build configurations

**⏱ First time opening may take 2-3 minutes to resolve dependencies.**

### 2. Configure the Scheme

1. Click the scheme selector in the toolbar (should show "Dictate")
2. Click **Edit Scheme...**
3. Under **Run** → **Info**:
   - Executable: Should be "Dictate" (auto-selected)
4. Under **Run** → **Options**:
   - Check "Use the GPU Frame Capture" if you want to debug Metal/GPU issues
5. Click **Close**

### 3. Build and Run

Press **⌘R** (Command + R) or click the **Play** button in Xcode.

**On first launch:**
- macOS will prompt for **microphone access** — click **OK**
- The app icon (waveform) appears in your menu bar
- Onboarding window may appear if it's your first time

### 4. Test the App

1. Press **⌥R** (Option + R) to start recording
2. Speak something
3. Press **⌥R** again to stop
4. Text is transcribed and copied to clipboard
5. Paste with **⌘V**

---

## Troubleshooting

### Issue: "Failed to resolve dependencies"

**Solution:** Update package dependencies:
1. File → Packages → Reset Package Caches
2. File → Packages → Update to Latest Package Versions

### Issue: Build fails with "No such module 'MLX'"

**Solution:** 
1. Close Xcode
2. Delete derived data:
   ```bash
   rm -rf ~/Library/Developer/Xcode/DerivedData
   ```
3. Reopen `Package.swift` in Xcode
4. Wait for indexing to complete

### Issue: "Microphone access denied"

**Solution:**
1. System Settings → Privacy & Security → Microphone
2. Enable access for "Dictate"
3. Restart the app

### Issue: App doesn't appear in menu bar

**Solution:** Check that `LSUIElement` is set to `true` in Info.plist (this makes it a menu bar app without a Dock icon).

### Issue: Hotkey (⌥R) doesn't work

**Solution:**
1. System Settings → Privacy & Security → Accessibility
2. Add Dictate to the allowed apps
3. Restart the app

---

## Project Structure in Xcode

When you open the project, you'll see:

```
Dictate/
├── App/
│   ├── DictateApp.swift          — Main app entry point (@main)
│   └── AppState.swift             — Observable app state
├── Audio/
│   ├── AudioRecorder.swift
│   └── AudioPermissions.swift
├── Transcription/
│   ├── TranscriptionEngine.swift
│   └── SpeechAnalyzerEngine.swift — Uses Speech framework
├── Styling/
│   ├── TextStyle.swift
│   ├── StylePrompts.swift
│   └── TextStyler.swift           — MLX LLM integration
├── Models/
│   ├── ModelManager.swift         — Downloads & manages LLM models
│   └── ModelInfo.swift
├── Settings/
│   ├── SettingsView.swift
│   ├── ModelSettingsView.swift
│   └── StyleSettingsView.swift
├── Views/
│   ├── MenuBarView.swift          — Main menu bar UI
│   ├── RecordingOverlay.swift     — Recording status window
│   └── OnboardingView.swift
├── Output/
│   ├── ClipboardManager.swift
│   └── MarkdownFileWriter.swift
└── Utilities/
    ├── Errors.swift
    ├── Logger+App.swift
    └── UserDefaults+Keys.swift
```

---

## Advanced: Xcode Scheme Configuration

### Debug Configuration (Default)

For development with fast iteration:
- Compiler optimizations: `-Onone`
- Debug symbols: Enabled
- Assertions: Enabled

### Release Configuration

For testing performance:
1. Product → Scheme → Edit Scheme
2. Run → Build Configuration → **Release**
3. This enables full optimizations

**Note:** MLX models run significantly faster in Release mode.

---

## Running from Terminal (Alternative)

If you prefer terminal builds:

```bash
# Debug build and run
swift run

# Release build (faster LLM inference)
swift build -c release
.build/release/Dictate
```

---

## Creating a Distributable App

### Option 1: Using Makefile (Recommended)

```bash
# Create .app bundle
make app

# The app is at: .build/release-app/Dictate.app
open .build/release-app/Dictate.app
```

### Option 2: Using Xcode Archive

1. Product → Archive
2. Window → Organizer
3. Select your archive → **Distribute App**
4. Choose **Copy App**
5. Export to a folder

---

## Configuring App Icon (Optional)

1. Create an `.icns` file or use an asset catalog
2. Add to `Resources/Assets.xcassets/AppIcon.appiconset/`
3. Add to Info.plist:
   ```xml
   <key>CFBundleIconFile</key>
   <string>AppIcon</string>
   ```

---

## Code Signing for Distribution

### 1. Set Your Team

1. Select the Dictate target in Xcode
2. Signing & Capabilities tab
3. Select your **Team** from the dropdown
4. Xcode will auto-generate a bundle identifier

### 2. Verify Signing

```bash
codesign --verify --verbose .build/release-app/Dictate.app
```

### 3. Notarize (For Distribution)

```bash
# Store credentials (one-time)
xcrun notarytool store-credentials "notary-profile" \
  --apple-id "your@email.com" \
  --team-id "YOURTEAMID" \
  --password "app-specific-password"

# Notarize
make notarize
```

---

## Development Tips

### 1. Enable More Logging

Add launch argument to see verbose logs:
1. Edit Scheme → Run → Arguments
2. Add: `-com.dictate.app.logging DEBUG`

### 2. Reset User Defaults

```bash
defaults delete com.dictate.app
```

### 3. Monitor Console Logs

```bash
log stream --predicate 'subsystem == "com.dictate.app"' --level debug
```

### 4. Profile Performance

1. Product → Profile (⌘I)
2. Choose **Time Profiler** to analyze LLM performance
3. Choose **Allocations** to check memory usage

---

## Common Build Settings

These are configured in `Package.swift`:

| Setting | Value |
|---------|-------|
| Minimum macOS | 15.0 (Sequoia) |
| Swift Version | 6.0 |
| Target Architecture | arm64 (Apple Silicon only) |
| Build Configuration | Debug / Release |

---

## Need Help?

- Check the [README.md](README.md) for usage info
- Check [TESTING.md](TESTING.md) for test guidance
- File an issue on GitHub if you encounter problems

---

## Next Steps

Once the app is running:

1. **Download an LLM model**:
   - Click menu bar icon → Settings → Models
   - Download "Llama 3.2 1B" (fastest, ~700 MB)
   
2. **Configure your style**:
   - Settings → Style tab
   - Choose your default (e.g., "Simplify")
   
3. **Set up markdown export** (optional):
   - Settings → General
   - Enable "Save markdown files"
   - Choose output folder

4. **Customize hotkey** (optional):
   - Settings → General
   - Click on current hotkey and press new combination

---

Happy dictating! 🎙️
