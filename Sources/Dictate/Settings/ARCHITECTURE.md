# Dictate App Architecture Overview

Visual guide to understanding how your Dictate app works.

---

## 🏗️ High-Level Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    Dictate Menu Bar App                  │
└─────────────────────────────────────────────────────────┘
                            │
        ┌───────────────────┼───────────────────┐
        │                   │                   │
        ▼                   ▼                   ▼
┌───────────────┐  ┌────────────────┐  ┌──────────────┐
│  Audio Layer  │  │ Transcription  │  │ Styling Layer│
│               │  │     Layer      │  │              │
│ ┌───────────┐ │  │ ┌────────────┐ │  │ ┌──────────┐ │
│ │AudioRec.  │ │  │ │SpeechAnaly-│ │  │ │TextStyler│ │
│ │           │ │  │ │zer         │ │  │ │(MLX LLM) │ │
│ └───────────┘ │  │ └────────────┘ │  │ └──────────┘ │
└───────┬───────┘  └────────┬───────┘  └──────┬───────┘
        │                   │                  │
        │                   │                  │
        └───────────────────┴──────────────────┘
                            │
                            ▼
        ┌───────────────────────────────────────┐
        │           Output Layer                │
        │  ┌────────────┐    ┌────────────────┐ │
        │  │ Clipboard  │    │ Markdown File  │ │
        │  │  Manager   │    │    Writer      │ │
        │  └────────────┘    └────────────────┘ │
        └───────────────────────────────────────┘
```

---

## 🔄 Request Flow

### User Presses ⌥R (Start Recording)

```
1. User presses ⌥R
         │
         ▼
2. KeyboardShortcuts detects hotkey
         │
         ▼
3. AppState.toggleRecording() called
         │
         ▼
4. AppState.phase = .recording
         │
         ▼
5. AudioRecorder.startRecording()
         │
         ▼
6. AVAudioEngine captures microphone input
         │
         ▼
7. Audio data buffered in memory
         │
         ▼
8. Menu bar icon changes to 🎙️ (mic.fill)
         │
         ▼
9. RecordingOverlay window appears (optional)
```

### User Presses ⌥R Again (Stop Recording)

```
1. User presses ⌥R again
         │
         ▼
2. AppState.toggleRecording() called
         │
         ▼
3. AudioRecorder.stopRecording()
         │
         ▼
4. Audio data saved to temporary file
         │
         ▼
5. AppState.phase = .transcribing
         │
         ▼
6. SpeechAnalyzerEngine.transcribe(audioURL)
         │
         ▼
7. Speech framework analyzes audio
         │
         ├─ Success ─────────────┐
         │                       │
         ▼                       ▼
8a. Returns transcript    8b. Returns error
         │                       │
         ▼                       ▼
9a. AppState.phase =      9b. AppState.phase =
    .styling                   .error
         │
         ▼
10. TextStyler.style(text, style: .simplify)
         │
         ├─ Plain style ────────┐
         │                      │
         │                      ▼
         │              Return text as-is
         │
         ├─ Other styles ───────┐
         │                      │
         │                      ▼
         │              MLX LLM generates
         │              styled version
         │
         ▼
11. AppState.phase = .done
         │
         ▼
12. ClipboardManager.copy(styledText)
         │
         ▼
13. (Optional) MarkdownFileWriter.write(styledText)
         │
         ▼
14. AudioRecorder.deleteAudioFile()
         │
         ▼
15. Menu bar icon changes to ✓ (checkmark.circle)
         │
         ▼
16. User can paste with ⌘V
```

---

## 📁 File Organization & Responsibilities

### App Layer (Lifecycle & State)

```
DictateApp.swift
├─ @main entry point
├─ Creates @State objects:
│  ├─ AppState (central state)
│  ├─ ModelManager (LLM downloads)
│  └─ TextStyler (MLX instance)
├─ Defines scenes:
│  ├─ MenuBarExtra (main UI)
│  ├─ Window("overlay") for recording status
│  ├─ Settings window
│  └─ Onboarding window
└─ Sets up global hotkey

AppState.swift
├─ @Observable class
├─ Manages app phase (.idle, .recording, .transcribing, etc.)
├─ Coordinates between layers
├─ Holds references to:
│  ├─ AudioRecorder
│  ├─ TranscriptionEngine
│  ├─ TextStyler
│  ├─ ClipboardManager
│  └─ MarkdownFileWriter
└─ Handles errors and state transitions
```

### Audio Layer (Recording)

```
AudioRecorder.swift
├─ Uses AVAudioEngine
├─ Requests microphone permission
├─ Captures audio to buffer
├─ Saves to temporary .wav file
├─ Provides audio URL for transcription
└─ Deletes audio after transcription

AudioPermissions.swift
├─ Checks microphone access
├─ Requests permission
└─ Handles permission denial
```

### Transcription Layer (Speech → Text)

```
TranscriptionEngine.swift
└─ Protocol defining transcription interface

