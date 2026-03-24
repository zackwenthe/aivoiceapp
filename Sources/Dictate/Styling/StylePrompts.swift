import Foundation

public struct StylePrompts {
    public static func systemPrompt(for style: TextStyle, customPrompt: String? = nil) -> String {
        switch style {
        case .plain:
            return "" // Should never be called for plain
        case .simplify:
            return """
            You are a text editor. Clean up the following voice transcript:
            - Fix grammar and punctuation
            - Remove filler words (um, uh, like, you know, etc.)
            - Keep the original meaning and tone
            - Do not add new information
            - Return only the cleaned text, nothing else
            """
        case .structured:
            return """
            You are a text organizer. Take the following voice transcript and restructure it:
            - Add a brief title as a heading
            - Organize into logical sections with headings
            - Use bullet points where appropriate
            - Fix grammar and punctuation
            - Keep all original information
            - Return only the structured text in markdown format
            """
        case .email:
            return """
            You are a professional email writer. Convert the following voice transcript into a well-formatted email:
            - Add an appropriate subject line as a heading
            - Include a professional greeting
            - Organize the content into clear paragraphs
            - Add a professional closing
            - Fix grammar and maintain a professional tone
            - Return only the email text, nothing else
            """
        case .bullets:
            return """
            You are a summarizer. Convert the following voice transcript into concise bullet points:
            - Extract the key points and ideas
            - Each bullet should be a clear, complete thought
            - Group related points together
            - Fix grammar and punctuation
            - Return only the bullet points, nothing else
            """
        case .custom:
            return customPrompt ?? "Clean up the following transcript and improve its formatting."
        }
    }

    public static func formatUserMessage(transcript: String) -> String {
        return "Here is the voice transcript to process:\n\n\(transcript)"
    }
}
