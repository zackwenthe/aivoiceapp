import SwiftUI
import OSLog

@Observable
@MainActor
final class AppState {
    enum Phase: Equatable {
        case idle
        case recording
        case transcribing
        case styling
        case done(text: String)
        case error(String)
    }

    var phase: Phase = .idle
    var selectedStyle: TextStyle = .plain
    var audioLevel: Float = 0.0
    var recentTranscriptions: [TranscriptionRecord] = []

    var isFirstLaunch: Bool {
        !UserDefaults.standard.bool(forKey: UserDefaults.Keys.hasCompletedOnboarding)
    }

    var outputFolderURL: URL? {
        guard let path = UserDefaults.standard.string(forKey: UserDefaults.Keys.outputFolderPath) else {
            return nil
        }
        return URL(fileURLWithPath: path)
    }

    var saveMarkdownFiles: Bool {
        get { UserDefaults.standard.bool(forKey: UserDefaults.Keys.saveMarkdownFiles) }
        set { UserDefaults.standard.set(newValue, forKey: UserDefaults.Keys.saveMarkdownFiles) }
    }

    private let audioRecorder = AudioRecorder()
    private let whisperEngine = WhisperKitEngine()
    private let clipboardManager = ClipboardManager()
    private var textStyler: TextStyler?

    init() {
        // Load saved style preference
        if let raw = UserDefaults.standard.string(forKey: UserDefaults.Keys.defaultStyleRawValue),
           let style = TextStyle(rawValue: raw) {
            selectedStyle = style
        }
    }

    func completeOnboarding() {
        UserDefaults.standard.set(true, forKey: UserDefaults.Keys.hasCompletedOnboarding)
    }

    func setOutputFolder(_ url: URL) {
        UserDefaults.standard.set(url.path, forKey: UserDefaults.Keys.outputFolderPath)
    }

    // MARK: - Recording Pipeline

    func toggleRecording() {
        switch phase {
        case .idle:
            startRecording()
        case .recording:
            stopRecordingAndProcess()
        default:
            // Pipeline in progress, ignore
            Logger.app.debug("Toggle ignored — pipeline in progress: \(String(describing: self.phase))")
        }
    }

    private func startRecording() {
        Logger.audio.info("Starting recording")
        phase = .recording

        do {
            try audioRecorder.startRecording { [weak self] level in
                Task { @MainActor in
                    self?.audioLevel = level
                }
            }
        } catch {
            Logger.audio.error("Failed to start recording: \(error.localizedDescription)")
            phase = .error("Failed to start recording")
            scheduleResetToIdle()
        }
    }

    private func stopRecordingAndProcess() {
        Logger.audio.info("Stopping recording")

        guard let audioURL = audioRecorder.stopRecording() else {
            phase = .error("No audio recorded")
            scheduleResetToIdle()
            return
        }

        Task {
            await runPipeline(audioURL: audioURL)
        }
    }

    private func runPipeline(audioURL: URL) async {
        // Step 1: Transcribe
        guard whisperEngine.isAvailable else {
            Logger.transcription.error("WhisperKit model not loaded, attempting reload before transcription")
            do {
                try await whisperEngine.loadModel()
            } catch {
                Logger.transcription.error("Model reload failed: \(error.localizedDescription)")
                phase = .error("Transcription model not loaded")
                cleanupAudio(at: audioURL)
                scheduleResetToIdle()
                return
            }
        }

        phase = .transcribing
        let rawText: String
        do {
            rawText = try await whisperEngine.transcribe(audioFileURL: audioURL)
            Logger.transcription.info("Transcription complete: \(rawText.prefix(100))...")
        } catch {
            Logger.transcription.error("Transcription failed: \(error.localizedDescription)")
            phase = .error("Transcription failed")
            cleanupAudio(at: audioURL)
            scheduleResetToIdle()
            return
        }

        // Step 2: Delete audio file
        cleanupAudio(at: audioURL)

        // Step 3: Style text (if needed)
        let finalText: String
        if selectedStyle.requiresLLM {
            phase = .styling
            do {
                guard let styler = textStyler else {
                    throw DictateError.modelNotLoaded
                }
                let customPrompt = UserDefaults.standard.string(forKey: UserDefaults.Keys.customStylePrompt)
                finalText = try await styler.style(text: rawText, style: selectedStyle, customPrompt: customPrompt)
                Logger.styling.info("Styling complete")
            } catch {
                Logger.styling.error("Styling failed: \(error.localizedDescription), using raw text")
                finalText = rawText
            }
        } else {
            finalText = rawText
        }

        // Step 4: Copy to clipboard
        clipboardManager.copy(finalText)
        Logger.app.info("Copied to clipboard")

        // Step 5: Save markdown (if configured)
        if saveMarkdownFiles, let folder = outputFolderURL {
            do {
                try MarkdownFileWriter.save(text: finalText, rawTranscript: rawText, style: selectedStyle, to: folder)
                Logger.app.info("Markdown file saved")
            } catch {
                Logger.app.error("Failed to save markdown: \(error.localizedDescription)")
            }
        }

        // Step 6: Record in history
        let record = TranscriptionRecord(
            date: Date(),
            preview: String(finalText.prefix(100)),
            style: selectedStyle
        )
        recentTranscriptions.insert(record, at: 0)
        if recentTranscriptions.count > 20 {
            recentTranscriptions = Array(recentTranscriptions.prefix(20))
        }

        // Step 7: Show done state
        phase = .done(text: finalText)
        scheduleResetToIdle()
    }

    private func cleanupAudio(at url: URL) {
        do {
            try FileManager.default.removeItem(at: url)
            Logger.audio.info("Audio file deleted")
        } catch {
            Logger.audio.warning("Failed to delete audio file: \(error.localizedDescription)")
        }
    }

    private func scheduleResetToIdle() {
        Task {
            try? await Task.sleep(for: .seconds(2))
            if case .done = phase {
                phase = .idle
            } else if case .error = phase {
                phase = .idle
            }
        }
    }

    // MARK: - Model Management

    func setTextStyler(_ styler: TextStyler) {
        self.textStyler = styler
    }

    func loadTranscriptionModel() async {
        do {
            try await whisperEngine.loadModel()
            Logger.app.info("WhisperKit transcription model ready")
        } catch {
            Logger.app.error("Failed to load WhisperKit model: \(error.localizedDescription)")
        }
    }
}

// MARK: - TranscriptionRecord

struct TranscriptionRecord: Identifiable {
    let id = UUID()
    let date: Date
    let preview: String
    let style: TextStyle
}
