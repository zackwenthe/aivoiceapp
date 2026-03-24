import Foundation

public enum TextStyle: String, CaseIterable, Codable, Identifiable, Sendable {
    case plain
    case simplify
    case structured
    case email
    case bullets
    case custom

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .plain: return "Plain"
        case .simplify: return "Simplify"
        case .structured: return "Structured"
        case .email: return "Email Draft"
        case .bullets: return "Bullet Points"
        case .custom: return "Custom"
        }
    }

    public var description: String {
        switch self {
        case .plain: return "Raw transcript with no modifications"
        case .simplify: return "Clean up grammar, remove filler words"
        case .structured: return "Add headings and organize into sections"
        case .email: return "Format as a professional email draft"
        case .bullets: return "Summarize as bullet points"
        case .custom: return "Apply your custom prompt"
        }
    }

    public var requiresLLM: Bool {
        self != .plain
    }
}
