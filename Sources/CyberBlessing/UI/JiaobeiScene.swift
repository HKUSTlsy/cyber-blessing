import CyberBlessingCore
import SwiftUI

struct JiaobeiBlockView: View {
    let face: CupFace?
    let isAirborne: Bool
    let rotation: Double
    var reducedMotion = false

    var body: some View {
        ZStack {
            Ellipse()
                .fill(RadialGradient(
                    colors: [.black.opacity(isAirborne ? 0.06 : 0.25), .clear],
                    center: .center,
                    startRadius: 1,
                    endRadius: 43
                ))
                .frame(width: 88, height: 12)
                .offset(y: 28)
                .scaleEffect(isAirborne ? 0.68 : 1)
                .animation(reducedMotion ? nil : .easeOut(duration: 0.18), value: isAirborne)

            CyberBlessingImages.image(face == .yang ? "jiaobei_flat" : "jiaobei_block")
                .resizable()
                .interpolation(.high)
                .scaledToFit()
                .frame(width: 96, height: 59)
                .overlay { MaterialGlaze(imageName: face == .yang ? "jiaobei_flat" : "jiaobei_block", intensity: 0.11) }
                .rotationEffect(.degrees(isAirborne ? rotation : rotation * 0.32))
                .rotation3DEffect(
                    .degrees(isAirborne ? 330 : 0),
                    axis: (x: 1, y: 0, z: 0),
                    perspective: 0.55
                )
                .offset(y: isAirborne ? -102 : 0)
                .shadow(color: .black.opacity(isAirborne ? 0.08 : 0.25), radius: isAirborne ? 11 : 3, x: 0, y: isAirborne ? 17 : 4)
                .animation(reducedMotion ? nil : (isAirborne ? .easeOut(duration: 0.20) : .interpolatingSpring(stiffness: 125, damping: 13)), value: isAirborne)
        }
        .frame(width: 108, height: 78)
        .accessibilityLabel(face.map { $0 == .yang ? "木质月牙筊杯，阳面朝上" : "木质月牙筊杯，阴面朝上" } ?? "木质月牙筊杯")
    }
}
