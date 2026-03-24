import AVFoundation
import Foundation
import Speech
import OSLog

struct SpeechAnalyzerEngine: TranscriptionEngine {
    var displayName: String { "Apple Speech Recognition" }

    /// Maximum chunk duration in seconds. Apple's on-device speech recognition
    /// silently truncates audio longer than ~60 seconds, so we split into
    /// smaller segments to ensure the full recording is transcribed.
    private static let maxChunkDuration: TimeInterval = 30

    var isAvailable: Bool {
        SFSpeechRecognizer(locale: Locale(identifier: "en-US"))?.isAvailable ?? false
    }

    func transcribe(audioFileURL: URL) async throws -> String {
        guard isAvailable else {
            throw DictateError.transcriptionEngineUnavailable
        }

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

        Logger.transcription.info("Starting transcription of \(audioFileURL.lastPathComponent)")

        // Split audio into chunks to avoid Apple's on-device recognition limit
        let chunkURLs = try splitAudioIntoChunks(audioFileURL: audioFileURL)
        defer {
            // Clean up any temporary chunk files
            for url in chunkURLs where url != audioFileURL {
                try? FileManager.default.removeItem(at: url)
            }
        }

        Logger.transcription.info("Audio split into \(chunkURLs.count) chunk(s)")

        var transcriptParts: [String] = []
        for (index, chunkURL) in chunkURLs.enumerated() {
            Logger.transcription.info("Transcribing chunk \(index + 1)/\(chunkURLs.count)")
            let part = try await transcribeChunk(recognizer: recognizer, audioFileURL: chunkURL)
            if !part.isEmpty {
                transcriptParts.append(part)
            }
        }

        let transcript = transcriptParts.joined(separator: " ")
        Logger.transcription.info("Transcription complete: \(transcript.count) characters")
        return transcript
    }

    // MARK: - Private

    private func transcribeChunk(recognizer: SFSpeechRecognizer, audioFileURL: URL) async throws -> String {
        let request = SFSpeechURLRecognitionRequest(url: audioFileURL)
        request.shouldReportPartialResults = false
        request.requiresOnDeviceRecognition = true

        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<String, Error>) in
            recognizer.recognitionTask(with: request) { result, error in
                if let error = error {
                    continuation.resume(throwing: DictateError.transcriptionFailed(error.localizedDescription))
                    return
                }

                guard let result = result, result.isFinal else {
                    return
                }

                let transcribedText = result.bestTranscription.formattedString
                continuation.resume(returning: transcribedText)
            }
        }
    }

    /// Splits an audio file into chunks of `maxChunkDuration` seconds.
    /// Returns the original URL in an array if the audio is short enough.
    private func splitAudioIntoChunks(audioFileURL: URL) throws -> [URL] {
        let sourceFile = try AVAudioFile(forReading: audioFileURL)
        let sampleRate = sourceFile.processingFormat.sampleRate
        let totalFrames = AVAudioFrameCount(sourceFile.length)
        let totalDuration = Double(totalFrames) / sampleRate

        guard totalDuration > Self.maxChunkDuration else {
            return [audioFileURL]
        }

        let framesPerChunk = AVAudioFrameCount(Self.maxChunkDuration * sampleRate)
        var chunkURLs: [URL] = []
        var framesRead: AVAudioFrameCount = 0
        var chunkIndex = 0

        while framesRead < totalFrames {
            let remainingFrames = totalFrames - framesRead
            let framesToRead = min(framesPerChunk, remainingFrames)

            guard let buffer = AVAudioPCMBuffer(pcmFormat: sourceFile.processingFormat, frameCapacity: framesToRead) else {
                throw DictateError.transcriptionFailed("Failed to allocate audio buffer for chunking")
            }

            try sourceFile.read(into: buffer, frameCount: framesToRead)

            let chunkURL = FileManager.default.temporaryDirectory
                .appendingPathComponent("dictate-chunk-\(chunkIndex)-\(UUID().uuidString).wav")

            let chunkFile = try AVAudioFile(
                forWriting: chunkURL,
                settings: [
                    AVFormatIDKey: kAudioFormatLinearPCM,
                    AVSampleRateKey: sampleRate,
                    AVNumberOfChannelsKey: sourceFile.processingFormat.channelCount,
                    AVLinearPCMBitDepthKey: 16,
                    AVLinearPCMIsFloatKey: false,
                    AVLinearPCMIsBigEndianKey: false,
                ]
            )

            try chunkFile.write(from: buffer)

            chunkURLs.append(chunkURL)
            framesRead += framesToRead
            chunkIndex += 1
        }

        return chunkURLs
    }
}
