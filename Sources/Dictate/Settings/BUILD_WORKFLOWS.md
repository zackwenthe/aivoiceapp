# Build & Run Workflows for Dictate

This document explains the different ways to build and run your Dictate app.

---

## 🎯 Quick Start (Recommended for Development)

```bash
open Package.swift
# Press ⌘R in Xcode
```

**Time:** ~30 seconds (after dependencies cached)
**Use case:** Daily development, debugging, testing

---

## 📋 Workflow Comparison

| Method | Speed | Use Case | Output |
|--------|-------|----------|--------|
| **Xcode Run** | ⚡️ Fastest | Development | Running app (debug mode) |
| **swift run** | ⚡️⚡️ Fast | Terminal testing | Running app (debug mode) |
| **swift build** | ⚡️⚡️ Fast | CI/testing | Binary in `.build/debug/` |
| **make app** | ⚡️⚡️⚡️ Medium | Local install | `Dictate.app` bundle |
| **make dmg** | ⚡️⚡️⚡️⚡️ Slow | Distribution | Installer DMG |
| **Xcode Archive** | ⚡️⚡️⚡️⚡️⚡️ Slowest | App Store / Distribution | Signed `.app` |

---

## 🔨 Detailed Workflows

### 1. Development in Xcode (Daily Work)

```
┌─────────────────┐
│ Open Package.swift │
└────────┬─────────┘
         │
         ▼
┌─────────────────┐
│ Xcode indexes   │
│ and resolves    │
│ dependencies    │
└────────┬─────────┘
         │
         ▼
┌─────────────────┐
│ Press ⌘R        │
│ (Product → Run) │
└────────┬─────────┘
         │
         ▼
┌─────────────────┐
│ App launches    │
│ Icon in menu bar│
└─────────────────┘
```

**Advantages:**
- Fast iteration (incremental compilation)
- Full debugging support (breakpoints, variables, etc.)
- Live view of console logs
- Instruments integration for profiling

**When to use:**
- Writing new features
- Fixing bugs
- Testing changes

---

### 2. Terminal Quick Test

```bash
# One-time: resolve dependencies
swift package resolve

# Build and run (debug)
swift run

# Or just build
swift build

# Run the binary directly
.build/debug/Dictate
```

**Build Process:**
```
Package.swift
     │
     ├─ Dependencies resolved (cached)
     │
     ├─ Swift compiler builds targets
     │
     └─ Executable: .build/debug/Dictate
```

**When to use:**
- Quick command-line testing
- CI/CD pipelines
- Automated testing
- No need for Xcode UI

---

### 3. Release Build (Performance Testing)

```bash
# Build optimized binary
swift build -c release

# Run it
.build/release/Dictate
```

**Differences from Debug:**
| Aspect | Debug | Release |
|--------|-------|---------|
| Compilation time | Fast | Slower |
| Runtime performance | Slow | Fast (10-100x) |
| Binary size | Large | Smaller |
| Assertions | Enabled | Disabled |
| Optimizations | None | Full |

**When to use:**
- Testing LLM performance (much faster)
- Benchmarking
- Before creating final distribution

---

### 4. Create App Bundle (Local Install)

```bash
make app
```

**Process:**
```
┌────────────────┐
│ make app       │
└───────┬────────┘
        │
        ├─ Runs: xcodebuild -c Release
        │
        ├─ Copies binary to .app/Contents/MacOS/
        │
        ├─ Copies Info.plist to .app/Contents/
        │
        └─ Output: .build/release-app/Dictate.app
```

**Result:**
```
.build/release-app/
└── Dictate.app/
    └── Contents/
        ├── Info.plist
        ├── MacOS/
        │   └── Dictate (executable)
        └── Resources/ (if any)
```

**When to use:**
- Installing on your Mac permanently
- Testing as a real app (not from Xcode)
- Sharing with others (unsigned)

**To install:**
```bash
cp -r .build/release-app/Dictate.app /Applications/
```

---

### 5. Create DMG Installer

```bash
make dmg
```

**Process:**
```
┌────────────────┐
│ make dmg       │
└───────┬────────┘
        │
        ├─ Runs: make app (creates .app)
        │
        ├─ Creates staging folder with:
        │  ├─ Dictate.app
        │  └─ Symlink to /Applications
        │
        ├─ Runs: hdiutil create
        │
        └─ Output: .build/release-app/Dictate-1.0.0.dmg
```

