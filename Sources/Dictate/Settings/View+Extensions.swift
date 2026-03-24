import SwiftUI

extension View {
    /// Applies a glass card effect with blur, padding, and shadow
    func glassCard() -> some View {
        self
            .padding(12)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
    }
}
