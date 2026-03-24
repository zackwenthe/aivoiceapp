import OSLog

extension Logger {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.dictate.app"

    static let app = Logger(subsystem: subsystem, category: "app")
    static let audio = Logger(subsystem: subsystem, category: "audio")
    static let transcription = Logger(subsystem: subsystem, category: "transcription")
    static let styling = Logger(subsystem: subsystem, category: "styling")
    static let models = Logger(subsystem: subsystem, category: "models")
    static let ui = Logger(subsystem: subsystem, category: "ui")
}