**Result:** A disk image users can:
1. Open
2. Drag "Dictate" to "Applications"
3. Eject

**When to use:**
- Distributing to friends/colleagues
- Posting on GitHub releases
- Professional-looking installer

---

### 6. Code Sign & Notarize (Distribution)

```bash
# Edit Makefile first with your Developer ID
# Then:
make notarize
```

**Process:**
```
┌────────────────┐
│ make notarize  │
└───────┬────────┘
        │
        ├─ Runs: make app
        │
        ├─ Code signs with: codesign --sign "Developer ID"
        │
        ├─ Creates DMG
        │
        ├─ Uploads to Apple: xcrun notarytool submit
        │
        ├─ Waits for approval (~5-10 min)
        │
        ├─ Staples ticket to DMG: xcrun stapler
        │
        └─ Output: Notarized DMG (no Gatekeeper warnings)
```

**When to use:**
- Public distribution
- Avoid "unidentified developer" warnings
- Professional releases

**Requirements:**
- Apple Developer account ($99/year)
- Developer ID certificate
- App-specific password for notarization

---

## 🔍 Comparison: Debug vs Release

### Example: LLM Text Styling Performance

| Build Type | Time to Style 500 words | Memory Usage |
|------------|------------------------|--------------|
| Debug | ~15-20 seconds | ~2.5 GB |
| Release | ~2-3 seconds | ~1.8 GB |

**Why such a difference?**
- Release builds enable Swift compiler optimizations (`-O`)
- Metal shader compilation is optimized
- Assertions and runtime checks removed
- Better CPU instruction scheduling

---

## 🎯 Recommended Workflow

### Daily Development
```bash
# Open once
open Package.swift

# Work in Xcode
# Press ⌘R to test changes
# Use breakpoints, debugger as needed
```

### Before Committing Code
```bash
# Test release build performance
swift build -c release
.build/release/Dictate

# Run tests
swift test
```

### Creating a Release
```bash
# Build app bundle
make app

# Test it works
open .build/release-app/Dictate.app

# Create DMG
make dmg

# (Optional) Sign and notarize
make notarize
```

---

## 🐛 Troubleshooting Build Issues

### "Failed to resolve dependencies"
```bash
swift package resolve
# If that fails:
swift package reset
swift package resolve
```

### "No such module 'MLX'"
```bash
# Clear everything and start fresh
rm -rf .build
rm -rf ~/Library/Developer/Xcode/DerivedData
open Package.swift  # Let Xcode re-index
```

### "Cannot find Dictate.app"
```bash
# Make sure build completed
ls -la .build/release-app/

# If empty, check for build errors:
make app 2>&1 | tee build.log
```

### Slow builds in Xcode
```bash
# Clear derived data
rm -rf ~/Library/Developer/Xcode/DerivedData

# Enable faster Swift compilation (Xcode 15+)
# Build Settings → Search "compilation mode" → Set to "Incremental"
```

---

## 📊 Build Time Expectations

On M1 MacBook Pro (8-core):

| Task | First Time | Subsequent (cached) |
|------|-----------|---------------------|
| `swift package resolve` | 2-3 min | 5 sec |
| `swift build` (debug) | 1-2 min | 10-30 sec |
| `swift build -c release` | 3-5 min | 1-2 min |
| `make app` | 4-6 min | 2-3 min |
| Xcode first launch | 3-4 min | Instant |
| Xcode incremental build | N/A | 5-15 sec |

**Tip:** Keep Xcode open for fastest iteration! Incremental builds are much faster.

---

## 🚀 Performance Tips

### Faster Development Builds
1. Use Xcode (incremental compilation)
2. Keep the app running (no need to rebuild for UI changes if using SwiftUI previews)
3. Use debug build configuration

### Faster Release Builds
1. Use `make app` instead of Xcode Archive
2. Build on Apple Silicon Mac
3. Close other apps to free up RAM
4. Use `-j` flag: `swift build -c release -j 8` (8 parallel jobs)

### Faster Package Resolution
1. Use local package cache (automatic)
2. Don't delete `.build` folder unnecessarily
3. Pin dependency versions in `Package.swift`

---

## 📝 Summary

**For development:** Use Xcode with ⌘R
**For testing performance:** Use `swift build -c release`  
**For local install:** Use `make app`
**For distribution:** Use `make dmg` or `make notarize`

---

**Questions?** Check `XCODE_SETUP.md` for detailed configuration help.
