# Xcode Troubleshooting Guide

Quick solutions to common Xcode issues when building Dictate.

---

## 🔴 Build Errors

### Error: "No such module 'MLX'"

**Cause:** Package dependencies not properly resolved or indexed.

**Solution 1 - Reset Package Caches:**
```bash
# In Xcode menu:
File → Packages → Reset Package Caches
File → Packages → Resolve Package Versions

# Wait for indexing to complete (watch progress bar in toolbar)
```

**Solution 2 - Clear Derived Data:**
```bash
# Close Xcode first, then:
rm -rf ~/Library/Developer/Xcode/DerivedData

# Reopen project
open Package.swift
```

**Solution 3 - Nuclear Option:**
```bash
# Close Xcode
rm -rf .build
rm -rf ~/Library/Developer/Xcode/DerivedData
rm -rf ~/Library/Caches/org.swift.swiftpm

# Reopen
open Package.swift
```

---

### Error: "Cannot find 'Logger' in scope"

**Cause:** Missing import statement or circular dependency.

**Solution:**
1. Check that `Logger+App.swift` is in the project
2. Make sure `import OSLog` is at the top of the file
3. Clean build folder: **Product → Clean Build Folder** (⇧⌘K)

---

### Error: "Type 'ModelManager' does not conform to protocol 'Sendable'"

**Cause:** Swift 6 strict concurrency checking.

**Solution:**
This is expected! The file uses `@unchecked Sendable` for `ModelDownloadDelegate`. Make sure:
- `ModelManager` is marked with `@MainActor`
- Delegate is marked `@unchecked Sendable`

Already correct in your code ✅

---

### Error: "Failed to produce diagnostic for expression"

**Cause:** Complex expression that confuses type inference.

**Solution:**
1. Product → Clean Build Folder (⇧⌘K)
2. Restart Xcode
3. If persists, break complex expressions into multiple lines with explicit types

---

### Error: "Command SwiftCompile failed with a nonzero exit code"

**Cause:** Generic compilation failure.

**Solution:**
1. Look for the actual error above this message (scroll up in build log)
2. Click the error in Issue Navigator (⌘5) to see details
3. Try: Product → Clean Build Folder
4. Try: File → Packages → Reset Package Caches

---

## 🟡 Runtime Issues

### App builds but doesn't appear in menu bar

**Cause:** Info.plist issue or app crashed on launch.

**Solution:**
1. Check Console.app for crash logs:
   ```bash
   # Open Console.app, search for "Dictate"
   ```

2. Verify Info.plist has:
   ```xml
   <key>LSUIElement</key>
   <true/>
   ```

3. Check that `DictateApp.swift` has `@main` attribute

4. Run from Xcode to see console output

---

### Error: "The operation couldn't be completed. (OSStatus error -50.)"

**Cause:** Audio framework initialization issue.

**Solution:**
1. Check microphone permissions:
   - System Settings → Privacy & Security → Microphone
   - Enable for "Dictate"
   
2. Verify Info.plist has:
   ```xml
   <key>NSMicrophoneUsageDescription</key>
   <string>Dictate needs access to your microphone...</string>
   ```

3. Restart the app

---

### Hotkey (⌥R) doesn't work

**Cause:** Accessibility permissions not granted.

**Solution:**
1. System Settings → Privacy & Security → Accessibility
2. Add Dictate to the list
3. Enable the checkbox
4. Restart the app

**Alternative:**
- Click the menu bar icon and use "Start Recording" button instead

---

### LLM model download fails

**Cause:** Network issue or insufficient disk space.

**Solution:**
1. Check internet connection
2. Check available disk space (models are 0.7-2.2 GB each)
3. Try downloading again
4. Check Console.app for detailed error:
   ```bash
   log stream --predicate 'subsystem == "com.dictate.app"' --level debug
   ```

---

### Model loads but text styling fails

**Cause:** Model incompatibility or corrupted download.

**Solution:**
1. Delete the model:
   - Settings → Models → Click "Delete"
   
2. Re-download the model

3. Check model files exist:
   ```bash
   ls -la ~/Library/Application\ Support/Dictate/Models/
   ```

4. Should contain folders with:
   - `config.json`
   - `tokenizer.json`
   - `tokenizer_config.json`
   - `model.safetensors`

---

## 🔵 Performance Issues

### App is slow / high CPU usage

**Cause:** Running in Debug mode.

**Solution:**
1. Edit Scheme → Run → Info → Build Configuration → **Release**
2. Or build release version:
   ```bash
   make app
   .build/release-app/Dictate.app
   ```

**Expected performance:**
- Debug: ~15-20 sec to style 500 words
- Release: ~2-3 sec to style 500 words

---

### Memory usage keeps growing

**Cause:** Potential memory leak.

**Solution:**
1. Profile with Instruments:
   - Product → Profile (⌘I)
   - Choose "Leaks" template
   - Use the app normally
   - Check for red leak indicators

2. Report issue with leak trace

---

### Build takes forever (>10 minutes)

**Cause:** Clean build of all dependencies.

**Solution:**
1. First build always takes longer (3-5 min is normal)
2. Subsequent builds should be faster (30 sec - 2 min)
3. Use incremental builds (Xcode default)
4. Don't clean unless necessary
5. Close other apps to free RAM

