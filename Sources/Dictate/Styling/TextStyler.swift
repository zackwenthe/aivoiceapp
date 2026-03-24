import Foundation
import MLX
import MLXLLM
import MLXLMCommon
import OSLog

@Observable
final class TextStyler: @unchecked Sendable {
    enum State: Equatable {
        case notLoaded
        case loading
        case ready
        case error(String)
    }

    private(set) var state: State = .notLoaded
    private var modelContainer: ModelContainer?

    var isReady: Bool { state == .ready }

    func loadModel(from modelPath: String) async {
        state = .loading
        Logger.styling.info("Loading LLM model: \(modelPath)")

        do {
            let modelURL = URL(fileURLWithPath: modelPath)
            let configuration = ModelConfiguration(directory: modelURL)
            let container = try await LLMModelFactory.shared.loadContainer(configuration: configuration) { progress in
                Logger.styling.debug("Model loading progress: \(progress.fractionCompleted)")
            }
            self.modelContainer = container
            state = .ready
            Logger.styling.info("LLM model loaded successfully")
        } catch {
            Logger.styling.error("Failed to load LLM model: \(error.localizedDescription)")
            state = .error(error.localizedDescription)
        }
    }

    func style(text: String, style: TextStyle, customPrompt: String? = nil) async throws -> String {
        guard style.requiresLLM else { return text }

        guard let container = modelContainer, state == .ready else {
            throw DictateError.modelNotLoaded
        }

        let systemPrompt = StylePrompts.systemPrompt(for: style, customPrompt: customPrompt)
        let userMessage = StylePrompts.formatUserMessage(transcript: text)

        let messages: [[String: String]] = [
            ["role": "system", "content": systemPrompt],
            ["role": "user", "content": userMessage],
        ]

        Logger.styling.info("Generating styled text with style: \(style.rawValue)")

        let styledText = try await container.perform { context in
            let input = try await context.processor.prepare(input: .init(messages: messages))
            let stream = try MLXLMCommon.generate(input: input, parameters: .init(temperature: 0.3), context: context)
            var output = ""
            for await generation in stream {
                if let chunk = generation.chunk {
                    output += chunk
                    if output.count >= 2048 {
                        break
                    }
                }
            }
            return output.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        Logger.styling.info("Styled text generated: \(styledText.count) characters")
        return styledText
    }

    func unloadModel() {
        modelContainer = nil
        state = .notLoaded
        Logger.styling.info("LLM model unloaded")
    }
}
