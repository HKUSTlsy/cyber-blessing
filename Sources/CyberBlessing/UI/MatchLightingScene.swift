import CyberBlessingCore
import SwiftUI

struct MatchLightingScene: View {
    let stage: IgnitionStage
    let tip: CGPoint
    @State private var stageStarted = Date.now

    var body: some View {
        GeometryReader { proxy in
            let box = CGPoint(x: proxy.size.width * 0.75, y: proxy.size.height * 0.63)
            TimelineView(.animation(minimumInterval: 1.0 / 30)) { timeline in
                let elapsed = timeline.date.timeIntervalSince(stageStarted)
                let drag = stage == .striking ? min(1, elapsed / 0.28) : 1
                let atIncense = stage == .approaching || stage == .lighting
                let head = atIncense ? tip : CGPoint(x: box.x + 12 - drag * 23, y: box.y - 8 - drag * 6)
                let angle: Double = atIncense ? 25 : -20
                let radians = angle * .pi / 180
                let center = CGPoint(x: head.x + 28 * cos(radians), y: head.y + 28 * sin(radians))
                ZStack {
                    ZStack {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(LinearGradient(colors: [BlessingPalette.vermilion, Color(red: 0.37, green: 0.10, blue: 0.07)], startPoint: .top, endPoint: .bottom))
                        RoundedRectangle(cornerRadius: 2).fill(Color(red: 0.86, green: 0.76, blue: 0.56))
                            .frame(width: 49, height: 17).offset(y: -2)
                        HStack(spacing: 2) {
                            ForEach(0..<18, id: \.self) { _ in Rectangle().fill(.black.opacity(0.35)).frame(width: 1, height: 5) }
                        }.offset(y: 10)
                    }
                    .frame(width: 67, height: 32)
                    .rotationEffect(.degrees(-8))
                    .position(box)
                    .opacity(stage == .withdrawing ? 0 : 1)

                    ZStack(alignment: .leading) {
                        Capsule().fill(LinearGradient(colors: [Color(red: 0.87, green: 0.69, blue: 0.39), Color(red: 0.62, green: 0.39, blue: 0.16)], startPoint: .top, endPoint: .bottom))
                            .frame(width: 58, height: 4)
                        Ellipse().fill(stage == .striking ? BlessingPalette.vermilion : Color(red: 0.18, green: 0.10, blue: 0.06))
                            .frame(width: 8, height: 6).offset(x: -2)
                        if stage != .striking {
                            FlameShape()
                                .fill(LinearGradient(colors: [.yellow, .orange, BlessingPalette.vermilion.opacity(0.9)], startPoint: .top, endPoint: .bottom))
                                .frame(width: 12 + sin(elapsed * 23), height: 23 + cos(elapsed * 17) * 2)
                                .shadow(color: .orange.opacity(0.45), radius: 6)
                                .offset(x: -4, y: -13)
                        }
                    }
                    .frame(width: 58, height: 6)
                    .rotationEffect(.degrees(angle))
                    .position(center)
                    .opacity(stage == .withdrawing ? 0 : 1)
                }
            }
        }
        .onChange(of: stage) { _ in stageStarted = .now }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

private struct FlameShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        p.addCurve(to: CGPoint(x: rect.width * 0.6, y: 0), control1: CGPoint(x: -rect.width * 0.15, y: rect.height * 0.8), control2: CGPoint(x: rect.width * 0.35, y: rect.height * 0.2))
        p.addCurve(to: CGPoint(x: rect.midX, y: rect.maxY), control1: CGPoint(x: rect.width * 0.65, y: rect.height * 0.35), control2: CGPoint(x: rect.width * 1.2, y: rect.height * 0.8))
        p.closeSubpath()
        return p
    }
}