SpeechAnalyzerEngine.swift
├─ Implements TranscriptionEngine
├─ Uses Speech framework (SFSpeechAnalyzer)
├─ On-device processing
├─ Returns transcript or error
└─ Supports multiple languages
```

### Styling Layer (Text Transformation)

```
TextStyle.swift
├─ Enum of available styles:
│  ├─ .plain (no LLM)
│  ├─ .simplify
│  ├─ .structured
│  ├─ .email
│  ├─ .bullets
│  └─ .custom
└─ Display names and descriptions

StylePrompts.swift
├─ System prompts for each style
└─ User message formatting

TextStyler.swift
├─ @Observable class
├─ Loads MLX LLM model
├─ Generates styled text
├─ Uses MLX for on-device inference
└─ State: .notLoaded, .loading, .ready, .error
```

### Model Management Layer (LLM Downloads)

```
ModelManager.swift (← YOU ARE HERE)
├─ @Observable @MainActor class
├─ Manages LLM model downloads
├─ Tracks download state per model
├─ Downloads from Hugging Face
├─ Validates downloaded files
├─ Loads selected model into TextStyler
└─ URLSession with custom delegate

ModelInfo.swift
├─ Defines available models
├─ Model metadata (name, size, repo)
└─ Static array of models
```

### Output Layer (Results)

```
ClipboardManager.swift
├─ Copies text to clipboard
└─ Uses NSPasteboard

MarkdownFileWriter.swift
├─ Writes .md files with YAML frontmatter
├─ Includes metadata (timestamp, style, etc.)
├─ User-configurable output folder
└─ Optional (can be disabled)
```

### UI Layer (SwiftUI Views)

```
MenuBarView.swift
├─ Main menu bar dropdown
├─ Shows current phase
├─ Start/stop recording button
├─ Style picker
├─ Settings access
└─ Quit button

RecordingOverlay.swift
├─ Floating window during recording
├─ Shows elapsed time
└─ Visual recording indicator

SettingsView.swift
├─ TabView with:
│  ├─ GeneralSettingsView
│  ├─ StyleSettingsView
│  └─ ModelSettingsView
└─ Preferences management

OnboardingView.swift
├─ First-launch experience
├─ Explains features
└─ Guides initial setup
```

### Utilities

```
Errors.swift
└─ DictateError enum with localized descriptions

Logger+App.swift
└─ Logger categories for debugging

UserDefaults+Keys.swift
└─ Centralized preference keys
```

---

## 🔌 Dependency Graph

```
DictateApp
    │
    ├─> AppState
    │     │
    │     ├─> AudioRecorder
    │     ├─> SpeechAnalyzerEngine
    │     ├─> TextStyler (receives from ModelManager)
    │     ├─> ClipboardManager
    │     └─> MarkdownFileWriter
    │
    ├─> ModelManager
    │     │
    │     └─> TextStyler (loads model into it)
    │
    └─> TextStyler (created, passed around)
```

---

## 🎨 SwiftUI Scene Hierarchy

```
DictateApp (@main)
    │
    ├─ MenuBarExtra("Dictate")
    │    └─ MenuBarView
    │         ├─ Status indicator
    │         ├─ Record/Stop button
    │         ├─ Style picker
    │         ├─ Settings button
    │         └─ Quit button
    │
    ├─ Window("Recording")
    │    └─ RecordingOverlay
    │         ├─ Timer
    │         └─ Waveform animation (optional)
    │
    ├─ Settings
    │    └─ SettingsView (TabView)
    │         ├─ GeneralSettingsView
    │         │    ├─ Output folder picker
    │         │    ├─ Hotkey customization
    │         │    └─ Launch at login toggle
    │         │
    │         ├─ StyleSettingsView
    │         │    ├─ Default style picker
    │         │    └─ Custom prompt editor
    │         │
    │         └─ ModelSettingsView
    │              ├─ Model list
    │              ├─ Download buttons
    │              ├─ Progress indicators
    │              └─ Model selection
    │
    └─ Window("Onboarding")
         └─ OnboardingView
              ├─ Welcome screen
              ├─ Features explanation
              └─ Initial setup
```

---

## 🧵 Concurrency Model

### Main Actor (@MainActor)

These run on the main thread (UI updates):
- `AppState`
- `ModelManager`
- All SwiftUI views

### Background Actors

These can run on background threads:
- `AudioRecorder` (some methods)
- `SpeechAnalyzerEngine` (transcription)
- `TextStyler.style()` (async, runs on MLX thread pool)
- Model downloads (URLSession delegate)

### Example Flow

```swift
// User presses hotkey → runs on main thread
@MainActor
func toggleRecording() {
    if isRecording {
        // Stop and transcribe
        Task {
            // Audio processing can happen in background
            let audioURL = await audioRecorder.stop()
            
            // Transcription happens in background
            let transcript = try await engine.transcribe(audioURL)
            
            // Styling happens in background (MLX)
            let styled = try await styler.style(transcript, style: currentStyle)
            
            // Back to main thread for UI update
            await MainActor.run {
                self.result = styled
                self.phase = .done
            }
        }
    }
}
```

---

## 💾 Data Flow

### Persistent Storage

```
User Defaults
├─ hasCompletedOnboarding: Bool
├─ outputFolderPath: String?
├─ defaultStyleRawValue: String
├─ customStylePrompt: String?
├─ selectedLLMModel: String?
├─ launchAtLogin: Bool
└─ saveMarkdownFiles: Bool

