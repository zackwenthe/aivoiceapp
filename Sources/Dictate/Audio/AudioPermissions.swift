import AVFoundation
import OSLog

struct AudioPermissions {
    static func requestMicrophoneAccess() async -> Bool {
        let status = AVCaptureDevice.authorizationStatus(for: .audio)

        switch status {
        case .authorized:
            return true
        case .notDetermined:
            return await AVCaptureDevice.requestAccess(for: .audio)
        case .denied, .restricted:
            Logger.audio.warning("Microphone access denied or restricted")
            return false
        @unknown default:
            return false
        }
    }

    static var isAuthorized: Bool {
        AVCaptureDevice.authorizationStatus(for: .audio) == .authorized
    }
}
