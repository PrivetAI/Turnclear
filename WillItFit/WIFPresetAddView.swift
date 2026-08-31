import SwiftUI

/// Second half of the preset flow: choose which saved route the stage joins.
struct WIFPresetAddView: View {
    let presetTitle: String
    let stage: WIFObstacle

    @EnvironmentObject private var store: WIFStore
    @Environment(\.presentationMode) private var presentationMode

    var body: some View {
        WIFScaffold(title: "Add to a route",
                    subtitle: presetTitle,
                    showsBack: true) {
            WIFCard {
                Text("This stage")
                    .font(WIFType.heading(15))
                    .foregroundColor(WIFPalette.ink)
                WIFKeyValue(key: stage.kind.title, value: stage.summary(store.unit))
                Text("It joins the end of the route you pick. Move it earlier from the route screen if it belongs there.")
                    .font(WIFType.body(11.5))
                    .foregroundColor(WIFPalette.slate)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if store.routes.isEmpty {
                WIFEmptyState(title: "No routes to add it to",
                              message: "Create a route on the Routes tab first, then come back and drop this stage into it.")
            } else {
                WIFSectionLabel(text: "Pick a route")
                ForEach(store.routes) { route in
                    routeButton(route)
                }
            }
        }
    }

    private func routeButton(_ route: WIFRoute) -> some View {
        Button(action: {
            store.append(obstacle: stage, toRouteID: route.id)
            presentationMode.wrappedValue.dismiss()
        }) {
            HStack(alignment: .center, spacing: 11) {
                WIFIcon(glyph: WIFRouteGlyph(), size: 21, color: WIFPalette.ink, weight: 1.9)
                VStack(alignment: .leading, spacing: 2) {
                    Text(route.name)
                        .font(WIFType.semibold(15))
                        .foregroundColor(WIFPalette.ink)
                        .multilineTextAlignment(.leading)
                    Text(route.stops.count == 1 ? "1 stage" : "\(route.stops.count) stages")
                        .font(WIFType.body(11))
                        .foregroundColor(WIFPalette.slate)
                }
                Spacer(minLength: 4)
                WIFIcon(glyph: WIFPlusGlyph(), size: 16, color: WIFPalette.teal, weight: 2.2)
            }
            .padding(WIFMetric.cardPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: WIFMetric.corner).fill(WIFPalette.panel))
            .overlay(RoundedRectangle(cornerRadius: WIFMetric.corner)
                        .stroke(WIFPalette.line, lineWidth: 1))
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}
