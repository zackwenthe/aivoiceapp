import Foundation

/// Information about an available LLM model for text styling
struct ModelInfo: Identifiable {
    let id: String
    let name: String
    let description: String
    let sizeDescription: String
    let huggingFaceRepo: String
    let fileName: String
    let fileSizeBytes: Int64
    
    /// All available models for download
    static let availableModels: [ModelInfo] = [
        ModelInfo(
            id: "llama-3.2-1b",
            name: "Llama 3.2 1B",
            description: "Fast, lightweight model ideal for quick text formatting and basic styling tasks",
            sizeDescription: "~700 MB",
            huggingFaceRepo: "mlx-community/Llama-3.2-1B-Instruct-4bit",
            fileName: "model.safetensors",
            fileSizeBytes: 700_000_000
        ),
        ModelInfo(
            id: "llama-3.2-3b",
            name: "Llama 3.2 3B",
            description: "Balanced model with better quality output, suitable for most styling needs",
            sizeDescription: "~1.8 GB",
            huggingFaceRepo: "mlx-community/Llama-3.2-3B-Instruct-4bit",
            fileName: "model.safetensors",
            fileSizeBytes: 1_800_000_000
        ),
        ModelInfo(
            id: "phi-4-mini",
            name: "Phi-4 Mini",
            description: "Highest quality model with excellent reasoning, best for complex styling tasks",
            sizeDescription: "~2.2 GB",
            huggingFaceRepo: "mlx-community/Phi-4-mini-instruct-4bit",
            fileName: "model.safetensors",
            fileSizeBytes: 2_200_000_000
        )
    ]
}
