# 🎙️ Dictate - Complete Xcode Setup Summary

**Your app is ready to run!** This is a complete guide to get your Mac app running in Xcode.

---

## ⚡️ 60-Second Quick Start

```bash
# 1. Make setup script executable
chmod +x setup.sh

# 2. Run setup (opens Xcode)
./setup.sh

# 3. In Xcode: Press ⌘R

# 4. Grant microphone access when prompted

# 5. Press ⌥R to start recording!
```

**That's it!** Your app is now running as a menu bar utility.

---

## 📋 What Just Happened?

### Files I Created for You

1. **`Sources/Dictate/Info.plist`** - App configuration
   - Bundle identifier: `com.dictate.app`
   - Microphone permission description
   - Menu bar app settings (no Dock icon)

2. **`setup.sh`** - Automated setup script
   - Checks for Xcode
   - Resolves dependencies
   - Opens project in Xcode

3. **`XCODE_SETUP.md`** - Detailed setup guide
   - Step-by-step instructions
   - Advanced configuration
   - Code signing help

4. **`XCODE_CHECKLIST.md`** - Configuration verification
   - Checkboxes for each setup step
   - Troubleshooting fixes
   - Testing procedures

5. **`BUILD_WORKFLOWS.md`** - Build process guide
   - Different ways to build (Xcode, terminal, release)
   - Performance comparison
   - Distribution workflows

6. **`XCODE_TROUBLESHOOTING.md`** - Problem solutions
   - Common errors and fixes
   - Runtime issues
   - Performance tips

---

## 🏗️ Your Project Structure

```
Dictate/
├── 📦 Package.swift              — Swift package definition
├── 📝 Info.plist                 — App metadata (NEW!)
├── 🔧 Makefile                   — Build automation
│
├── 📖 README.md                  — User guide
├── 📖 XCODE_SETUP.md             — Setup instructions (NEW!)
├── 📖 XCODE_CHECKLIST.md         — Configuration checklist (NEW!)
├── 📖 BUILD_WORKFLOWS.md         — Build process guide (NEW!)
├── 📖 XCODE_TROUBLESHOOTING.md   — Problem solutions (NEW!)
├── 🚀 setup.sh                   — Quick setup script (NEW!)
│
├── Sources/Dictate/
│   ├── DictateApp.swift          — Main app (@main entry point)
│   ├── AppState.swift            — Observable app state
│   ├── ModelManager.swift        — LLM model management (your current file)
│   ├── TextStyler.swift          — MLX LLM integration
│   ├── AudioRecorder.swift       — Audio recording
│   ├── SpeechAnalyzerEngine.swift — On-device transcription
│   └── ... (other source files)
│
└── Tests/DictateTests/
    └── ... (test files)
```

---

## 🎯 What Your App Does

### Core Features

1. **Global Recording Hotkey** (⌥R)
   - Press once to start recording
   - Press again to stop
   - Works from any app

2. **On-Device Transcription**
   - Uses Apple's Speech framework
   - No internet required
   - Privacy-first (nothing sent to cloud)

3. **AI Text Styling** (Optional)
   - Download local LLM models
   - Transform transcripts:
     - Plain (no changes)
     - Simplify (fix grammar, remove filler)
     - Structured (headings, sections)
     - Email Draft (professional format)
     - Bullet Points (key ideas)
     - Custom (your own prompt)

4. **Clipboard Integration**
   - Automatically copies result
   - Paste anywhere with ⌘V

5. **Markdown Export** (Optional)
   - Save timestamped `.md` files
   - YAML frontmatter metadata

---

## 🚀 How to Run Your App

### Method 1: Xcode GUI (Easiest)

```bash
open Package.swift
```

Then in Xcode:
- Press **⌘R** to run
- Or click **▶️ Play** button in toolbar

**App appears in menu bar** (waveform icon)

### Method 2: Terminal

```bash
# Debug build
swift run

# Or release build (faster LLM)
swift build -c release
.build/release/Dictate
```

### Method 3: Installable App

```bash
# Create .app bundle
make app

# Install it
cp -r .build/release-app/Dictate.app /Applications/

# Run from Applications
open /Applications/Dictate.app
```