File System
├─ ~/Library/Application Support/Dictate/
│   └─ Models/
│       ├─ llama-3.2-1b/
│       │   ├─ config.json
│       │   ├─ tokenizer.json
│       │   ├─ tokenizer_config.json
│       │   └─ model.safetensors
│       ├─ llama-3.2-3b/
│       └─ phi-4-mini/
│
└─ [User-chosen folder]/
    └─ dictation-2026-03-24-143022.md
```

### Temporary Storage

```
/tmp/
└─ dictate-recording-[UUID].wav
    (deleted after transcription)
```

### Clipboard

```
NSPasteboard.general
└─ Styled text (ready to paste)
```

---

## 🔐 Security & Privacy

### Permissions Required

```
Microphone
├─ Declared in Info.plist
├─ Requested at runtime
└─ Used by: AudioRecorder

Accessibility (optional)
├─ For global hotkey
├─ Requested by: KeyboardShortcuts
└─ User must enable manually in Settings
```

### Privacy Guarantees

```
✅ All transcription on-device (Speech framework)
✅ All LLM inference on-device (MLX)
✅ No network requests (except model downloads)
✅ Audio deleted after transcription
✅ No data sent to cloud
✅ No analytics or tracking
```

---

## 🧪 Testing Points

Key areas to test:

```
Audio Layer
├─ Microphone permission granted/denied
├─ Recording starts/stops correctly
└─ Audio file created and cleaned up

Transcription Layer
├─ Transcription succeeds
├─ Handles audio quality issues
└─ Returns errors gracefully

Styling Layer
├─ Plain style (no LLM needed)
├─ LLM styles (model loaded)
├─ Model not loaded (error handling)
└─ Custom prompts work

Model Management
├─ Download succeeds
├─ Download progress updates
├─ Download can be cancelled
├─ Downloaded model loads correctly
└─ Missing files detected

Integration
├─ Full recording → transcription → styling → clipboard flow
├─ Hotkey toggles recording
├─ UI updates reflect state changes
└─ Errors shown to user
```

---

## 📊 Performance Characteristics

### Debug Build

```
Recording: 0ms overhead
Transcription: ~5-10 sec (Speech framework, same in both builds)
Styling (plain): <1ms
Styling (LLM): ~15-20 sec (SLOW)
Total time: ~20-30 sec
```

### Release Build

```
Recording: 0ms overhead
Transcription: ~5-10 sec (same)
Styling (plain): <1ms
Styling (LLM): ~2-3 sec (FAST! 10x faster)
Total time: ~8-13 sec
```

**Key Takeaway:** Always test LLM performance in Release mode!

---

## 🛠️ Extension Points

Easy places to add features:

```
New Text Styles
├─ Add case to TextStyle enum
├─ Add prompt to StylePrompts
└─ Appears automatically in UI

New LLM Models
├─ Add to ModelInfo.availableModels
└─ Must be MLX-compatible from Hugging Face

Custom Output Formats
├─ Create new writer (like MarkdownFileWriter)
└─ Call from AppState after styling

Additional Hotkeys
├─ Define in DictateApp.swift
└─ Add to KeyboardShortcuts.Name extension

New Settings
├─ Add to UserDefaults.Keys
├─ Add UI in appropriate SettingsView
└─ Use in app logic
```

---

## 🎯 Key Design Decisions

### Why @Observable instead of ObservableObject?

- Simpler syntax (no `@Published`)
- Automatic dependency tracking
- Better performance
- Modern Swift (5.9+)

### Why @MainActor for ModelManager?

- UI updates from download progress
- Prevents race conditions
- Simplifies state management

### Why delete audio files?

- Privacy (nothing stored)
- Saves disk space
- Transcription is permanent copy

### Why MLX instead of other LLM frameworks?

- Native Swift
- Apple Silicon optimized
- On-device (privacy)
- Fast inference

### Why menu bar app (LSUIElement)?

- Always accessible
- No clutter in Dock
- Global hotkey makes sense
- Productivity tool pattern

---

This architecture provides:
- ✅ Clear separation of concerns
- ✅ Testability
- ✅ Extensibility
- ✅ Type safety
- ✅ Swift concurrency support
- ✅ Privacy-first design

---

**Understanding this?** You're ready to extend the app! 🚀
