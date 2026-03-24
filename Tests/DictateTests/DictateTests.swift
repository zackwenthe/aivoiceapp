import Testing
import DictateLib

@Suite("Dictate Tests")
struct DictateTests {
    @Test("TextStyle has correct display names")
    func textStyleDisplayNames() {
        #expect(TextStyle.plain.displayName == "Plain")
        #expect(TextStyle.email.displayName == "Email Draft")
        #expect(TextStyle.bullets.displayName == "Bullet Points")
    }

    @Test("Plain style does not require LLM")
    func plainStyleNoLLM() {
        #expect(!TextStyle.plain.requiresLLM)
    }

    @Test("All non-plain styles require LLM")
    func nonPlainStylesRequireLLM() {
        for style in TextStyle.allCases where style != .plain {
            #expect(style.requiresLLM, "Expected \(style.rawValue) to require LLM")
        }
    }

    @Test("StylePrompts returns non-empty prompts for LLM styles")
    func stylePromptsNotEmpty() {
        for style in TextStyle.allCases where style.requiresLLM {
            let prompt = StylePrompts.systemPrompt(for: style)
            #expect(!prompt.isEmpty, "Expected non-empty prompt for \(style.rawValue)")
        }
    }
}
