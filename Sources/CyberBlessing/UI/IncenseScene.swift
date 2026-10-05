import CyberBlessingCore
import SwiftUI

struct IncenseScene: View {
    let progress: Double
    let isBurning: Bool
    let phase: Date
    var reducedMotion = false
    var ignitionStage: IgnitionStage = .idle
    var smokeTime: TimeInterval? = nil

    private var normalizedProgress: Double { min(max(progress, 0), 1) }

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let burnerHeight = min(size.height * 0.56, 116)
            let burnerWidth = burnerHeight * CyberBlessingImages.aspectRatio("incense_burner")
            let burnerCenterY = size.height * 0.75
            let ashSurfaceY = burnerCenterY - burnerHeight * 0.13
            let stickBottomY = ashSurfaceY + 8
            let buriedLength: CGFloat = 8
            let stickHeight = buriedLength + max(3, size.height * 0.41 * (1 - normalizedProgress))
            let tipY = stickBottomY - stickHeight
            let smokeHeight = min(108, max(8, tipY - 4))
            let phaseValue = reducedMotion ? CGFloat(0) : CGFloat(phase.timeIntervalSinceReferenceDate)

            ZStack {
                Ellipse()
                    .fill(BlessingPalette.bronze.opacity(0.10))
                    .frame(width: burnerWidth * 0.78, height: 11)
                    .blur(radius: 5)
                    .position(x: size.width / 2, y: size.height - 4)

                RadialGradient(
                    colors: [BlessingPalette.gold.opacity(0.10), .clear],
                    center: .center,
                    startRadius: 4,
                    endRadius: size.height * 0.48
                )
                .frame(width: size.width * 0.72, height: size.height * 0.86)
                .position(x: size.width / 2, y: size.height * 0.40)

                RitualSurface(finish: .amberWood)
                    .frame(width: size.width - 18, height: 34)
                    .position(x: size.width / 2, y: size.height - 19)
                    .zIndex(-1)

                // The bowl and rear rim sit behind the shaft; only the foreground
                // ash and front rim occlude its buried root.
                burnerImage
                    .frame(width: burnerWidth, height: burnerHeight)
                    .shadow(color: .black.opacity(0.17), radius: 4, x: 0, y: 5)
                    .position(x: size.width / 2, y: burnerCenterY)

                if normalizedProgress < 1 {
                    // Keep the coating's thickness fixed while cropping away burnt length.
                    // The central 8% of the macro sprite contains the stick itself.
                    CyberBlessingImages.image("incense_unlit")
                        .resizable()
                        .interpolation(.high)
                        .frame(width: 190, height: size.height * 0.41 + buriedLength)
                        .frame(width: 12, height: stickHeight, alignment: .bottom)
                        .clipped()
                        .shadow(color: .black.opacity(0.22), radius: 1, x: 1, y: 1)
                        .position(x: size.width / 2, y: stickBottomY - stickHeight / 2)
                        .zIndex(1)

                    if isBurning {
                        IncenseEmber(isBurning: true, phase: phaseValue)
                            .frame(width: 12, height: 12)
                            .position(x: size.width / 2, y: tipY + 2.5)
                            .zIndex(4)

                        SmokePlume(reducedMotion: reducedMotion, fixedTime: smokeTime)
                            .frame(width: 64, height: smokeHeight)
                            .position(
                                x: size.width / 2,
                                y: tipY + 2 - smokeHeight / 2
                            )
                            .zIndex(2)
                    }
                }

                burnerImage
                    .frame(width: burnerWidth, height: burnerHeight)
                    .mask(alignment: .bottom) {
                        Rectangle().frame(height: burnerHeight * 0.63)
                    }
                    .position(x: size.width / 2, y: burnerCenterY)
                    .zIndex(3)

                if normalizedProgress < 1 {
                    Ellipse().fill(Color.black.opacity(0.19))
                        .frame(width: 11, height: 2.4).blur(radius: 0.9)
                        .position(x: size.width / 2 + 1, y: ashSurfaceY + 1)
                        .zIndex(4)
                }

                if ignitionStage != .idle {
                    MatchLightingScene(stage: ignitionStage, tip: CGPoint(x: size.width / 2, y: tipY + 3))
                        .zIndex(8)
                }

                if normalizedProgress > 0 {
                    AshMoundShape()
                        .fill(LinearGradient(
                            colors: [Color(red: 0.82, green: 0.79, blue: 0.71).opacity(0.62), Color(red: 0.54, green: 0.51, blue: 0.46).opacity(0.52)],
                            startPoint: .top,
                            endPoint: .bottom
                        ))
                        .frame(
                            width: 19 + CGFloat(normalizedProgress) * 30,
                            height: 1 + CGFloat(normalizedProgress) * 5
                        )
                        .position(x: size.width / 2, y: ashSurfaceY + 2)
                        .zIndex(4)
                        .accessibilityHidden(true)
                }
            }
            .frame(width: size.width, height: size.height)
        }
        .clipped()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(isBurning ? "一根真实质感线香正在香炉中燃烧，剩余长度随时间减少" : (normalizedProgress >= 1 ? "香已燃尽，青铜香炉中留有香灰" : "一根线香插在青铜香炉中"))
    }
    private var burnerImage: some View {
        CyberBlessingImages.image("incense_burner")
            .resizable().interpolation(.high).scaledToFit()
            .overlay { MaterialGlaze(imageName: "incense_burner", intensity: 0.08) }
    }

}

