import Foundation

protocol TranscriptionEngine: Sendable {
    func transcribe(audioFileURL: URL) async throws -> String
    var isAvailable: Bool { get }
    var displayName: String { get }
}
