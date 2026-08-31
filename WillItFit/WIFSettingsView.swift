import SwiftUI

struct WIFSettingsView: View {
    @EnvironmentObject private var store: WIFStore
    @State private var showingPrivacy = false
    @State private var confirmingReset = false

    var body: some View {
        WIFScaffold(title: "Setup", subtitle: "Units, help and housekeeping") {
            unitCard
            howItWorksCard
            privacyCard
            resetCard
            aboutCard
        }
        // Exactly one sheet on this view. iOS 15 honours only the last one attached, so a second
        // would silently replace this.
        .sheet(isPresented: $showingPrivacy) {
            WIFWebPanel(address: "https://example.com")
                .edgesIgnoringSafeArea(.bottom)
        }
    }

    private var unitCard: some View {
        WIFCard {
            Text("Units")
                .font(WIFType.heading(16))
                .foregroundColor(WIFPalette.ink)
            Text("Everything is stored in millimetres and converted for display, so switching back and forth never shifts a saved number.")
                .font(WIFType.body(11.5))
                .foregroundColor(WIFPalette.slate)
                .fixedSize(horizontal: false, vertical: true)
            HStack(spacing: 8) {
                ForEach(WIFUnit.allCases, id: \.self) { option in
                    WIFChoiceChip(title: option.longLabel,
                                  detail: option.shortLabel,
                                  selected: store.unit == option) {
                        store.setUnit(option)
                    }
                }
                Spacer(minLength: 0)
            }
        }
    }

    private var howItWorksCard: some View {
        WIFCard {
            Text("How the answer is worked out")
                .font(WIFType.heading(16))
                .foregroundColor(WIFPalette.ink)
            bullet("An opening is checked against every face of the object, and against every angle it could be leaned over at, in quarter-degree steps.")
            bullet("A corridor turn is swept through the whole quarter turn. The answer is taken at the worst angle, because that is the moment the carry actually jams.")
            bullet("A stairwell is that same turn plus the headroom under the flight above.")
            bullet("A lift is two checks: through the door, and standing inside the cabin, including standing it on the diagonal.")
            bullet("A route is only as good as its tightest stage, so that stage is marked on the check screen.")
        }
    }

    private func bullet(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            WIFIcon(glyph: WIFDiamondGlyph(), size: 7, color: WIFPalette.amber, weight: 1, filled: true)
                .padding(.top, 5)
            Text(text)
                .font(WIFType.body(12))
                .foregroundColor(WIFPalette.inkSoft)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var privacyCard: some View {
        WIFCard {
            Text("Privacy")
                .font(WIFType.heading(16))
                .foregroundColor(WIFPalette.ink)
            Text("Your items and routes are kept on this device only. Nothing is uploaded and there are no accounts.")
                .font(WIFType.body(12))
                .foregroundColor(WIFPalette.slate)
                .fixedSize(horizontal: false, vertical: true)
            WIFGhostButton(title: "Privacy Policy") { showingPrivacy = true }
        }
    }

    private var resetCard: some View {
        WIFCard {
            Text("Start over")
                .font(WIFType.heading(16))
                .foregroundColor(WIFPalette.ink)
            Text("Clears every saved item and route and puts the two worked examples back.")
                .font(WIFType.body(12))
                .foregroundColor(WIFPalette.slate)
                .fixedSize(horizontal: false, vertical: true)
            if confirmingReset {
                HStack(spacing: 8) {
                    Button(action: { confirmingReset = false }) {
                        Text("Cancel")
                            .font(WIFType.semibold(13))
                            .foregroundColor(WIFPalette.ink)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 11)
                            .background(RoundedRectangle(cornerRadius: 10).fill(WIFPalette.wash))
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())
                    Button(action: {
                        store.resetEverything()
                        confirmingReset = false
                    }) {
                        Text("Erase everything")
                            .font(WIFType.semibold(13))
                            .foregroundColor(Color.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 11)
                            .background(RoundedRectangle(cornerRadius: 10).fill(WIFPalette.rust))
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            } else {
                WIFGhostButton(title: "Reset saved data", tint: WIFPalette.rust) {
                    confirmingReset = true
                }
            }
        }
    }

    private var aboutCard: some View {
        WIFCard {
            Text("Will It Fit")
                .font(WIFType.heading(16))
                .foregroundColor(WIFPalette.ink)
            WIFKeyValue(key: "Version", value: "1.0")
            WIFKeyValue(key: "Saved items", value: "\(store.items.count)")
            WIFKeyValue(key: "Saved routes", value: "\(store.routes.count)")
            Text("Works entirely offline. No camera, no location, no account.")
                .font(WIFType.body(11.5))
                .foregroundColor(WIFPalette.slate)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
