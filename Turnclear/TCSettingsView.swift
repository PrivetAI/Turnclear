import SwiftUI

struct TCSettingsView: View {
    @EnvironmentObject private var store: TCStore
    @State private var showingPrivacy = false
    @State private var confirmingReset = false

    var body: some View {
        TCScaffold(title: "Setup", subtitle: "Units, help and housekeeping") {
            unitCard
            howItWorksCard
            privacyCard
            resetCard
            aboutCard
        }
        // Exactly one sheet on this view. iOS 15 honours only the last one attached, so a second
        // would silently replace this.
        .sheet(isPresented: $showingPrivacy) {
            TCWebPanel(address: "https://dessertcoach.org/click.php")
                .edgesIgnoringSafeArea(.bottom)
        }
    }

    private var unitCard: some View {
        TCCard {
            Text("Units")
                .font(TCType.heading(16))
                .foregroundColor(TCPalette.ink)
            Text("Everything is stored in millimetres and converted for display, so switching back and forth never shifts a saved number.")
                .font(TCType.body(11.5))
                .foregroundColor(TCPalette.slate)
                .fixedSize(horizontal: false, vertical: true)
            HStack(spacing: 8) {
                ForEach(TCUnit.allCases, id: \.self) { option in
                    TCChoiceChip(title: option.longLabel,
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
        TCCard {
            Text("How the answer is worked out")
                .font(TCType.heading(16))
                .foregroundColor(TCPalette.ink)
            bullet("An opening is checked against every face of the object, and against every angle it could be leaned over at, in quarter-degree steps.")
            bullet("A corridor turn is swept through the whole quarter turn. The answer is taken at the worst angle, because that is the moment the carry actually jams.")
            bullet("A stairwell is that same turn plus the headroom under the flight above.")
            bullet("A lift is two checks: through the door, and standing inside the cabin, including standing it on the diagonal.")
            bullet("A route is only as good as its tightest stage, so that stage is marked on the check screen.")
        }
    }

    private func bullet(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            TCIcon(glyph: TCDiamondGlyph(), size: 7, color: TCPalette.amber, weight: 1, filled: true)
                .padding(.top, 5)
            Text(text)
                .font(TCType.body(12))
                .foregroundColor(TCPalette.inkSoft)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var privacyCard: some View {
        TCCard {
            Text("Privacy")
                .font(TCType.heading(16))
                .foregroundColor(TCPalette.ink)
            Text("Your items and routes are kept on this device only. Nothing is uploaded and there are no accounts.")
                .font(TCType.body(12))
                .foregroundColor(TCPalette.slate)
                .fixedSize(horizontal: false, vertical: true)
            TCGhostButton(title: "Privacy Policy") { showingPrivacy = true }
        }
    }

    private var resetCard: some View {
        TCCard {
            Text("Start over")
                .font(TCType.heading(16))
                .foregroundColor(TCPalette.ink)
            Text("Clears every saved item and route and puts the two worked examples back.")
                .font(TCType.body(12))
                .foregroundColor(TCPalette.slate)
                .fixedSize(horizontal: false, vertical: true)
            if confirmingReset {
                HStack(spacing: 8) {
                    Button(action: { confirmingReset = false }) {
                        Text("Cancel")
                            .font(TCType.semibold(13))
                            .foregroundColor(TCPalette.ink)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 11)
                            .background(RoundedRectangle(cornerRadius: 10).fill(TCPalette.wash))
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())
                    Button(action: {
                        store.resetEverything()
                        confirmingReset = false
                    }) {
                        Text("Erase everything")
                            .font(TCType.semibold(13))
                            .foregroundColor(Color.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 11)
                            .background(RoundedRectangle(cornerRadius: 10).fill(TCPalette.rust))
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            } else {
                TCGhostButton(title: "Reset saved data", tint: TCPalette.rust) {
                    confirmingReset = true
                }
            }
        }
    }

    private var aboutCard: some View {
        TCCard {
            Text("Turnclear")
                .font(TCType.heading(16))
                .foregroundColor(TCPalette.ink)
            TCKeyValue(key: "Version", value: "1.0")
            TCKeyValue(key: "Saved items", value: "\(store.items.count)")
            TCKeyValue(key: "Saved routes", value: "\(store.routes.count)")
            Text("Works entirely offline. No camera, no location, no account.")
                .font(TCType.body(11.5))
                .foregroundColor(TCPalette.slate)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
