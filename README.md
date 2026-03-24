# Dictate

A native macOS menu bar utility that records your voice, transcribes it locally, optionally styles the text, and copies it to your clipboard.

Built for Apple Silicon Macs running macOS 26 (Tahoe) with Liquid Glass UI.

## Features

- **Global hotkey** (⌥R) to toggle recording from anywhere
- **On-device transcription** using Apple SpeechAnalyzer — no cloud, no data leaves your Mac
- **Text styling** with a local LLM (MLX Swift) — simplify, structure, email draft, bullet points, or custom prompts
- **Auto-copy to clipboard** — paste your transcription anywhere immediately
- **Markdown file saving** — optional timestamped `.md` files with YAML frontmatter
- **Audio deleted after transcription** — nothing stored on disk

## Requirements

- macOS 26 (Tahoe) or later
- Apple Silicon Mac (M1, M2, M3, M4)
- Xcode 26+ (to build from source)
- Microphone access

## Build & Install

### Quick Start (Xcode)

```bash
# Clone the repo
git clone https://github.com/zackwenthe/aivoiceapp.git
cd aivoiceapp

# Open in Xcode
open Package.swift
```

In Xcode: **Product → Run** (⌘R) to launch, or **Product → Archive** for distribution.

### Build from Terminal

```bash
# Release build
make build

# Create .app bundle
make app

# Create installable DMG
make dmg
```

The DMG will be at `.build/release-app/Dictate-1.0.0.dmg`.

### Install the DMG

1. Open `Dictate-1.0.0.dmg`
2. Drag **Dictate** to the **Applications** folder
3. Launch Dictate from Applications
4. Grant microphone access when prompted
5. The app appears as a waveform icon (⏦) in your menu bar

> **Note:** Without code signing, macOS may block the app. Right-click the app → Open → Open to bypass Gatekeeper on first launch.

### Code Signing & Notarization (Optional)

Required for distribution to others without Gatekeeper warnings. Requires an Apple Developer account ($99/yr).

```bash
# One-time: store your notarization credentials
xcrun notarytool store-credentials "notary-profile" \
  --apple-id "you@email.com" \
  --team-id "YOURTEAMID" \
  --password "app-specific-password"

# Sign the app
make sign

# Or sign, create DMG, notarize, and staple in one step
make notarize
```

Before signing, edit the `Makefile` and replace `YOUR_NAME (TEAM_ID)` with your Developer ID certificate identity. Find it with:

```bash
security find-identity -v -p codesigning
```

## Usage

1. **Press ⌥R** (Option + R) to start recording
2. **Press ⌥R again** to stop
3. Text is transcribed and **copied to your clipboard**
4. Paste anywhere with ⌘V

### Styles

Choose a style from the menu bar dropdown:

| Style | Description | Requires LLM |
|-------|-------------|:---:|
| Plain | Raw transcript, no changes | No |
| Simplify | Fix grammar, remove filler words | Yes |
| Structured | Add headings and sections | Yes |
| Email Draft | Professional email format | Yes |
| Bullet Points | Key points as bullets | Yes |
| Custom | Your own prompt | Yes |

### LLM Models

For text styling (anything except Plain), download a local LLM model:

1. Click the menu bar icon → **Settings** → **Models** tab
2. Choose a model and click **Download**
3. Select the model as active

Available models:
- **Llama 3.2 1B** (~700 MB) — fast, lightweight
- **Llama 3.2 3B** (~1.8 GB) — better quality
- **Phi-4 Mini** (~2.2 GB) — best quality

Models are downloaded from Hugging Face and run entirely on-device via MLX.

## Project Structure

```
Sources/Dictate/
├── App/           — DictateApp.swift, AppState.swift
├── Audio/         — AudioRecorder, AudioPermissions
├── Transcription/ — TranscriptionEngine protocol, SpeechAnalyzerEngine
├── Styling/       — TextStyle, StylePrompts, TextStyler (MLX LLM)
├── Output/        — ClipboardManager, MarkdownFileWriter
├── Models/        — ModelManager, ModelManifest
├── Settings/      — General, Style, Model settings views
├── Views/         — MenuBarView, RecordingOverlay, OnboardingView
└── Utilities/     — Errors, Logger, UserDefaults keys
```

## Make Commands

| Command | Description |
|---------|-------------|
| `make build` | Release build via Swift Package Manager |
| `make app` | Create `Dictate.app` bundle from release build |
| `make dmg` | Create installable DMG with Applications shortcut |
| `make sign` | Code-sign the app (edit Makefile with your identity first) |
| `make notarize` | Notarize DMG with Apple (requires Developer account) |
| `make clean` | Remove build artifacts |

## License

MIT
