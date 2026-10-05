import SwiftUI

/// Arc-length spacing keeps neighbouring beads on a continuous threaded loop.
struct BeadScene: View, Animatable {
    var position: Double
    var reducedMotion = false
    var animatableData: Double { get { position } set { position = newValue } }

    var body: some View {
        GeometryReader { proxy in
            let width = min(proxy.size.width - 28, 248)
            let height = width / CyberBlessingImages.aspectRatio("bead_hand")
            let origin = CGPoint(x: (proxy.size.width - width) / 2, y: (proxy.size.height - height) / 2)
            let center = CGPoint(x: origin.x + width * 0.775, y: origin.y + height * 0.535)
            let rx = width * 0.185
            let ry = height * 0.285
            let cycle = reducedMotion ? 0 : position - floor(position)
            let press = pow(sin(cycle * .pi), 2)
            let hand = HandPoseRenderer.image(cycle: cycle).map { Image(nsImage: $0) } ?? CyberBlessingImages.image("bead_hand")
            let loop = ThreadedBeadLoop(center: center, rx: rx, ry: ry, press: press)
            ZStack {
                Ellipse().fill(BlessingPalette.bronze.opacity(0.09))
                    .frame(width: width * 0.67, height: 16).blur(radius: 5)
                    .position(x: center.x - 25, y: proxy.size.height - 13)
                beadLayer(loop: loop, front: false)
                hand.resizable().scaledToFit().frame(width: width, height: height)
                    .position(x: proxy.size.width / 2, y: proxy.size.height / 2)
                beadLayer(loop: loop, front: true)
                // The thumb pad overlaps the bead in the web; its feathered mask
                // uses the exact same deformed photograph as the rest of the hand.
                hand.resizable().scaledToFit().frame(width: width, height: height)
                    .mask { ThumbPadMask(cycle: cycle).fill(.white).blur(radius: 0.8) }
                    .position(x: proxy.size.width / 2, y: proxy.size.height / 2)
            }
        }
        .accessibilityHidden(true)
    }

    private func beadLayer(loop: ThreadedBeadLoop, front: Bool) -> some View {
        ZStack {
            Canvas { context, _ in
                for step in 1...180 {
                    let point = loop.point(fraction: Double(step) / 180)
                    let previous = loop.point(fraction: Double(step - 1) / 180)
                    var segment = Path()
                    segment.move(to: previous); segment.addLine(to: point)
                    let opacity = front ? loop.frontness(point) : 1
                    context.stroke(segment, with: .color(Color(red: 0.26, green: 0.17, blue: 0.10).opacity(opacity)), style: StrokeStyle(lineWidth: 1.35, lineCap: .round))
                }
            }
            ForEach(0..<18, id: \.self) { index in
                let fraction = (Double(index) - position) / 18
                let point = loop.point(fraction: fraction)
                let next = loop.point(fraction: fraction + 0.001)
                let tangent = atan2(next.y - point.y, next.x - point.x)
                Group {
                    EbonyBead(index: index, tangent: tangent, front: front)
                        .frame(width: 21, height: 21)
                        .shadow(color: .black.opacity(front ? 0.24 : 0.08), radius: front ? 2.1 : 0.9, x: 1.3, y: 2)
                        .position(point)
                        .opacity(front ? loop.frontness(point) : 1)
                }
            }
        }
    }
}

private struct ThreadedBeadLoop {
    let center: CGPoint
    let rx: CGFloat
    let ry: CGFloat
    let press: Double
    // Ellipse arc-length table, cached once for the fixed scene proportions.
    private static let lengths: [Double] = {
        var values = [0.0]
        for i in 1...360 {
            let a = Double(i - 1) / 360 * .pi * 2
            let b = Double(i) / 360 * .pi * 2
            values.append(values.last! + hypot(0.185 * (sin(b) - sin(a)), 0.27265 * (cos(b) - cos(a))))
        }
        return values
    }()
    func point(fraction: Double) -> CGPoint {
        let wrapped = fraction - floor(fraction)
        let distance = wrapped * Self.lengths.last!
        var low = 0, high = 360
        while high - low > 1 {
            let mid = (low + high) / 2
            if Self.lengths[mid] < distance { low = mid } else { high = mid }
        }
        let partial = (distance - Self.lengths[low]) / (Self.lengths[high] - Self.lengths[low])
        let angle = (Double(low) + partial) / 360 * .pi * 2
        return CGPoint(x: center.x + sin(angle) * rx,
                       y: center.y - cos(angle) * ry + press * 2.2 * pow(max(0, cos(angle)), 6))
    }

