import SwiftUI

struct WaveformView: View {
    let level: Float
    let barCount: Int

    @State private var animatedLevels: [CGFloat]

    init(level: Float, barCount: Int = 5) {
        self.level = level
        self.barCount = barCount
        self._animatedLevels = State(initialValue: Array(repeating: 0.15, count: barCount))
    }

    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<barCount, id: \.self) { index in
                RoundedRectangle(cornerRadius: 1.5)
                    .fill(.primary)
                    .frame(width: 3, height: barHeight(for: index))
                    .animation(.easeInOut(duration: 0.15), value: animatedLevels[index])
            }
        }
        .frame(height: 20)
        .onChange(of: level) { _, newLevel in
            updateLevels(from: newLevel)
        }
    }

    private func barHeight(for index: Int) -> CGFloat {
        let minHeight: CGFloat = 4
        let maxHeight: CGFloat = 20
        return minHeight + (maxHeight - minHeight) * animatedLevels[index]
    }

    private func updateLevels(from level: Float) {
        let baseLevel = CGFloat(level)
        for i in 0..<barCount {
            // Create variation across bars for visual interest
            let offset = Double(i) / Double(barCount)
            let variation = sin(Date().timeIntervalSinceReferenceDate * 8 + offset * .pi * 2) * 0.3
            animatedLevels[i] = max(0.05, min(1.0, baseLevel + CGFloat(variation)))
        }
    }
}
