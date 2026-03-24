import SwiftUI
import KeyboardShortcuts

struct MenuBarView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.openSettings) private var openSettings
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Status section
            statusSection

            Divider()

            // Style picker
            styleSection

            Divider()

            // Recent transcriptions
            if !appState.recentTranscriptions.isEmpty {
                recentSection
                Divider()
            }

            // Actions
            actionsSection
        }
        .frame(width: 280)
    }

    @ViewBuilder
    private var statusSection: some View {
        HStack {
            Image(systemName: statusIcon)
                .foregroundStyle(statusColor)
            Text(statusText)
                .font(.headline)
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    @ViewBuilder
    private var styleSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Style")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 12)
                .padding(.top, 6)

            ForEach(TextStyle.allCases) { style in
                Button {
                    appState.selectedStyle = style
                    UserDefaults.standard.set(style.rawValue, forKey: UserDefaults.Keys.defaultStyleRawValue)
                } label: {
                    HStack {
                        Text(style.displayName)
                        Spacer()
                        if appState.selectedStyle == style {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.blue)
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 2)
            }
        }
        .padding(.bottom, 6)
    }

    @ViewBuilder
    private var recentSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Recent")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 12)
                .padding(.top, 6)

            ForEach(appState.recentTranscriptions.prefix(5)) { record in
                Button {
                    // Copy this transcription to clipboard again
                    ClipboardManager().copy(record.preview)
                } label: {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(record.preview)
                            .lineLimit(1)
                            .font(.caption)
                        Text(record.date, style: .relative)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 2)
            }
        }
        .padding(.bottom, 6)
    }

    @ViewBuilder
    private var actionsSection: some View {
        Button("Settings...") {
            openSettings()
        }
        .keyboardShortcut(",", modifiers: .command)
        .padding(.horizontal, 12)
        .padding(.vertical, 4)

        Divider()

        Button("Quit Dictate") {
            NSApplication.shared.terminate(nil)
        }
        .keyboardShortcut("q", modifiers: .command)
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
        .padding(.bottom, 4)
    }

    private var statusIcon: String {
        switch appState.phase {
        case .idle: return "waveform"
        case .recording: return "mic.fill"
        case .transcribing, .styling: return "ellipsis.circle"
        case .done: return "checkmark.circle.fill"
        case .error: return "exclamationmark.triangle"
        }
    }

    private var statusColor: Color {
        switch appState.phase {
        case .idle: return .secondary
        case .recording: return .red
        case .transcribing, .styling: return .blue
        case .done: return .green
        case .error: return .yellow
        }
    }

    private var statusText: String {
        switch appState.phase {
        case .idle: return "Ready"
        case .recording: return "Recording..."
        case .transcribing: return "Transcribing..."
        case .styling: return "Styling..."
        case .done: return "Done!"
        case .error(let msg): return msg
        }
    }
}
