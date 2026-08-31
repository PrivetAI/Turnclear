import SwiftUI

/// Shown while the launch check runs, and again over the panel until the page paints. Using the
/// same screen in both places means there is no visual seam between the two phases.
struct WIFSplashScreen: View {
    @State private var breathing = false

    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)

            VStack(spacing: 22) {
                ZStack {
                    WIFDoorGlyph()
                        .stroke(WIFPalette.amber,
                                style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                        .frame(width: 74, height: 74)
                    WIFDiamondGlyph()
                        .fill(WIFPalette.teal)
                        .frame(width: 11, height: 11)
                        .offset(x: 26, y: -22)
                }
                .scaleEffect(breathing ? 1.06 : 0.94)
                .animation(Animation.easeInOut(duration: 1.1).repeatForever(autoreverses: true),
                           value: breathing)

                VStack(spacing: 5) {
                    Text("WILL IT FIT")
                        .font(.system(size: 20, weight: .heavy))
                        .tracking(3)
                        .foregroundColor(.white)
                    Text("Measure once, carry once")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(Color.white.opacity(0.55))
                }
            }
        }
        .onAppear { breathing = true }
    }
}
