import Foundation
import WhisperKit
import OSLog

final class WhisperKitEngine: @unchecked Sendable {
    private var whisperKit: WhisperKit?

    var displayName: String { "WhisperKit (Large v3 Turbo)" }

    var isAvailable: Bool { whisperKit != nil }

    func loadModel() async throws {
        Logger.transcription.info("Loading WhisperKit model (large-v3_turbo)...")
        whisperKit = try await WhisperKit(model: "large-v3_turbo")
        Logger.transcription.info("WhisperKit model loaded successfully")
    }

    func transcribe(audioFileURL: URL) async throws -> String {
        guard let pipe = whisperKit else {
            throw DictateError.transcriptionEngineUnavailable
        }

        Logger.transcription.info("Transcribing with WhisperKit: \(audioFileURL.lastPathComponent)")

        let results: [TranscriptionResult] = try await pipe.transcribe(audioPath: audioFileURL.path)

        let text = results.map(\.text).joined(separator: " ").trimmingCharacters(in: .whitespacesAndNewlines)

        Logger.transcription.info("WhisperKit transcription complete: \(text.count) characters")
        return text
    }
}
