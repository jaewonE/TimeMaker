import SwiftUI
import TimeMakerCore

struct TodayProgressDots: View {
    let totalSeconds: Int

    private let dotDiameter: CGFloat = 6
    private let dotSpacing: CGFloat = 3

    private var fullHours: Int { max(totalSeconds, 0) / 3_600 }
    private var remainder: Int { max(totalSeconds, 0) % 3_600 }
    private var itemCount: Int { fullHours + (remainder > 0 ? 1 : 0) }
    private var rowCount: Int { ProgressDotLayout.rowCount(for: itemCount) }
    private var columnCount: Int { ProgressDotLayout.columnCount(for: itemCount) }
    private var gridWidth: CGFloat {
        (CGFloat(columnCount) * dotDiameter) + (CGFloat(columnCount - 1) * dotSpacing)
    }
    private var gridHeight: CGFloat {
        (CGFloat(rowCount) * dotDiameter) + (CGFloat(rowCount - 1) * dotSpacing)
    }
    private var rows: [GridItem] {
        Array(
            repeating: GridItem(.fixed(dotDiameter), spacing: dotSpacing),
            count: rowCount
        )
    }

    var body: some View {
        Group {
            if itemCount > 0 {
                LazyHGrid(rows: rows, alignment: .top, spacing: dotSpacing) {
                    ForEach(0..<fullHours, id: \.self) { _ in
                        Circle()
                            .fill(TimeMakerTheme.accentSoft)
                            .frame(width: dotDiameter, height: dotDiameter)
                    }

                    if remainder > 0 {
                        ZStack {
                            Circle()
                                .stroke(
                                    TimeMakerTheme.accentSoft,
                                    style: StrokeStyle(lineWidth: 1, dash: [1.5, 1.5])
                                )
                            PieSlice(fraction: Double(remainder) / 3_600)
                                .fill(TimeMakerTheme.accentSoft)
                        }
                        .frame(width: dotDiameter, height: dotDiameter)
                    }
                }
            }
        }
        .frame(width: gridWidth, height: gridHeight, alignment: .topLeading)
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
