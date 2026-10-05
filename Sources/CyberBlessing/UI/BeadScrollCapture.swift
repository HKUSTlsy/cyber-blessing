import AppKit
import SwiftUI

struct BeadScrollCapture: NSViewRepresentable {
    let onScroll: (Double, Bool) -> Void
    func makeNSView(context: Context) -> BeadWheelView {
        let view = BeadWheelView()
        view.onScroll = onScroll
        view.setAccessibilityElement(true)
        view.setAccessibilityLabel("盘串区域，使用鼠标滚轮或触控板上下滚动拨珠")
        view.setAccessibilityRole(.group)
        return view
    }
    func updateNSView(_ view: BeadWheelView, context: Context) { view.onScroll = onScroll }
}

final class BeadWheelView: NSView {
    var onScroll: ((Double, Bool) -> Void)?
    override func scrollWheel(with event: NSEvent) {
        guard let onScroll else { super.scrollWheel(with: event); return }
        onScroll(Double(event.hasPreciseScrollingDeltas ? event.scrollingDeltaY : event.deltaY), event.hasPreciseScrollingDeltas)
    }
}
