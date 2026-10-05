import AppKit
import SwiftUI

@MainActor
enum CyberBlessingImages {
    static let names = ["incense_burner", "incense_stick", "incense_unlit", "bead_hand", "jiaobei_block", "jiaobei_flat", "woodfish_body", "woodfish_mallet"]
    private static let loaded: [String: NSImage] = {
        var result: [String: NSImage] = [:]
        for name in names {
            guard let url = resourceURL(name), let image = NSImage(contentsOf: url), image.isValid else {
                NSLog("Missing or invalid image resource: %@", name)
                continue
            }
            result[name] = image
        }
        return result
    }()

    static func resourceURL(_ name: String) -> URL? {
        AppMetadata.resourceURL(name, withExtension: "png")
    }

    /// Explicitly decoded/cached NSImages work identically in SwiftPM and an app bundle.
    static func image(_ name: String) -> Image {
        if let image = loaded[name] { return Image(nsImage: image) }
        return Image(systemName: "exclamationmark.triangle")
    }
    static func aspectRatio(_ name: String) -> CGFloat {
        guard let image = loaded[name], image.size.height > 0 else { return 1 }
        return image.size.width / image.size.height
    }
    static var loadedCount: Int { loaded.count }
}
