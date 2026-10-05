import AppKit
import CoreImage

/// Deform the intact photograph around the thumb pad, preserving the joint and
/// palm. The two compositing layers use the same pose, so no cut-out rotates away.
@MainActor
enum HandPoseRenderer {
    private static let context = CIContext(options: [.cacheIntermediates: false])
    private static let source: CIImage? = {
        guard let url = CyberBlessingImages.resourceURL("bead_hand"), let image = CIImage(contentsOf: url) else { return nil }
        return image.transformed(by: CGAffineTransform(scaleX: 560 / image.extent.width, y: 560 / image.extent.width))
    }()
    private static let kernel = CIWarpKernel(source: """
        kernel vec2 thumbFlex(float width, float height, float dx, float dy) {
            vec2 p = destCoord();
            vec2 q = (p - vec2(width * 0.855, height * 0.785)) / vec2(width * 0.19, height * 0.17);
            float flex = exp(-dot(q, q) * 2.4);
            return p - vec2(dx, dy) * flex;
        }
        """)
    private static var lastKey: Int?
    private static var lastImage: NSImage?
    static var isAvailable: Bool { source != nil && kernel != nil }

    static func image(cycle: Double) -> NSImage? {
        guard let source, let kernel else { return nil }
        let key = Int((cycle - floor(cycle)) * 96)
        if lastKey == key { return lastImage }
        let phase = Double(key) / 96
        let press = pow(sin(phase * .pi), 2)
        let drag = sin(phase * .pi * 2)
        let scale = source.extent.width / 248
        let dx = (-6 * press - 2 * drag) * scale
        let dy = -6.0 * press * scale
        guard let warped = kernel.apply(extent: source.extent,
            roiCallback: { _, rect in rect.insetBy(dx: -20, dy: -20) },
            image: source, arguments: [source.extent.width, source.extent.height, dx, dy]),
            let cg = context.createCGImage(warped, from: source.extent) else { return nil }
        let result = NSImage(cgImage: cg, size: source.extent.size)
        lastKey = key; lastImage = result
        return result
    }
}
