import SwiftUI

struct TodayProgressDots: View {
    let totalSeconds: Int

    private var fullHours: Int { max(totalSeconds, 0) / 3_600 }
    private var remainder: Int { max(totalSeconds, 0) % 3_600 }
    private var itemCount: Int { fullHours + (remainder > 0 ? 1 : 0) }

    var body: some View {
        GeometryReader { proxy in
            let count = max(itemCount, 1)
            let spacing: CGFloat = count > 16 ? 4 : 8
            let available = proxy.size.width - (CGFloat(count - 1) * spacing)
            let diameter = min(max(available / CGFloat(count), 5), 12)

            HStack(spacing: spacing) {
                if itemCount > 0 {
                    ForEach(0..<fullHours, id: \.self) { _ in
                        Circle()
                            .fill(TimeMakerTheme.accentSoft)
                            .frame(width: diameter, height: diameter)
                    }

                    if remainder > 0 {
                        ZStack {
                            Circle()
                                .stroke(
                                    TimeMakerTheme.accentSoft,
                                    style: StrokeStyle(lineWidth: 1.25, dash: [2, 2])
                                )
                            PieSlice(fraction: Double(remainder) / 3_600)
                                .fill(TimeMakerTheme.accentSoft)
                        }
                        .frame(width: diameter, height: diameter)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(width: 250, height: 14)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("progress.today"))
        .accessibilityValue(Text(progressAccessibilityValue))
    }

    private var progressAccessibilityValue: String {
        let hours = max(totalSeconds, 0) / 3_600
        let minutes = (max(totalSeconds, 0) % 3_600) / 60
        return String(
            format: NSLocalizedString("progress.value", comment: ""),
            hours,
            minutes
        )
    }
}

private struct PieSlice: Shape {
    let fraction: Double

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        let start = Angle.degrees(-90)
        let end = Angle.degrees(-90 + (360 * min(max(fraction, 0), 1)))

        path.move(to: center)
        path.addLine(to: CGPoint(x: center.x, y: center.y - radius))
        path.addArc(center: center, radius: radius, startAngle: start, endAngle: end, clockwise: false)
        path.closeSubpath()
        return path
    }
}
