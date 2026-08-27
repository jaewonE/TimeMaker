import AppKit
import SwiftUI
import TimeMakerCore

struct ScrollWheelMonitor: NSViewRepresentable {
    let enabled: Bool
    let onScroll: (ScrollDirection) -> Void

    func makeNSView(context: Context) -> ScrollCapturingView {
        let view = ScrollCapturingView()
        view.onScroll = onScroll
        view.enabled = enabled
        return view
    }

    func updateNSView(_ nsView: ScrollCapturingView, context: Context) {
        nsView.onScroll = onScroll
        nsView.enabled = enabled
    }

    final class ScrollCapturingView: NSView {
        var onScroll: ((ScrollDirection) -> Void)?
        var enabled = true
        private var accumulatedDelta: CGFloat = 0

        override var acceptsFirstResponder: Bool { false }

        override func scrollWheel(with event: NSEvent) {
            guard enabled else {
                super.scrollWheel(with: event)
                return
            }

            accumulatedDelta += event.scrollingDeltaY
            let threshold: CGFloat = event.hasPreciseScrollingDeltas ? 8 : 1

            if abs(accumulatedDelta) >= threshold {
                onScroll?(accumulatedDelta > 0 ? .increase : .decrease)
                accumulatedDelta = 0
            }

            if event.phase == .ended || event.momentumPhase == .ended {
                accumulatedDelta = 0
            }
        }
    }
}
