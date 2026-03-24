import Foundation
import WhisperKit
import OSLog

final class WhisperKitEngine: TranscriptionEngine, @unchecked Sendable {
    private var whisperKit: WhisperKit?

    var displayName: String { "WhisperKit (Large v3 Turbo)" }

    var isAvailable: Bool { whisperKit != nil }

    func loadModel() async throws {
        Logger.transcription.info("Loading WhisperKit model (large-v3-turbo)...")
        let config = WhisperKitConfig(model: "large-v3-turbo")
        whisperKit = try await WhisperKit(config)
        Logger.transcription.info("WhisperKit model loaded successfully")
    }

    func transcribe(audioFileURL: URL) async throws -> String {
        guard let pipe = whisperKit else {
            throw DictateError.transcriptionEngineUnavailable
        }

        Logger.transcription.info("Transcribing with WhisperKit: \(audioFileURL.lastPathComponent)")

        let result = try await pipe.transcribe(audioPath: audioFileURL.path)

        let text = (result?.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)

        Logger.transcription.info("WhisperKit transcription complete: \(text.count) characters")
        return text
    }
}
