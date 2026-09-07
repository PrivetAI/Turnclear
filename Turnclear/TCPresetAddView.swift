import SwiftUI

/// Second half of the preset flow: choose which saved route the stage joins.
struct TCPresetAddView: View {
    let presetTitle: String
    let stage: TCObstacle

    @EnvironmentObject private var store: TCStore
    @Environment(\.presentationMode) private var presentationMode

    var body: some View {
        TCScaffold(title: "Add to a route",
                    subtitle: presetTitle,
                    showsBack: true) {
            TCCard {
                Text("This stage")
                    .font(TCType.heading(15))
                    .foregroundColor(TCPalette.ink)
                TCKeyValue(key: stage.kind.title, value: stage.summary(store.unit))
                Text("It joins the end of the route you pick. Move it earlier from the route screen if it belongs there.")
                    .font(TCType.body(11.5))
                    .foregroundColor(TCPalette.slate)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if store.routes.isEmpty {
                TCEmptyState(title: "No routes to add it to",
                              message: "Create a route on the Routes tab first, then come back and drop this stage into it.")
            } else {
                TCSectionLabel(text: "Pick a route")
                ForEach(store.routes) { route in
                    routeButton(route)
                }
            }
        }
    }

    private func routeButton(_ route: TCRoute) -> some View {
        Button(action: {
            store.append(obstacle: stage, toRouteID: route.id)
            presentationMode.wrappedValue.dismiss()
        }) {
            HStack(alignment: .center, spacing: 11) {
                TCIcon(glyph: TCRouteGlyph(), size: 21, color: TCPalette.ink, weight: 1.9)
                VStack(alignment: .leading, spacing: 2) {
                    Text(route.name)
                        .font(TCType.semibold(15))
                        .foregroundColor(TCPalette.ink)
                        .multilineTextAlignment(.leading)
                    Text(route.stops.count == 1 ? "1 stage" : "\(route.stops.count) stages")
                        .font(TCType.body(11))
                        .foregroundColor(TCPalette.slate)
                }
                Spacer(minLength: 4)
                TCIcon(glyph: TCPlusGlyph(), size: 16, color: TCPalette.teal, weight: 2.2)
            }
            .padding(TCMetric.cardPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: TCMetric.corner).fill(TCPalette.panel))
            .overlay(RoundedRectangle(cornerRadius: TCMetric.corner)
                        .stroke(TCPalette.line, lineWidth: 1))
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}
