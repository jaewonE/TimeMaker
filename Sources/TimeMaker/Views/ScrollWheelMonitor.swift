import AppKit
import SwiftUI
import TimeMakerCore

struct ScrollWheelMonitor: NSViewRepresentable {
    let enabled: Bool
    let clickEnabled: Bool
    let thresholdMultiplier: Double
    let onScroll: (ScrollDirection) -> Void
    let onClick: () -> Void

    func makeNSView(context: Context) -> ScrollCapturingView {
        let view = ScrollCapturingView()
        view.onScroll = onScroll
        view.onClick = onClick
        view.enabled = enabled
        view.clickEnabled = clickEnabled
        view.thresholdMultiplier = thresholdMultiplier
        return view
    }

    func updateNSView(_ nsView: ScrollCapturingView, context: Context) {
        nsView.onScroll = onScroll
        nsView.onClick = onClick
        nsView.enabled = enabled
        nsView.clickEnabled = clickEnabled
        nsView.thresholdMultiplier = thresholdMultiplier
    }

    final class ScrollCapturingView: NSView {
        var onScroll: ((ScrollDirection) -> Void)?
        var onClick: (() -> Void)?
        var enabled = true
        var clickEnabled = false
        var thresholdMultiplier = 1.0
        private var accumulatedDelta: CGFloat = 0

        override var acceptsFirstResponder: Bool { false }

        override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
            clickEnabled
        }

        override func mouseDown(with event: NSEvent) {
            guard clickEnabled else {
                super.mouseDown(with: event)
                return
            }
            onClick?()
        }

        override func scrollWheel(with event: NSEvent) {
            guard enabled else {
                super.scrollWheel(with: event)
                return
            }

            accumulatedDelta += event.scrollingDeltaY
            let baselineThreshold: CGFloat = event.hasPreciseScrollingDeltas ? 8 : 1
            let threshold = baselineThreshold * CGFloat(max(thresholdMultiplier, 0.5))

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
