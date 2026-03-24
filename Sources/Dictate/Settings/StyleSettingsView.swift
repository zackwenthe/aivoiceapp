import SwiftUI

struct StyleSettingsView: View {
    @Environment(AppState.self) private var appState
    @State private var customPrompt: String = UserDefaults.standard.string(forKey: UserDefaults.Keys.customStylePrompt) ?? ""

    var body: some View {
        Form {
            Section("Default Style") {
                Picker("Style", selection: Bindable(appState).selectedStyle) {
                    ForEach(TextStyle.allCases) { style in
                        Text(style.displayName).tag(style)
                    }
                }
                .onChange(of: appState.selectedStyle) { _, newValue in
                    UserDefaults.standard.set(newValue.rawValue, forKey: UserDefaults.Keys.defaultStyleRawValue)
                }

                Text(appState.selectedStyle.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if appState.selectedStyle.requiresLLM {
                    Label("Requires a downloaded LLM model", systemImage: "cpu")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }

            Section("Custom Prompt") {
                Text("Used when the 'Custom' style is selected")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                TextEditor(text: $customPrompt)
                    .frame(minHeight: 100)
                    .font(.body.monospaced())
                    .onChange(of: customPrompt) { _, newValue in
                        UserDefaults.standard.set(newValue, forKey: UserDefaults.Keys.customStylePrompt)
                    }
            }

            Section("Style Descriptions") {
                ForEach(TextStyle.allCases) { style in
                    HStack(alignment: .top) {
                        Text(style.displayName)
                            .fontWeight(.medium)
                            .frame(width: 100, alignment: .leading)
                        Text(style.description)
                            .foregroundStyle(.secondary)
                    }
                    .font(.caption)
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}
