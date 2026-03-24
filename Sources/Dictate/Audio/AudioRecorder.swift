import AVFoundation
import OSLog

final class AudioRecorder: @unchecked Sendable {
    private var audioEngine: AVAudioEngine?
    private var audioFile: AVAudioFile?
    private var tempFileURL: URL?
    private var isRecording = false

    func startRecording(levelCallback: @escaping @Sendable (Float) -> Void) throws {
        guard !isRecording else {
            throw DictateError.recordingFailed("Already recording")
        }

        let engine = AVAudioEngine()
        let inputNode = engine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)

        // Create temp file for recording
        let tempDir = FileManager.default.temporaryDirectory
        let filename = "dictate-\(UUID().uuidString).wav"
        let fileURL = tempDir.appendingPathComponent(filename)

        // Create audio file with the input format
        let audioFile = try AVAudioFile(
            forWriting: fileURL,
            settings: [
                AVFormatIDKey: kAudioFormatLinearPCM,
                AVSampleRateKey: recordingFormat.sampleRate,
                AVNumberOfChannelsKey: 1,
                AVLinearPCMBitDepthKey: 16,
                AVLinearPCMIsFloatKey: false,
                AVLinearPCMIsBigEndianKey: false,
            ]
        )

        // Install tap to capture audio
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            // Write buffer to file
            do {
                try audioFile.write(from: buffer)
            } catch {
                Logger.audio.error("Failed to write audio buffer: \(error.localizedDescription)")
            }

            // Calculate audio level for waveform visualization
            guard let channelData = buffer.floatChannelData?[0] else { return }
            let frameLength = Int(buffer.frameLength)
            var sum: Float = 0
            for i in 0..<frameLength {
                sum += channelData[i] * channelData[i]
            }
            let rms = sqrt(sum / Float(frameLength))
            let level = max(0, min(1, rms * 5)) // Normalize to 0-1
            levelCallback(level)
        }

        try engine.start()

        self.audioEngine = engine
        self.audioFile = audioFile
        self.tempFileURL = fileURL
        self.isRecording = true

        Logger.audio.info("Recording started: \(fileURL.lastPathComponent)")
    }

    func stopRecording() -> URL? {
        guard isRecording else { return nil }

        audioEngine?.inputNode.removeTap(onBus: 0)
        audioEngine?.stop()
        audioEngine = nil
        audioFile = nil
        isRecording = false

        let url = tempFileURL
        tempFileURL = nil

        Logger.audio.info("Recording stopped")
        return url
    }
}
