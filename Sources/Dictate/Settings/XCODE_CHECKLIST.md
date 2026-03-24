# Xcode Configuration Checklist

Use this checklist to ensure your Dictate app is properly configured in Xcode.

## ✅ Initial Setup

- [ ] Xcode 16+ installed
- [ ] macOS 15+ running
- [ ] Apple Silicon Mac (M1/M2/M3/M4)
- [ ] Project opened via `open Package.swift`

## ✅ Dependencies Resolved

- [ ] KeyboardShortcuts package fetched
- [ ] mlx-swift package fetched  
- [ ] mlx-swift-lm package fetched
- [ ] All packages show green checkmarks in Project Navigator

**To check:** File → Packages → Resolve Package Versions

## ✅ Build Configuration

- [ ] Scheme is set to "Dictate"
- [ ] Destination is set to "My Mac"
- [ ] Build configuration is "Debug" (for development)

**To check:** Click scheme selector in toolbar

## ✅ Info.plist Configuration

Check that `Sources/Dictate/Info.plist` exists with:

- [ ] `CFBundleIdentifier`: `com.dictate.app`
- [ ] `LSUIElement`: `true` (menu bar app, no Dock icon)
- [ ] `NSMicrophoneUsageDescription`: Present and descriptive
- [ ] `LSMinimumSystemVersion`: `15.0`
- [ ] `CFBundleShortVersionString`: `1.0.0`

**Location:** `Sources/Dictate/Info.plist`

## ✅ System Permissions

After first launch, verify these in **System Settings**:

- [ ] Privacy & Security → Microphone → Dictate ✓
- [ ] Privacy & Security → Accessibility → Dictate ✓ (for global hotkey)

## ✅ File Structure

Verify these directories exist:

```
Project Root/
├── Sources/
│   └── Dictate/
│       ├── Info.plist ✓
│       ├── DictateApp.swift ✓
│       ├── ModelManager.swift ✓
│       └── [other source files]
├── Tests/
│   └── DictateTests/
├── Resources/ (optional)
├── Package.swift ✓
├── Makefile ✓
└── README.md ✓
```

## ✅ Build & Run

- [ ] Project builds without errors (⌘B)
- [ ] Project runs successfully (⌘R)
- [ ] App icon appears in menu bar
- [ ] Clicking icon shows menu with options
- [ ] No crash logs in Console.app

## ✅ Functional Tests

### Basic Functionality
- [ ] Press ⌥R → recording starts (red mic icon in menu bar)
- [ ] Press ⌥R again → recording stops
- [ ] Text is copied to clipboard
- [ ] Can paste with ⌘V

### Settings Access
- [ ] Menu → Settings opens settings window
- [ ] General tab accessible
- [ ] Style tab accessible  
- [ ] Models tab accessible

### Model Download (Optional)
- [ ] Settings → Models shows available models
- [ ] Can click "Download" on a model
- [ ] Download progress shows
- [ ] Downloaded model can be selected

## ✅ Troubleshooting Completed

If you had issues, verify you've completed these fixes:

- [ ] Reset package caches: File → Packages → Reset Package Caches
- [ ] Cleared DerivedData: `rm -rf ~/Library/Developer/Xcode/DerivedData`
- [ ] Restarted Xcode
- [ ] Verified Xcode Command Line Tools: `xcode-select -p`

## ✅ Optional: Code Signing

For distribution to others:

- [ ] Apple Developer account active
- [ ] Team selected in Signing & Capabilities
- [ ] Provisioning profile valid
- [ ] App builds and runs with code signature
- [ ] Verified signature: `codesign --verify --verbose [app path]`

## ✅ Optional: Performance Testing

- [ ] Built in Release mode: Edit Scheme → Run → Release
- [ ] LLM model loaded successfully
- [ ] Text styling completes in reasonable time
- [ ] No memory leaks (Product → Profile → Leaks)

---

## Quick Reference Commands

```bash
# Open in Xcode
open Package.swift

# Clean build folder
rm -rf .build

# Reset Xcode derived data
rm -rf ~/Library/Developer/Xcode/DerivedData

# Build from terminal (debug)
swift build

# Run from terminal (debug)
swift run

# Build release version
swift build -c release

# Create .app bundle
make app

# View logs
log stream --predicate 'subsystem == "com.dictate.app"' --level debug
```

---

## Support

If something isn't working:

1. Check the checkbox items above
2. Review `XCODE_SETUP.md` for detailed instructions
3. Check Console.app for crash logs
4. Review the error message in Xcode's Issue Navigator
5. File an issue on GitHub with:
   - Xcode version
   - macOS version
   - Error message
   - Steps to reproduce

---

**Last Updated:** March 24, 2026
