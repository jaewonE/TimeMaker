import AppKit
import SwiftUI

struct WindowKeyStateReader: NSViewRepresentable {
    @Binding var isKeyWindow: Bool

    func makeCoordinator() -> Coordinator {
        Coordinator(isKeyWindow: $isKeyWindow)
    }

    func makeNSView(context: Context) -> NSView {
        let view = NSView(frame: .zero)
        DispatchQueue.main.async {
            context.coordinator.attach(to: view.window)
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async {
            context.coordinator.attach(to: nsView.window)
        }
    }

    final class Coordinator {
        private var isKeyWindow: Binding<Bool>
        private weak var window: NSWindow?
        private var observers: [NSObjectProtocol] = []

        init(isKeyWindow: Binding<Bool>) {
            self.isKeyWindow = isKeyWindow
        }

        deinit {
            observers.forEach(NotificationCenter.default.removeObserver)
        }

        func attach(to window: NSWindow?) {
            guard self.window !== window else { return }
            observers.forEach(NotificationCenter.default.removeObserver)
            observers.removeAll()
            self.window = window
            isKeyWindow.wrappedValue = window?.isKeyWindow ?? false

            guard let window else { return }
            let center = NotificationCenter.default
            observers.append(center.addObserver(
                forName: NSWindow.didBecomeKeyNotification,
                object: window,
                queue: .main
            ) { [weak self] _ in
                self?.isKeyWindow.wrappedValue = true
            })
            observers.append(center.addObserver(
                forName: NSWindow.didResignKeyNotification,
                object: window,
                queue: .main
            ) { [weak self] _ in
                self?.isKeyWindow.wrappedValue = false
            })
        }
    }
}
