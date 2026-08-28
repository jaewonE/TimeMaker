import AppKit
import SwiftUI
import TimeMakerCore

struct ScrollWheelMonitor: NSViewRepresentable {
    let enabled: Bool
    let thresholdMultiplier: Int
    let onScroll: (ScrollDirection) -> Void

    func makeNSView(context: Context) -> ScrollCapturingView {
        let view = ScrollCapturingView()
        view.onScroll = onScroll
        view.enabled = enabled
        view.thresholdMultiplier = thresholdMultiplier
        return view
    }

    func updateNSView(_ nsView: ScrollCapturingView, context: Context) {
        nsView.onScroll = onScroll
        nsView.enabled = enabled
        nsView.thresholdMultiplier = thresholdMultiplier
    }

    final class ScrollCapturingView: NSView {
        var onScroll: ((ScrollDirection) -> Void)?
        var enabled = true
        var thresholdMultiplier = 1
        private var accumulatedDelta: CGFloat = 0

        override var acceptsFirstResponder: Bool { false }

        override func scrollWheel(with event: NSEvent) {
            guard enabled else {
                super.scrollWheel(with: event)
                return
            }

            accumulatedDelta += event.scrollingDeltaY
            let baselineThreshold: CGFloat = event.hasPreciseScrollingDeltas ? 8 : 1
            let threshold = baselineThreshold * CGFloat(max(thresholdMultiplier, 1))

            while abs(accumulatedDelta) >= threshold {
                let direction: ScrollDirection = accumulatedDelta > 0 ? .increase : .decrease
                onScroll?(direction)
                accumulatedDelta -= CGFloat(direction.rawValue) * threshold
            }

            if event.phase == .ended || event.momentumPhase == .ended {
                accumulatedDelta = 0
            }
        }
    }
}
