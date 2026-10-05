import AppKit
import Foundation

let destination = CommandLine.arguments.dropFirst().first ?? ".work/AppIcon.iconset"
try FileManager.default.createDirectory(atPath: destination, withIntermediateDirectories: true)

func render(_ pixels: Int, to name: String) throws {
    guard let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: pixels, pixelsHigh: pixels,
        bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB,
        bytesPerRow: 0, bitsPerPixel: 0), let context = NSGraphicsContext(bitmapImageRep: bitmap) else {
        fatalError("Cannot create icon bitmap")
    }
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = context
    let scale = CGFloat(pixels) / 1024
    context.cgContext.scaleBy(x: scale, y: scale)
    NSColor(calibratedRed: 0.68, green: 0.22, blue: 0.15, alpha: 1).setFill()
    NSBezierPath(roundedRect: NSRect(x: 80, y: 80, width: 864, height: 864), xRadius: 190, yRadius: 190).fill()
    let gold = NSColor(calibratedRed: 1, green: 0.83, blue: 0.53, alpha: 1)
    gold.setFill()
    NSBezierPath(roundedRect: NSRect(x: 496, y: 377, width: 32, height: 260), xRadius: 16, yRadius: 16).fill()
    let flame = NSBezierPath()
    flame.move(to: NSPoint(x: 512, y: 648))
    flame.curve(to: NSPoint(x: 509, y: 845), controlPoint1: NSPoint(x: 392, y: 698), controlPoint2: NSPoint(x: 464, y: 790))
    flame.curve(to: NSPoint(x: 512, y: 648), controlPoint1: NSPoint(x: 549, y: 794), controlPoint2: NSPoint(x: 632, y: 709))
    flame.fill()
    let bowl = NSBezierPath()
    bowl.move(to: NSPoint(x: 322, y: 408))
    bowl.line(to: NSPoint(x: 702, y: 408))
    bowl.curve(to: NSPoint(x: 634, y: 242), controlPoint1: NSPoint(x: 696, y: 322), controlPoint2: NSPoint(x: 686, y: 271))
    bowl.line(to: NSPoint(x: 390, y: 242))
    bowl.curve(to: NSPoint(x: 322, y: 408), controlPoint1: NSPoint(x: 340, y: 271), controlPoint2: NSPoint(x: 328, y: 322))
    bowl.close(); bowl.fill()
    NSColor(calibratedRed: 0.68, green: 0.22, blue: 0.15, alpha: 1).setFill()
    NSBezierPath(roundedRect: NSRect(x: 342, y: 385, width: 340, height: 12), xRadius: 6, yRadius: 6).fill()
    gold.setFill()
    NSBezierPath(roundedRect: NSRect(x: 409, y: 213, width: 29, height: 57), xRadius: 10, yRadius: 10).fill()
    NSBezierPath(roundedRect: NSRect(x: 587, y: 213, width: 29, height: 57), xRadius: 10, yRadius: 10).fill()
    NSGraphicsContext.restoreGraphicsState()
    guard let data = bitmap.representation(using: .png, properties: [:]) else { fatalError("Cannot encode icon") }
    try data.write(to: URL(fileURLWithPath: destination).appendingPathComponent(name))
}
for size in [16, 32, 128, 256, 512] {
    try render(size, to: "icon_\(size)x\(size).png")
    try render(size * 2, to: "icon_\(size)x\(size)@2x.png")
}
