import SwiftUI
import TimeMakerCore

struct ScrollSensitivitySlider: View {
    @Binding var sensitivity: ScrollSensitivity

    private let options = ScrollSensitivity.allCases

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Slider(value: selectionIndex, in: 0...Double(options.count - 1), step: 1)
                .tint(TimeMakerTheme.accent)
                .controlSize(.small)
                .frame(width: 184)

            HStack(spacing: 0) {
                ForEach(options.indices, id: \.self) { index in
                    Rectangle()
                        .fill(Color.secondary.opacity(0.55))
                        .frame(width: 1, height: 3)

                    if index != options.indices.last {
                        Spacer(minLength: 0)
                    }
                }
            }
            .padding(.horizontal, 8)
            .frame(width: 184)

            HStack {
                Text("settings.scrollSensitivity.shortLabel")
                Spacer(minLength: 8)
                Text(displayValue)
                    .monospacedDigit()
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            .frame(width: 184)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("settings.scrollSensitivity"))
        .accessibilityValue(Text(displayValue))
    }

    private var selectionIndex: Binding<Double> {
        Binding(
            get: {
                Double(options.firstIndex(of: sensitivity) ?? 1)
            },
            set: { rawIndex in
                let index = min(max(Int(rawIndex.rounded()), 0), options.count - 1)
                sensitivity = options[index]
            }
        )
    }

    private var displayValue: String {
        if sensitivity == .half {
            return "0.5×"
        }
        return "\(Int(sensitivity.rawValue))×"
    }
}
