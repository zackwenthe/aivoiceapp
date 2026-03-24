import Foundation
import Speech
import OSLog

struct SpeechAnalyzerEngine: TranscriptionEngine {
    var displayName: String { "Apple Speech Recognition" }

    var isAvailable: Bool {
        SFSpeechRecognizer(locale: Locale(identifier: "en-US"))?.isAvailable ?? false
    }

    func transcribe(audioFileURL: URL) async throws -> String {
        guard isAvailable else {
            throw DictateError.transcriptionEngineUnavailable
        }

        // Request speech recognition authorization if needed
        let authStatus = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }

        guard authStatus == .authorized else {
            throw DictateError.transcriptionFailed("Speech recognition not authorized")
        }

        guard let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US")) else {
            throw DictateError.transcriptionEngineUnavailable
        }

        let request = SFSpeechURLRecognitionRequest(url: audioFileURL)
        request.shouldReportPartialResults = false
        request.requiresOnDeviceRecognition = true // Force on-device for privacy

        Logger.transcription.info("Starting transcription of \(audioFileURL.lastPathComponent)")

        let result = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<SFSpeechRecognitionResult, Error>) in
            recognizer.recognitionTask(with: request) { result, error in
                if let error = error {
                    continuation.resume(throwing: DictateError.transcriptionFailed(error.localizedDescription))
                    return
                }

                guard let result = result, result.isFinal else {
                    return
                }

                continuation.resume(returning: result)
            }
        }

        let transcript = result.bestTranscription.formattedString
        Logger.transcription.info("Transcription complete: \(transcript.count) characters")
        return transcript
    }
}
