import SwiftUI

struct WIFRoutesView: View {
    @EnvironmentObject private var store: WIFStore
    @State private var pendingDelete: UUID?

    var body: some View {
        WIFScaffold(title: "Routes", subtitle: "Everything the object has to get past, in order") {
            NavigationLink(destination: WIFRouteEditorView(existing: nil).environmentObject(store)) {
                HStack(spacing: 8) {
                    WIFIcon(glyph: WIFPlusGlyph(), size: 16, color: Color.white, weight: 2.2)
                    Text("Add a route")
                        .font(WIFType.semibold(15))
                        .foregroundColor(Color.white)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
                .background(RoundedRectangle(cornerRadius: 12).fill(WIFPalette.ink))
                .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())

            if store.routes.isEmpty {
                WIFEmptyState(title: "No routes yet",
                              message: "A route is the run from the street to the room: front door, hallway turn, lift, flat door. Order matters, because the answer is only as good as the tightest stage.")
            } else {
                ForEach(store.routes) { route in
                    routeCard(route)
                }
            }
        }
    }

    private func routeCard(_ route: WIFRoute) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 10) {
                NavigationLink(destination: WIFRouteEditorView(existing: route)
                                .environmentObject(store)) {
                    VStack(alignment: .leading, spacing: 7) {
                        HStack(spacing: 8) {
                            WIFIcon(glyph: WIFRouteGlyph(), size: 22, color: WIFPalette.ink, weight: 1.9)
                            Text(route.name)
                                .font(WIFType.semibold(15))
                                .foregroundColor(WIFPalette.ink)
                                .lineLimit(2)
                                .multilineTextAlignment(.leading)
                            Spacer(minLength: 4)
                            WIFIcon(glyph: WIFChevronGlyph(), size: 15, color: WIFPalette.slate, weight: 2)
                                .rotationEffect(.degrees(90))
                        }
                        Text(route.stops.isEmpty
                             ? "No stages yet"
                             : route.stops.map { $0.kind.shortTitle }.joined(separator: "  >  "))
                            .font(WIFType.body(11.5))
                            .foregroundColor(WIFPalette.slate)
                            .fixedSize(horizontal: false, vertical: true)
                            .multilineTextAlignment(.leading)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())

                WIFGlyphButton(glyph: WIFTrashGlyph(),
                               size: 32,
                               glyphSize: 15,
                               color: WIFPalette.rust,
                               background: WIFPalette.rustSoft) {
                    pendingDelete = (pendingDelete == route.id) ? nil : route.id
                }
            }

            if pendingDelete == route.id {
                HStack(spacing: 8) {
                    Text("Delete this route?")
                        .font(WIFType.body(12))
                        .foregroundColor(WIFPalette.rust)
                    Spacer(minLength: 4)
                    Button(action: { pendingDelete = nil }) {
                        Text("Keep")
                            .font(WIFType.semibold(12))
                            .foregroundColor(WIFPalette.ink)
                            .padding(.horizontal, 12).padding(.vertical, 7)
                            .background(RoundedRectangle(cornerRadius: 8).fill(WIFPalette.wash))
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())
                    Button(action: {
                        store.deleteRoute(route.id)
                        pendingDelete = nil
                    }) {
                        Text("Delete")
                            .font(WIFType.semibold(12))
                            .foregroundColor(Color.white)
                            .padding(.horizontal, 12).padding(.vertical, 7)
                            .background(RoundedRectangle(cornerRadius: 8).fill(WIFPalette.rust))
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .padding(WIFMetric.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: WIFMetric.corner).fill(WIFPalette.panel))
        .overlay(RoundedRectangle(cornerRadius: WIFMetric.corner)
                    .stroke(store.selectedRoute?.id == route.id ? WIFPalette.ink : WIFPalette.line,
                            lineWidth: store.selectedRoute?.id == route.id ? 2 : 1))
    }
}
