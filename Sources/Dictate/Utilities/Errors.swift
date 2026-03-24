import Foundation

enum DictateError: LocalizedError {
    case microphoneAccessDenied
    case recordingFailed(String)
    case transcriptionFailed(String)
    case transcriptionEngineUnavailable
    case stylingFailed(String)
    case modelNotLoaded
    case modelDownloadFailed(String)
    case fileWriteFailed(String)

    var errorDescription: String? {
        switch self {
        case .microphoneAccessDenied:
            return "Microphone access denied. Please grant access in System Settings > Privacy & Security > Microphone."
        case .recordingFailed(let detail):
            return "Recording failed: \(detail)"
        case .transcriptionFailed(let detail):
            return "Transcription failed: \(detail)"
        case .transcriptionEngineUnavailable:
            return "Speech recognition is not available on this system."
        case .stylingFailed(let detail):
            return "Text styling failed: \(detail)"
        case .modelNotLoaded:
            return "LLM model is not loaded. Please download a model in Settings."
        case .modelDownloadFailed(let detail):
            return "Model download failed: \(detail)"
        case .fileWriteFailed(let detail):
            return "Failed to save markdown file: \(detail)"
        }
    }
}
