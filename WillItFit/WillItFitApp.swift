import SwiftUI

@main
struct WillItFitApp: App {
    @StateObject private var gate = WIFEntryGate(wifSourceLink: "https://example.com",
                                                 wifMarkerDomain: "example")
    @StateObject private var store = WIFStore()
    @State private var pagePainted = false

    var body: some Scene {
        WindowGroup {
            Group {
                if let panelReady = gate.wifPanelReady {
                    if panelReady {
                        ZStack {
                            WIFWebPanel(address: gate.wifSourceLink,
                                        onFirstPaint: { withAnimation { pagePainted = true } })
                                .edgesIgnoringSafeArea(.bottom)
                                .background(Color.black.ignoresSafeArea())
                            if !pagePainted {
                                WIFSplashScreen()
                                    .transition(.opacity)
                                    .onAppear {
                                        // Hang guard, not a deadline. Long on purpose: firing it
                                        // early only reveals the black page it exists to hide.
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 20) {
                                            pagePainted = true
                                        }
                                    }
                            }
                        }
                        .preferredColorScheme(.dark)
                    } else {
                        WIFRootView()
                            .environmentObject(store)
                            .preferredColorScheme(.light)
                    }
                } else {
                    WIFSplashScreen()
                        .preferredColorScheme(.light)
                        .onAppear { gate.begin() }
                }
            }
            .animation(.easeInOut(duration: 0.25), value: gate.wifPanelReady)
        }
    }
}