---

## 🟢 Xcode UI Issues

### "Cannot open file" / File navigator shows files in red

**Cause:** Files moved or deleted outside Xcode.

**Solution:**
1. Right-click red file → Delete
2. Right-click project in navigator → Add Files to "Dictate"
3. Select the file from its actual location

---

### Scheme is missing or shows wrong target

**Cause:** Scheme configuration issue.

**Solution:**
1. Product → Scheme → Manage Schemes
2. If "Dictate" scheme missing:
   - Click "+" to add new scheme
   - Choose "Dictate" target
   - Click "Autocreate Schemes Now" button

---

### Can't find "Run" or "Build" buttons

**Cause:** Toolbar customization.

**Solution:**
1. View → Customize Toolbar
2. Drag "Build and Run" button to toolbar
3. Or use keyboard shortcuts:
   - ⌘B to build
   - ⌘R to run

---

### Xcode freezes during indexing

**Cause:** Large dependency tree or low memory.

**Solution:**
1. Wait patiently (first index can take 5 min)
2. If truly frozen (>10 min):
   - Force quit Xcode
   - Delete derived data
   - Reopen project
   - Let it finish indexing without doing anything else

---

## 🟣 Package Management Issues

### Error: "Package resolution failed"

**Cause:** Network issue or incompatible versions.

**Solution:**
```bash
# Check Package.swift has correct URLs:
.package(url: "https://github.com/sindresorhus/KeyboardShortcuts", from: "2.0.0"),
.package(url: "https://github.com/ml-explore/mlx-swift", from: "0.30.3"),
.package(url: "https://github.com/ml-explore/mlx-swift-lm", from: "2.30.3"),

# Try manual resolution:
swift package resolve

# If fails, check network:
ping github.com
```

---

### Error: "Package graph is not resolvable"

**Cause:** Dependency version conflicts.

**Solution:**
1. File → Packages → Update to Latest Package Versions
2. If that fails, check Package.swift for conflicting requirements
3. Try pinning to specific versions instead of ranges

---

### "Package.resolved" conflicts in Git

**Cause:** Different developers resolving to different versions.

**Solution:**
```bash
# Delete and regenerate:
rm Package.resolved
swift package resolve

# Commit the new Package.resolved
git add Package.resolved
git commit -m "Update Package.resolved"
```

---

## 🔧 Development Tools

### Can't set breakpoints

**Cause:** Running Release build or compiler optimization.

**Solution:**
1. Edit Scheme → Run → Info → Build Configuration → **Debug**
2. Edit Scheme → Run → Options → Debug Executable → ✓ Checked

---

### Console logs not appearing

**Cause:** Filter settings or wrong logging category.

**Solution:**
1. Check console filter dropdown (bottom-right) is not filtering out messages
2. Ensure `Logger.app.info()` is being called (not just `.debug()` in Release)
3. View in Terminal instead:
   ```bash
   log stream --predicate 'subsystem == "com.dictate.app"'
   ```

---

### SwiftUI previews don't work

**Cause:** Menu bar app structure or missing preview code.

**Solution:**
Previews don't work well for menu bar apps. Instead:
- Run the full app (⌘R)
- Or create separate preview-friendly views for testing

---

## 🆘 Still Having Issues?

### Get Help
1. **Check full build log:**
   - View → Navigators → Reports (⌘9)
   - Click latest build
   - Read full output

2. **Enable verbose logging:**
   - Edit Scheme → Run → Arguments
   - Add: `-com.apple.CoreData.SQLDebug 1` (if using Core Data)

3. **Check system logs:**
   ```bash
   log show --predicate 'subsystem == "com.dictate.app"' --last 1h
   ```

4. **Verify system requirements:**
   ```bash
   # Should be 15.x or later
   sw_vers -productVersion
   
   # Should be arm64
   uname -m
   
   # Should show Xcode 16+
   xcodebuild -version
   ```

5. **Create minimal reproducible example:**
   - Create new SwiftUI Mac app
   - Add just MLX dependencies
   - See if basic import works

---

## 📞 Getting Support

When asking for help, include:

```bash
# System info
sw_vers -productVersion
uname -m
xcodebuild -version

# Swift version
swift --version

# Package status
swift package describe

# Full build log
xcodebuild clean build 2>&1 | tee build.log
# Then share build.log
```

**Where to get help:**
- GitHub Issues: (your repo issues page)
- MLX Swift: https://github.com/ml-explore/mlx-swift
- Swift Forums: https://forums.swift.org

---

## ✅ Prevention Checklist

Avoid issues by:
- [ ] Not deleting `.build` unnecessarily
- [ ] Letting Xcode finish indexing before building
- [ ] Running `swift package resolve` after pulling changes
- [ ] Keeping Xcode and macOS up to date
- [ ] Not manually editing Package.resolved
- [ ] Committing Package.resolved to version control
- [ ] Using consistent Xcode version across team

---

**Last Updated:** March 24, 2026

**Need more help?** Check:
- `XCODE_SETUP.md` - Initial setup guide
- `BUILD_WORKFLOWS.md` - Different ways to build
- `XCODE_CHECKLIST.md` - Configuration verification