private struct IncenseEmber: View {
    let isBurning: Bool
    let phase: CGFloat

    var body: some View {
        ZStack {
            Ellipse().fill(Color(red: 0.27, green: 0.22, blue: 0.19))
                .frame(width: 10, height: 3)
            Ellipse().fill(Color(red: 0.76, green: 0.23, blue: 0.08))
                .frame(width: 5, height: 2)
                .opacity(0.72 + 0.12 * sin(Double(phase) * 1.2))
                .shadow(color: .orange.opacity(0.30), radius: 2)
        }
        .accessibilityHidden(true)
    }
}

/// Translucent tapered volumes instead of uniform stroked curves. The narrow
/// source is anchored to the ember; disturbances travel upwards and dissipate.
private struct SmokePlume: View {
    let reducedMotion: Bool
    let fixedTime: TimeInterval?

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 24, paused: reducedMotion || fixedTime != nil)) { timeline in
            let t = CGFloat(fixedTime ?? (reducedMotion ? 3 : timeline.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 1800)))
            Canvas { context, size in
                func center(_ u: CGFloat, strand: CGFloat) -> CGFloat {
                    let travel = t * 0.8 - u * 5.8
                    return size.width / 2 + pow(u, 1.35) * (
                        sin(travel) * 7 + sin(travel * 1.73 + strand) * 4 * u
                        + sin(travel * 2.9 + strand * 2) * 2 * u * u)
                        + strand * pow(u, 2) * (6 + 4 * sin(travel * 1.2 + strand))
                }
                for strand in -1...1 {
                    var volume = Path()
                    let steps = 64
                    for side in [CGFloat(-1), CGFloat(1)] {
                        let indices = side < 0 ? Array(0...steps) : Array((0...steps).reversed())
                        for i in indices {
                            let u = CGFloat(i) / CGFloat(steps)
                            let width = (0.38 + pow(u, 1.6) * 2.9) * (0.72 + 0.28 * sin(t - u * 10))
                            let point = CGPoint(x: center(u, strand: CGFloat(strand)) + side * width,
                                                y: size.height * (1 - u))
                            if i == 0 && side < 0 { volume.move(to: point) }
                            else { volume.addLine(to: point) }
                        }
                    }
                    volume.closeSubpath()
                    context.drawLayer { layer in
                        layer.addFilter(.blur(radius: 0.7 + Double(abs(strand)) * 0.6))
                        layer.fill(volume, with: .linearGradient(Gradient(stops: [
                            .init(color: Color(red: 0.42, green: 0.44, blue: 0.45).opacity(0.10), location: 0),
                            .init(color: Color(red: 0.48, green: 0.49, blue: 0.50).opacity(0.075), location: 0.35),
                            .init(color: Color.gray.opacity(0.035), location: 0.72),
                            .init(color: .clear, location: 1)
                        ]), startPoint: CGPoint(x: 0, y: size.height), endPoint: .zero))
                    }
                }
                // Small diffuse wisps advect up the plume and disappear before
                // reaching its top. No bright circles or detached source wobble.
                context.drawLayer { layer in
                    layer.addFilter(.blur(radius: 2))
                    for i in 0..<12 {
                        let age = (t * 0.21 + CGFloat(i) / 12).truncatingRemainder(dividingBy: 1)
                        let u = age
                        let radius = 0.6 + u * 5
                        let opacity = 0.032 * sin(u * .pi) * (1 - u)
                        let rect = CGRect(x: center(u, strand: sin(CGFloat(i) * 2.4)) - radius,
                                          y: size.height * (1 - u) - radius * 2,
                                          width: radius * 2, height: radius * 4)
                        layer.fill(Path(ellipseIn: rect), with: .color(Color.gray.opacity(Double(opacity))))
                    }
                }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

private struct AshMoundShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.maxY), control: CGPoint(x: rect.midX, y: rect.minY - rect.height * 0.7))
        path.closeSubpath()
        return path
    }
}
