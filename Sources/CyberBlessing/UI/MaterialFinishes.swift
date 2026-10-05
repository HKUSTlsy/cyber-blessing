import SwiftUI

enum RitualSurfaceFinish {
    case amberWood
    case darkRosewood
    case burgundyCushion

    var colors: [Color] {
        switch self {
        case .amberWood:
            [Color(red: 0.47, green: 0.31, blue: 0.19), Color(red: 0.69, green: 0.50, blue: 0.32), Color(red: 0.40, green: 0.27, blue: 0.18)]
        case .darkRosewood:
            [Color(red: 0.28, green: 0.16, blue: 0.12), Color(red: 0.48, green: 0.27, blue: 0.19), Color(red: 0.24, green: 0.14, blue: 0.11)]
        case .burgundyCushion:
            [Color(red: 0.30, green: 0.11, blue: 0.12), Color(red: 0.49, green: 0.19, blue: 0.17), Color(red: 0.25, green: 0.09, blue: 0.11)]
        }
    }

    var grain: Color {
        switch self {
        case .amberWood: Color(red: 0.95, green: 0.75, blue: 0.47)
        case .darkRosewood: Color(red: 0.82, green: 0.53, blue: 0.34)
        case .burgundyCushion: Color(red: 0.94, green: 0.60, blue: 0.40)
        }
    }
}

struct RitualSurface: View {
    let finish: RitualSurfaceFinish

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(LinearGradient(colors: finish.colors, startPoint: .topLeading, endPoint: .bottomTrailing))

            Canvas { context, size in
                for index in 0..<6 {
                    let y = size.height * CGFloat(index + 1) / 7
                    let wave = CGFloat(sin(Double(index) * 1.37)) * 1.5
                    var grainLine = Path()
                    grainLine.move(to: CGPoint(x: 2, y: y))
                    grainLine.addCurve(
                        to: CGPoint(x: size.width - 2, y: y - wave * 0.25),
                        control1: CGPoint(x: size.width * 0.28, y: y + wave),
                        control2: CGPoint(x: size.width * 0.72, y: y - wave)
                    )
                    context.stroke(
                        grainLine,
                        with: .color(finish.grain.opacity(index.isMultiple(of: 2) ? 0.20 : 0.11)),
                        lineWidth: index.isMultiple(of: 2) ? 0.65 : 0.4
                    )
                }
            }
            .padding(.horizontal, 5)
            .padding(.vertical, 3)

            VStack(spacing: 0) {
                Capsule().fill(.white.opacity(0.28)).frame(height: 0.8).padding(.horizontal, 12)
                Spacer(minLength: 0)
                Capsule().fill(.black.opacity(0.15)).frame(height: 0.7).padding(.horizontal, 14)
            }
            .padding(.vertical, 3)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(.white.opacity(0.20), lineWidth: 0.7)
        }
        .shadow(color: finish.colors[0].opacity(0.22), radius: 5, x: 0, y: 4)
        .accessibilityHidden(true)
    }
}

struct MaterialGlaze: View {
    let imageName: String
    var intensity: Double = 0.12

    var body: some View {
        LinearGradient(
            stops: [
                .init(color: .white.opacity(intensity), location: 0),
                .init(color: .clear, location: 0.42),
                .init(color: .black.opacity(intensity * 0.38), location: 1)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .mask {
            CyberBlessingImages.image(imageName)
                .resizable()
                .scaledToFit()
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
