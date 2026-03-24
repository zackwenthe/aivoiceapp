import AppKit
import OSLog

struct ClipboardManager {
    func copy(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
        Logger.app.info("Text copied to clipboard (\(text.count) characters)")
    }
}
