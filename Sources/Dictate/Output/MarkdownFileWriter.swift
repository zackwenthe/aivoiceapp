import Foundation
import OSLog

struct MarkdownFileWriter {
    static func save(text: String, rawTranscript: String, style: TextStyle, to folder: URL) throws {
        // Ensure the output folder exists
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)

        let timestamp = ISO8601DateFormatter().string(from: Date())
        let safeTimestamp = timestamp
            .replacingOccurrences(of: ":", with: "-")
            .replacingOccurrences(of: "+", with: "")
        let filename = "dictate-\(safeTimestamp).md"
        let fileURL = folder.appendingPathComponent(filename)

        var content = """
        ---
        date: \(timestamp)
        style: \(style.rawValue)
        app: Dictate
        ---

        """

        if style != .plain && text != rawTranscript {
            content += """
            ## Styled Output

            \(text)

            ---

            ## Raw Transcript

            \(rawTranscript)
            """
        } else {
            content += text
        }

        content += "\n"

        do {
            try content.write(to: fileURL, atomically: true, encoding: .utf8)
            Logger.app.info("Markdown saved: \(fileURL.lastPathComponent)")
        } catch {
            throw DictateError.fileWriteFailed(error.localizedDescription)
        }
    }
}
