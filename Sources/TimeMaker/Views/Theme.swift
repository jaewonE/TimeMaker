import SwiftUI

enum TimeMakerTheme {
    static let accent = Color(red: 0.56, green: 0.47, blue: 0.71)
    static let accentDark = Color(red: 0.39, green: 0.27, blue: 0.56)
    static let accentSoft = Color(red: 0.87, green: 0.84, blue: 0.92)
    static let panelLight = Color(red: 245.0 / 255.0, green: 245.0 / 255.0, blue: 245.0 / 255.0)
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
