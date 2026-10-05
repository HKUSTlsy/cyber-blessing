import AppKit
import SwiftUI

/// Native controls stay inside MenuBarExtra, including the destructive confirmation.
struct SettingsActionButton: NSViewRepresentable {
    let title: String
    let identifier: String
    var destructive = false
    var enabled = true
    let action: () -> Void

    final class Coordinator: NSObject {
        var action: () -> Void
        init(action: @escaping () -> Void) { self.action = action }
        @objc func press(_ sender: NSButton) { action() }
    }

    func makeCoordinator() -> Coordinator { Coordinator(action: action) }

    func makeNSView(context: Context) -> NSButton {
        let button = NSButton(title: title, target: context.coordinator, action: #selector(Coordinator.press(_:)))
        button.bezelStyle = .rounded
        button.controlSize = .small
        button.font = .systemFont(ofSize: 11)
        button.setContentHuggingPriority(.required, for: .horizontal)
        return button
    }

    func updateNSView(_ button: NSButton, context: Context) {
        context.coordinator.action = action
        button.title = title
        button.isEnabled = enabled
        button.contentTintColor = destructive ? .systemRed : nil
        button.setAccessibilityIdentifier(identifier)
    }
}
