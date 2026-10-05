import Foundation

enum AppMetadata {
    static let width: CGFloat = 354
    static func resourceURL(_ name: String, withExtension ext: String?) -> URL? {
        #if APP_BUNDLE
        // Installed packages use only their own resources, never a developer's
        // SwiftPM build directory embedded by Bundle.module's generated accessor.
        return Bundle.main.url(forResource: name, withExtension: ext)
        #else
        return Bundle.main.url(forResource: name, withExtension: ext)
            ?? Bundle.module.url(forResource: name, withExtension: ext)
        #endif
    }
    static let version: String = {
        guard let url = resourceURL("VERSION", withExtension: nil),
              let text = try? String(contentsOf: url, encoding: .utf8) else { return "—" }
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }()
}