    func frontness(_ point: CGPoint) -> Double {
        func smooth(_ value: Double) -> Double {
            let t = min(1, max(0, value))
            return t * t * (3 - 2 * t)
        }
        let left = smooth(Double((center.x + 3 - point.x) / 6))
        let upper = smooth(Double((center.y - ry * 0.25 - point.y) / (ry * 0.22)))
        let lower = smooth(Double((point.y - center.y - ry * 0.60) / (ry * 0.15)))
        return max(left, upper, lower)
    }

}

private struct EbonyBead: View {
    let index: Int
    let tangent: Double
    let front: Bool
    var body: some View {
        Circle()
            .fill(RadialGradient(colors: [Color(red: 0.21, green: 0.17, blue: 0.13), Color(red: 0.085, green: 0.065, blue: 0.045), Color(red: 0.023, green: 0.019, blue: 0.016)], center: UnitPoint(x: 0.3, y: 0.22), startRadius: 0, endRadius: 21))
            .overlay {
                Canvas { context, size in
                    for line in 0..<5 {
                        var grain = Path()
                        let x = size.width * CGFloat(line + 1) / 6
                        grain.move(to: CGPoint(x: x, y: 0))
                        grain.addCurve(to: CGPoint(x: x + 1.5, y: size.height), control1: CGPoint(x: x - 2, y: 6), control2: CGPoint(x: x + 3, y: 14))
                        context.stroke(grain, with: .color(.brown.opacity(0.045)), lineWidth: 0.35)
                    }
                    // Paired drilled mouths align with the strand direction.
                    for sign in [-1.0, 1.0] {
                        let point = CGPoint(x: size.width / 2 + cos(tangent) * 9.4 * sign,
                                            y: size.height / 2 + sin(tangent) * 9.4 * sign)
                        context.fill(Path(ellipseIn: CGRect(x: point.x - 1.2, y: point.y - 1.2, width: 2.4, height: 2.4)), with: .color(.black.opacity(0.8)))
                    }
                }.clipShape(Circle())
            }
            .overlay(alignment: .topLeading) {
                Ellipse().fill(Color(red: 1, green: 0.94, blue: 0.82).opacity(0.17))
                    .frame(width: 7, height: 4).blur(radius: 1.2).rotationEffect(.degrees(-35)).padding(3)
            }
            .overlay(Circle().fill(.black.opacity(front ? 0 : 0.15)))
            .rotationEffect(.degrees(Double(index % 3 - 1) * 4))
    }
}

private struct ThumbPadMask: Shape {
    let cycle: Double
    func path(in r: CGRect) -> Path {
        let press = pow(sin(cycle * .pi), 2)
        let drag = sin(cycle * .pi * 2)
        func point(_ x: Double, _ y: Double) -> CGPoint {
            let qx = (x - 0.855) / 0.19
            let qy = (y - 0.215) / 0.17
            let flex = exp(-(qx * qx + qy * qy) * 2.4)
            return CGPoint(x: CGFloat(x) * r.width + CGFloat((-6 * press - 2 * drag) * flex) * r.width / 248,
                           y: CGFloat(y) * r.height + CGFloat(6 * press * flex) * r.width / 248)
        }
        var p = Path()
        p.move(to: point(0.72, 0.085))
        p.addQuadCurve(to: point(0.89, 0.23), control: point(0.89, 0.075))
        p.addQuadCurve(to: point(0.855, 0.247), control: point(0.905, 0.255))
        p.addQuadCurve(to: point(0.805, 0.205), control: point(0.825, 0.247))
        p.addQuadCurve(to: point(0.735, 0.14), control: point(0.75, 0.18))
        p.closeSubpath()
        return p
    }
}
