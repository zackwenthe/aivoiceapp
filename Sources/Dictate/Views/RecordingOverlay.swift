import SwiftUI

struct RecordingOverlay: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        Group {
            if appState.phase != .idle {
                overlayContent
                    .transition(.opacity.combined(with: .scale(scale: 0.9)))
            }
        }
        .animation(.easeInOut(duration: 0.25), value: appState.phase)
        .frame(minWidth: 200)
    }

    @ViewBuilder
    private var overlayContent: some View {
        HStack(spacing: 12) {
            phaseIcon
            phaseLabel
        }
        .glassCard()
    }

    @ViewBuilder
    private var phaseIcon: some View {
        switch appState.phase {
        case .recording:
            Image(systemName: "mic.fill")
                .foregroundStyle(.red)
                .symbolEffect(.pulse, isActive: true)
        case .transcribing:
            ProgressView()
                .controlSize(.small)
        case .styling:
            ProgressView()
                .controlSize(.small)
        case .done:
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
        case .error:
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.yellow)
        case .idle:
            EmptyView()
        }
    }

    @ViewBuilder
    private var phaseLabel: some View {
        switch appState.phase {
        case .recording:
            HStack(spacing: 8) {
                Text("Recording...")
                WaveformView(level: appState.audioLevel)
            }
        case .transcribing:
            Text("Transcribing...")
        case .styling:
            Text("Styling text...")
        case .done:
            Text("Copied to clipboard!")
                .foregroundStyle(.green)
        case .error(let message):
            Text(message)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        case .idle:
            EmptyView()
        }
    }
}
