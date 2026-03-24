import Foundation

extension UserDefaults {
    enum Keys {
        static let hasCompletedOnboarding = "hasCompletedOnboarding"
        static let outputFolderPath = "outputFolderPath"
        static let defaultStyleRawValue = "defaultStyleRawValue"
        static let customStylePrompt = "customStylePrompt"
        static let selectedLLMModel = "selectedLLMModel"
        static let launchAtLogin = "launchAtLogin"
        static let saveMarkdownFiles = "saveMarkdownFiles"
    }
}
