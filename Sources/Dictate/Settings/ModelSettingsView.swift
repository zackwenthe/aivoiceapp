import SwiftUI

struct ModelSettingsView: View {
    @Environment(AppState.self) private var appState
    @State private var modelManager = ModelManager()

    var body: some View {
        Form {
            Section("LLM Model") {
                Text("A local LLM is required for text styling (all styles except Plain).")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                ForEach(ModelInfo.availableModels) { model in
                    modelRow(model)
                }
            }

            Section("Info") {
                Label("Models are downloaded from Hugging Face and stored locally.", systemImage: "info.circle")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Label("Models run entirely on-device using Apple Silicon GPU.", systemImage: "cpu")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .padding()
    }

    @ViewBuilder
    private func modelRow(_ model: ModelInfo) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(model.name)
                        .fontWeight(.medium)
                    if modelManager.selectedModelID == model.id {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                            .font(.caption)
                    }
                }

                Text(model.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text("Size: \(model.sizeDescription)")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            Spacer()

            modelAction(for: model)
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private func modelAction(for model: ModelInfo) -> some View {
        let state = modelManager.downloadStates[model.id] ?? .notDownloaded

        switch state {
        case .notDownloaded:
            Button("Download") {
                Task {
                    await modelManager.downloadModel(model)
                }
            }

        case .downloading(let progress):
            VStack(spacing: 4) {
                ProgressView(value: progress)
                    .frame(width: 80)
                Text("\(Int(progress * 100))%")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

        case .downloaded:
            if modelManager.selectedModelID == model.id {
                Text("Active")
                    .font(.caption)
                    .foregroundStyle(.green)
            } else {
                Button("Select") {
                    modelManager.selectedModelID = model.id
                    Task {
                        let styler = TextStyler()
                        await modelManager.loadSelectedModel(into: styler)
                        await MainActor.run {
                            appState.setTextStyler(styler)
                        }
                    }
                }
            }

        case .error(let message):
            VStack(spacing: 4) {
                Image(systemName: "exclamationmark.triangle")
                    .foregroundStyle(.red)
                Button("Retry") {
                    Task {
                        await modelManager.downloadModel(model)
                    }
                }
                .font(.caption)
            }
        }
    }
}
