import SwiftUI
import KeyboardShortcuts

extension KeyboardShortcuts.Name {
    static let toggleRecording = Self("toggleRecording", default: .init(.r, modifiers: [.option]))
}

@main
struct DictateApp: App {
    @State private var appState = AppState()
    @State private var modelManager = ModelManager()
    @State private var textStyler = TextStyler()

    var body: some Scene {
        MenuBarExtra("Dictate", systemImage: menuBarIcon) {
            MenuBarView()
                .environment(appState)
                .onAppear {
                    setupHotkey()
                    if appState.isFirstLaunch {
                        // Onboarding will be shown via openWindow
                    }
                    // Load LLM model if one was previously selected
                    Task {
                        await modelManager.loadSelectedModel(into: textStyler)
                        await MainActor.run {
                            appState.setTextStyler(textStyler)
                        }
                    }
                }
        }

        Window("Recording", id: "overlay") {
            RecordingOverlay()
                .environment(appState)
        }
        .windowStyle(.plain)
        .windowResizability(.contentSize)

        Settings {
            SettingsView()
                .environment(appState)
        }

        Window("Welcome to Dictate", id: "onboarding") {
            OnboardingView()
                .environment(appState)
        }
        .windowResizability(.contentSize)
    }

    private var menuBarIcon: String {
        switch appState.phase {
        case .recording:
            return "mic.fill"
        case .transcribing, .styling:
            return "ellipsis.circle"
        case .done:
            return "checkmark.circle"
        case .error:
            return "exclamationmark.triangle"
        case .idle:
            return "waveform"
        }
    }

    private func setupHotkey() {
        KeyboardShortcuts.onKeyDown(for: .toggleRecording) { [appState] in
            Task { @MainActor in
                appState.toggleRecording()
            }
        }
    }
}
