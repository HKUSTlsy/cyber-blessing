import AppKit

enum AppTermination {
    static func quit() {
        NSApplication.shared.terminate(nil)
    }
}