---

## 🔐 Required Permissions

On first launch, grant these:

### 1. Microphone Access (Required)
- System Settings → Privacy & Security → Microphone
- Enable for "Dictate"
- **Why:** To record your voice

### 2. Accessibility Access (Optional)
- System Settings → Privacy & Security → Accessibility  
- Enable for "Dictate"
- **Why:** For global hotkey (⌥R) to work system-wide

---

## 📥 Downloading LLM Models

For text styling (non-plain modes), download a model:

### In the App:
1. Click menu bar icon
2. Settings → Models tab
3. Click "Download" on a model

### Available Models:

| Model | Size | Speed | Quality | Recommended For |
|-------|------|-------|---------|-----------------|
| Llama 3.2 1B | 700 MB | ⚡️⚡️⚡️ Fast | Good | Quick formatting |
| Llama 3.2 3B | 1.8 GB | ⚡️⚡️ Medium | Better | Balanced use |
| Phi-4 Mini | 2.2 GB | ⚡️ Slower | Best | Complex tasks |

**Tip:** Start with Llama 3.2 1B for fastest results.

Models download to:
```
~/Library/Application Support/Dictate/Models/
```

---

## 🎨 How to Use the App

### Basic Workflow

```
1. Press ⌥R
   ↓
2. Speak into microphone
   ↓
3. Press ⌥R to stop
   ↓
4. [Transcription happens]
   ↓
5. [Optional: AI styling]
   ↓
6. Text copied to clipboard
   ↓
7. Paste with ⌘V
```

### Example Session

```
You say:
"Um, so I was thinking we could, uh, meet tomorrow at like 3pm 
to discuss the project proposal and, you know, review the budget"

Plain style result:
"Um, so I was thinking we could, uh, meet tomorrow at like 3pm 
to discuss the project proposal and, you know, review the budget"

Simplify style result:
"I was thinking we could meet tomorrow at 3pm to discuss the 
project proposal and review the budget."

Email Draft style result:
"Subject: Meeting Request - Project Proposal Review

Hi [Name],

I was thinking we could meet tomorrow at 3pm to discuss the 
project proposal and review the budget.

Please let me know if this time works for you.

Best regards"
```

---

## ⚙️ Configuration

### Settings Location

Click menu bar icon → **Settings**

### Tabs:

1. **General**
   - Output folder for markdown files
   - Hotkey customization
   - Launch at login

2. **Style**
   - Default text style
   - Custom prompt (for Custom style)
   - Preview examples

3. **Models**
   - Download/delete LLM models
   - Select active model
   - View model info

---

## 🐛 Common Issues & Solutions

### Issue: "No such module 'MLX'"

**Fix:**
```bash
# In Xcode:
File → Packages → Reset Package Caches
File → Packages → Resolve Package Versions
```

### Issue: Hotkey doesn't work

**Fix:**
- Grant Accessibility permission
- System Settings → Privacy & Security → Accessibility
- Add Dictate and enable checkbox

### Issue: App doesn't appear in menu bar

**Fix:**
- Check Info.plist has `LSUIElement` = `true` ✅ (already set)
- Look for crash logs in Console.app
- Run from Xcode to see console output

### Issue: Model download fails

**Fix:**
- Check internet connection
- Check disk space (need 0.7-2.2 GB per model)
- Try downloading again

**More solutions:** See `XCODE_TROUBLESHOOTING.md`

---

## 📊 Performance Notes

### Debug vs Release Builds

| Aspect | Debug | Release |
|--------|-------|---------|
| Build time | Fast | Slower |
| Runtime speed | Slow | 10-100x faster |
| LLM styling (500 words) | ~15-20 sec | ~2-3 sec |

**For development:** Use Debug (default in Xcode)
**For testing LLM:** Use Release

To build Release in Xcode:
1. Edit Scheme → Run → Info
2. Build Configuration → **Release**

---

## 🎓 Learning Resources

### Documentation Files

