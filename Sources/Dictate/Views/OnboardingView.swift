import SwiftUI
import KeyboardShortcuts

struct OnboardingView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismissWindow) private var dismissWindow
    @State private var currentStep = 0
    @State private var micPermissionGranted = false
    @State private var outputFolderPath = ""
    @State private var saveMarkdown = true

    private let totalSteps = 4

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                ForEach(0..<totalSteps, id: \.self) { step in
                    Capsule()
                        .fill(step <= currentStep ? Color.accentColor : Color.secondary.opacity(0.3))
                        .frame(height: 3)
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)

            // Content
            TabView(selection: $currentStep) {
                welcomeStep.tag(0)
                microphoneStep.tag(1)
                hotkeyStep.tag(2)
                outputStep.tag(3)
            }
            .tabViewStyle(.automatic)
            .frame(width: 500, height: 340)

            // Navigation
            HStack {
                if currentStep > 0 {
                    Button("Back") {
                        withAnimation { currentStep -= 1 }
                    }
                }
                Spacer()
                if currentStep < totalSteps - 1 {
                    Button("Next") {
                        withAnimation { currentStep += 1 }
                    }
                    .buttonStyle(.borderedProminent)
                } else {
                    Button("Get Started") {
                        completeOnboarding()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding(24)
        }
        .frame(width: 500, height: 420)
    }

    // MARK: - Steps

    @ViewBuilder
    private var welcomeStep: some View {
        VStack(spacing: 16) {
            Image(systemName: "waveform")
                .font(.system(size: 60))
                .foregroundStyle(.tint)

            Text("Welcome to Dictate")
                .font(.largeTitle.bold())

            Text("Record your voice, transcribe it locally, style it, and paste anywhere.")
                .font(.title3)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .padding()
    }

    @ViewBuilder
    private var microphoneStep: some View {
        VStack(spacing: 16) {
            Image(systemName: "mic.circle.fill")
                .font(.system(size: 50))
                .foregroundStyle(micPermissionGranted ? .green : .orange)

            Text("Microphone Access")
                .font(.title2.bold())

            Text("Dictate needs microphone access to record your voice for transcription. All processing happens locally on your Mac.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            if micPermissionGranted {
                Label("Microphone access granted", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            } else {
                Button("Grant Microphone Access") {
                    Task {
                        micPermissionGranted = await AudioPermissions.requestMicrophoneAccess()
                    }
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .onAppear {
            micPermissionGranted = AudioPermissions.isAuthorized
        }
    }

    @ViewBuilder
    private var hotkeyStep: some View {
        VStack(spacing: 16) {
            Image(systemName: "keyboard")
                .font(.system(size: 50))
                .foregroundStyle(.tint)

            Text("Set Your Hotkey")
                .font(.title2.bold())

            Text("Choose a global keyboard shortcut to toggle recording. Press once to start, press again to stop.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            HStack {
                Text("Shortcut:")
                KeyboardShortcuts.Recorder(for: .toggleRecording)
            }
            .padding()

            Text("Default: ⌥R (Option + R)")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding()
    }

    @ViewBuilder
    private var outputStep: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text")
                .font(.system(size: 50))
                .foregroundStyle(.tint)

            Text("Save Transcriptions")
                .font(.title2.bold())

            Text("Transcriptions are always copied to your clipboard. You can also save markdown files to a folder.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Toggle("Save markdown files", isOn: $saveMarkdown)

            if saveMarkdown {
                HStack {
                    TextField("Choose a folder...", text: $outputFolderPath)
                        .textFieldStyle(.roundedBorder)
                        .disabled(true)

                    Button("Choose...") {
                        chooseFolder()
                    }
                }
                .padding(.horizontal, 40)
            }
        }
        .padding()
    }

    // MARK: - Actions

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

    private func completeOnboarding() {
        appState.saveMarkdownFiles = saveMarkdown
        appState.completeOnboarding()
        dismissWindow(id: "onboarding")
    }
}
