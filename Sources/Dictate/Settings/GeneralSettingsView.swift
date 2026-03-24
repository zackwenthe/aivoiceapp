import SwiftUI
import KeyboardShortcuts
import ServiceManagement

struct GeneralSettingsView: View {
    @Environment(AppState.self) private var appState
    @State private var outputFolderPath: String = UserDefaults.standard.string(forKey: UserDefaults.Keys.outputFolderPath) ?? ""
    @State private var launchAtLogin: Bool = UserDefaults.standard.bool(forKey: UserDefaults.Keys.launchAtLogin)
    @State private var saveMarkdown: Bool = UserDefaults.standard.bool(forKey: UserDefaults.Keys.saveMarkdownFiles)

    var body: some View {
        Form {
            Section("Keyboard Shortcut") {
                HStack {
                    Text("Toggle Recording:")
                    Spacer()
                    KeyboardShortcuts.Recorder(for: .toggleRecording)
                }
            }

            Section("Output") {
                Toggle("Save markdown files", isOn: $saveMarkdown)
                    .onChange(of: saveMarkdown) { _, newValue in
                        appState.saveMarkdownFiles = newValue
                    }

                if saveMarkdown {
                    HStack {
                        TextField("Output folder", text: $outputFolderPath)
                            .textFieldStyle(.roundedBorder)
                            .disabled(true)

                        Button("Choose...") {
                            chooseFolder()
                        }
                    }

                    if !outputFolderPath.isEmpty {
                        Text(outputFolderPath)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Section("System") {
                Toggle("Launch at login", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { _, newValue in
                        UserDefaults.standard.set(newValue, forKey: UserDefaults.Keys.launchAtLogin)
                        updateLoginItem(enabled: newValue)
                    }
            }
        }
        .formStyle(.grouped)
        .padding()
    }

    private func chooseFolder() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.canCreateDirectories = true
        panel.allowsMultipleSelection = false
        panel.title = "Choose Output Folder"
        panel.prompt = "Select"

        if panel.runModal() == .OK, let url = panel.url {
            outputFolderPath = url.path
            appState.setOutputFolder(url)
        }
    }

    private func updateLoginItem(enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            // Login item management may fail in development
        }
    }
}
