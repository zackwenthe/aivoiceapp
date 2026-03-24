import Foundation
import WhisperKit
import OSLog

final class WhisperKitEngine: @unchecked Sendable {
    private var whisperKit: WhisperKit?

    var displayName: String { "WhisperKit (Large v3 Turbo)" }

    var isAvailable: Bool { whisperKit != nil }

    func loadModel() async throws {
        Logger.transcription.info("Loading WhisperKit model (large-v3_turbo)...")
        whisperKit = try await withThrowingTaskGroup(of: WhisperKit.self) { group in
            group.addTask {
                try await WhisperKit(model: "large-v3_turbo")
            }
            group.addTask {
                try await Task.sleep(for: .seconds(300))
                throw DictateError.modelDownloadFailed("Model download timed out after 5 minutes")
            }
            let result = try await group.next()!
            group.cancelAll()
            return result
        }
        Logger.transcription.info("WhisperKit model loaded successfully")
    }

    func transcribe(audioFileURL: URL, timeout: Duration = .seconds(120)) async throws -> String {
        guard let pipe = whisperKit else {
            throw DictateError.transcriptionEngineUnavailable
        }

        Logger.transcription.info("Transcribing with WhisperKit: \(audioFileURL.lastPathComponent)")

        let results: [TranscriptionResult] = try await withThrowingTaskGroup(of: [TranscriptionResult].self) { group in
            group.addTask {
                try await pipe.transcribe(audioPath: audioFileURL.path)
            }
            group.addTask {
                try await Task.sleep(for: timeout)
                throw DictateError.transcriptionFailed("Transcription timed out after \(timeout)")
            }
            // Return the first result; if timeout fires first, its error propagates
            let result = try await group.next()!
            group.cancelAll()
            return result
        }

        let text = results.map(\.text).joined(separator: " ").trimmingCharacters(in: .whitespacesAndNewlines)

        Logger.transcription.info("WhisperKit transcription complete: \(text.count) characters")
        return text
    }
}
