# Testing Guide for Dictate

## Pre-Implementation Checklist

Before testing the app, ensure all these components are in place:

### ✅ Core Files Created/Updated

- [x] `View+Extensions.swift` - Glass card modifier
- [x] `ModelInfo.swift` - Model metadata with MLX-compatible repos
- [x] `ModelManager.swift` - Multi-file download system with progress tracking
- [x] All existing files verified for completeness

### ✅ Model Download Implementation

- [x] Downloads multiple files per model (config.json, tokenizer files, weights)
- [x] Stores models as directories (not single files)
- [x] Validates model completeness
- [x] Proper error handling and cleanup
- [x] Real-time progress tracking
- [x] Cancellation support

### ✅ MLX Integration

- [x] Model loading expects directory path (not single file)
- [x] Compatible with MLX Swift `LLMModelFactory`
- [x] Proper model format validation

---

## Testing Steps

### Phase 1: Build & Launch

1. **Build the project**
   ```bash
   make build
   ```
   
2. **Check for compilation errors**
   - All imports should resolve
   - No syntax errors
   - Swift 6 concurrency checks pass

3. **Launch the app**
   ```bash
   make app
   open .build/release-app/Dictate.app
   ```

### Phase 2: UI Testing

1. **Menu Bar Icon**
   - [ ] App appears in menu bar
   - [ ] Icon changes based on state (idle, recording, etc.)

2. **Settings Window**
   - [ ] General tab loads
   - [ ] Styles tab loads
   - [ ] Models tab loads
   - [ ] All UI elements render correctly

3. **Model Settings View**
   - [ ] Three models listed (Llama 3.2 1B, 3B, Phi-4 Mini)
   - [ ] Download buttons visible
   - [ ] Size descriptions correct

### Phase 3: Model Download Testing

**⚠️ Important**: Real model downloads will fail until you verify the Hugging Face repos exist and have the correct file structure.

#### Test with Mock Model (Recommended First)

1. **Create a test model manually**:
   ```bash
   mkdir -p ~/Library/Application\ Support/Dictate/Models/test-model
   cd ~/Library/Application\ Support/Dictate/Models/test-model
   echo '{"model_type":"test"}' > config.json
   echo '{"version":"1.0"}' > tokenizer.json
   echo '{"version":"1.0"}' > tokenizer_config.json
   echo 'mock weights' > model.safetensors
   ```

2. **Restart app** - Model should show as "Downloaded"

#### Test Real Download

1. **Click Download on a model**
   - [ ] Progress bar appears
   - [ ] Progress updates (0-100%)
   - [ ] Cancel button works
   - [ ] Download completes or shows error

2. **Verify downloaded files**:
   ```bash
   ls -la ~/Library/Application\ Support/Dictate/Models/llama-3.2-1b/
   ```
   Expected files:
   - `config.json`
   - `tokenizer.json`
   - `tokenizer_config.json`
   - `model.safetensors`

3. **Test model selection**
   - [ ] "Select" button appears for downloaded model
   - [ ] Clicking "Select" marks it as active
   - [ ] "Active" label shows for selected model

4. **Test model deletion**
   - [ ] Right-click model → Delete
   - [ ] Model removed from filesystem
   - [ ] State updates to "Not Downloaded"

### Phase 4: Model Loading Testing

1. **Select a downloaded model**
2. **Check logs** (Console.app → filter by "Dictate"):
   ```
   Loading LLM model: /path/to/model
   Model loaded successfully
   ```
3. **Verify TextStyler state**:
   - Should transition from `.loading` → `.ready`
   - If error, check MLX model compatibility

### Phase 5: End-to-End Pipeline

1. **Grant microphone permission**
2. **Press hotkey (⌥R)** to start recording
   - [ ] Recording overlay appears
   - [ ] Waveform animates
   - [ ] Audio level indicator works

3. **Press hotkey again** to stop
   - [ ] "Transcribing..." state
   - [ ] "Styling..." state (if LLM style selected)
   - [ ] "Done!" confirmation
   - [ ] Text copied to clipboard

4. **Test different styles**:
   - [ ] Plain (no LLM)
   - [ ] Simplify (requires LLM)
   - [ ] Structured
   - [ ] Email
   - [ ] Bullets
   - [ ] Custom

5. **Verify output**:
   - [ ] Clipboard contains transcribed/styled text
   - [ ] Markdown file saved (if enabled)

---

## Known Issues to Test

### Issue 1: Hugging Face Model Repos

**Problem**: The repos specified in `ModelInfo.swift` may not exist or may not have the exact file structure expected.

**Test**:
```bash
# Check if repo exists and has required files
curl -I https://huggingface.co/mlx-community/Llama-3.2-1B-Instruct-4bit/resolve/main/config.json
curl -I https://huggingface.co/mlx-community/Llama-3.2-1B-Instruct-4bit/resolve/main/model.safetensors
```

**Fix if needed**:
- Update `ModelInfo.huggingFaceRepo` to correct repo
- Update `ModelInfo.fileName` to match actual weights filename
- May need to use different MLX model sources

### Issue 2: MLX Model Format

**Problem**: MLX Swift may expect specific directory structure or additional files.

**Test**: After download, try loading:
```swift
let config = ModelConfiguration(id: "/path/to/model/directory")
```

**Fix if needed**:
- Check MLX Swift documentation for required files
- Update `isModelComplete()` validation
- Add missing files to download list

### Issue 3: Model Size vs. Actual Size

**Problem**: File sizes in `ModelInfo` are estimates.

**Test**: Compare downloaded size vs. `sizeDescription`

**Fix**: Update size estimates based on actual downloads

---

## Debugging Tips

### View Logs
```bash
# Open Console.app
open -a Console

# Filter by "Dictate" subsystem
# Look for categories: app, audio, transcription, styling, models
```

### Check File System
```bash
# Models directory
ls -lah ~/Library/Application\ Support/Dictate/Models/

# Recorded audio (temporary)
ls -lah /tmp/dictate-*

# Markdown output (if configured)
ls -lah ~/Documents/Dictate/
```

### Test Individual Components

```swift
// Test model download (in a test target)
let manager = ModelManager()
let model = ModelInfo.availableModels[0]
await manager.downloadModel(model)

// Test transcription
let engine = SpeechAnalyzerEngine()
let audioURL = URL(fileURLWithPath: "/path/to/test.wav")
let transcript = try await engine.transcribe(audioFileURL: audioURL)

// Test styling
let styler = TextStyler()
await styler.loadModel(from: "/path/to/model")
let styled = try await styler.style(text: "test", style: .simplify)
```

---

## Success Criteria

The app is fully functional when:

- ✅ Builds without errors
- ✅ All UI views render correctly
- ✅ Models can be downloaded and stored
- ✅ Models can be selected and loaded
- ✅ Recording works with visual feedback
- ✅ Transcription produces text output
- ✅ Styling works with loaded LLM
- ✅ Text is copied to clipboard
- ✅ Markdown files saved (if enabled)
- ✅ No crashes or memory leaks
- ✅ Proper error messages shown to user

---

## Next Steps After Testing

1. **Update model repos** if URLs are incorrect
2. **Add more models** to `ModelInfo.availableModels`
3. **Optimize download** (parallel downloads, resume support)
4. **Add model verification** (checksum validation)
5. **Improve error messages** (user-friendly descriptions)
6. **Add progress persistence** (survive app restart)
7. **Add disk space checks** before download
8. **Add model info** (show token count, context length, etc.)
