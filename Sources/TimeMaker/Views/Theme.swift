import SwiftUI

enum TimeMakerTheme {
    static let accent = Color(red: 0.35, green: 0.62, blue: 0.57)
    static let accentDark = Color(red: 0.12, green: 0.46, blue: 0.40)
    static let accentSoft = Color(red: 0.79, green: 0.87, blue: 0.85)
    static let panelLight = Color(red: 0.96, green: 0.97, blue: 0.97)
}

extension View {
    func timeMakerCard() -> some View {
        self
            .background(.thinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.primary.opacity(0.06), lineWidth: 1)
            }
    }
}