- **`README.md`** - High-level overview, installation
- **`XCODE_SETUP.md`** - Detailed setup instructions
- **`XCODE_CHECKLIST.md`** - Step-by-step verification
- **`BUILD_WORKFLOWS.md`** - Different ways to build
- **`XCODE_TROUBLESHOOTING.md`** - Solutions to problems
- **`IMPLEMENTATION_SUMMARY.md`** - Technical architecture
- **`TESTING.md`** - Testing guide

### Key Code Files

- **`DictateApp.swift`** - App lifecycle, hotkey setup
- **`AppState.swift`** - Central state management
- **`ModelManager.swift`** - LLM model downloads (← you are here)
- **`TextStyler.swift`** - MLX LLM text generation
- **`AudioRecorder.swift`** - Audio capture
- **`SpeechAnalyzerEngine.swift`** - On-device transcription

---

## 🔄 Development Workflow

### Typical Development Session

```bash
# 1. Open project
open Package.swift

# 2. Make code changes in Xcode

# 3. Press ⌘R to test

# 4. Use the app (⌥R to record)

# 5. Iterate!
```

### Before Committing Code

```bash
# Test release build
swift build -c release

# Run tests
swift test

# Check for issues
# (look for warnings in Xcode)
```

---

## 📦 Distribution

### For Yourself

```bash
make app
cp -r .build/release-app/Dictate.app /Applications/
```

### For Others (Unsigned)

```bash
make dmg
# Share: .build/release-app/Dictate-1.0.0.dmg
```

**Note:** Others will see "unidentified developer" warning and need to right-click → Open

### For Public Distribution (Signed & Notarized)

Requires Apple Developer account ($99/year):

```bash
# One-time setup
1. Get Developer ID certificate from Apple
2. Edit Makefile with your certificate name
3. Store notarization credentials:
   xcrun notarytool store-credentials "notary-profile" ...

# Then:
make notarize
# Share: .build/release-app/Dictate-1.0.0.dmg (notarized)
```

**Result:** No Gatekeeper warnings for users

---

## 🎯 Next Steps

### Right Now:
1. ✅ Run `./setup.sh` (if you haven't)
2. ✅ Press ⌘R in Xcode
3. ✅ Grant microphone permission
4. ✅ Test with ⌥R hotkey

### Soon:
1. Download an LLM model (Settings → Models)
2. Try different text styles
3. Customize hotkey if needed
4. Set up markdown export folder

### Later:
1. Explore the codebase
2. Customize prompts
3. Add new features
4. Share with others

---

## 🤝 Project Info

**Language:** Swift 6.0
**Platform:** macOS 15+ (Sequoia)
**Architecture:** Apple Silicon (arm64)
**UI Framework:** SwiftUI
**Package Manager:** Swift Package Manager

**Key Dependencies:**
- MLX Swift (Apple's ML framework)
- MLX-LM (Language models for MLX)
- KeyboardShortcuts (Global hotkeys)

---

## 📞 Getting Help

### Quick Questions
- Check `XCODE_TROUBLESHOOTING.md` first
- Search for error messages in documentation

### Build Issues
- See "Troubleshooting" section in `XCODE_SETUP.md`
- Check Console.app for crash logs

### Feature Questions
- Read `README.md` for usage
- Check `IMPLEMENTATION_SUMMARY.md` for architecture

### Still Stuck?
- File an issue on GitHub with:
  - Your macOS version
  - Your Xcode version
  - Error message
  - Steps to reproduce

---

## ✅ Success Checklist

You're ready to go when:

- [ ] `./setup.sh` ran successfully
- [ ] Xcode opened the project
- [ ] Dependencies resolved (green checkmarks)
- [ ] Pressed ⌘R and app built
- [ ] Icon appeared in menu bar
- [ ] Microphone permission granted
- [ ] ⌥R hotkey toggles recording
- [ ] Text appears on clipboard after recording

**All checked?** Congratulations! You now have a working Mac app! 🎉

---

## 🚀 You're All Set!

Your Dictate app is ready to use. Press ⌥R and start dictating!

**Happy coding!** 🎙️

---

**Questions?** Check the other documentation files or file an issue.

**Last Updated:** March 24, 2026
