import SwiftUI

struct WoodFishScene: View {
    let isStriking: Bool

    var body: some View {
        ZStack {
            Ellipse()
                .fill(BlessingPalette.bronze.opacity(0.11))
                .frame(width: 190, height: 12)
                .blur(radius: 5)
                .offset(y: 62)

            RitualSurface(finish: .burgundyCushion)
                .frame(width: 164, height: 27)
                .clipShape(Capsule())
                .overlay(Capsule().stroke(BlessingPalette.gold.opacity(0.24), lineWidth: 0.7))
                .offset(x: -6, y: 60)

            CyberBlessingImages.image("woodfish_body")
                .resizable()
                .interpolation(.high)
                .scaledToFit()
                .frame(width: 190, height: 142)
                .overlay { MaterialGlaze(imageName: "woodfish_body", intensity: 0.13) }
                .rotationEffect(.degrees(isStriking ? -1.2 : 0))
                .offset(x: -6, y: -5)
                .shadow(color: .black.opacity(0.13), radius: 5, x: 0, y: 5)
                .animation(.spring(response: 0.13, dampingFraction: 0.48), value: isStriking)
                .zIndex(1)

            CyberBlessingImages.image("woodfish_mallet")
                .resizable()
                .interpolation(.high)
                .scaledToFit()
                .frame(width: 72, height: 102)
                .overlay { MaterialGlaze(imageName: "woodfish_mallet", intensity: 0.10) }
                .scaleEffect(x: -1, y: 1)
                .rotationEffect(.degrees(isStriking ? -32 : -12), anchor: .bottomTrailing)
                .offset(x: 92, y: -42)
                .shadow(color: .black.opacity(0.16), radius: 2, x: 1, y: 2)
                .animation(.spring(response: 0.13, dampingFraction: 0.45), value: isStriking)
                .zIndex(2)
        }
        .frame(width: 260, height: 164)
        .accessibilityHidden(true)
    }
}
