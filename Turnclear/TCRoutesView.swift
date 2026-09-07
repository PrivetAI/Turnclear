import SwiftUI

struct TCRoutesView: View {
    @EnvironmentObject private var store: TCStore
    @State private var pendingDelete: UUID?

    var body: some View {
        TCScaffold(title: "Routes", subtitle: "Everything the object has to get past, in order") {
            NavigationLink(destination: TCRouteEditorView(existing: nil).environmentObject(store)) {
                HStack(spacing: 8) {
                    TCIcon(glyph: TCPlusGlyph(), size: 16, color: Color.white, weight: 2.2)
                    Text("Add a route")
                        .font(TCType.semibold(15))
                        .foregroundColor(Color.white)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
                .background(RoundedRectangle(cornerRadius: 12).fill(TCPalette.ink))
                .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())

            if store.routes.isEmpty {
                TCEmptyState(title: "No routes yet",
                              message: "A route is the run from the street to the room: front door, hallway turn, lift, flat door. Order matters, because the answer is only as good as the tightest stage.")
            } else {
                ForEach(store.routes) { route in
                    routeCard(route)
                }
            }
        }
    }

    private func routeCard(_ route: TCRoute) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 10) {
                NavigationLink(destination: TCRouteEditorView(existing: route)
                                .environmentObject(store)) {
                    VStack(alignment: .leading, spacing: 7) {
                        HStack(spacing: 8) {
                            TCIcon(glyph: TCRouteGlyph(), size: 22, color: TCPalette.ink, weight: 1.9)
                            Text(route.name)
                                .font(TCType.semibold(15))
                                .foregroundColor(TCPalette.ink)
                                .lineLimit(2)
                                .multilineTextAlignment(.leading)
                            Spacer(minLength: 4)
                            TCIcon(glyph: TCChevronGlyph(), size: 15, color: TCPalette.slate, weight: 2)
                                .rotationEffect(.degrees(90))
                        }
                        Text(route.stops.isEmpty
                             ? "No stages yet"
                             : route.stops.map { $0.kind.shortTitle }.joined(separator: "  >  "))
                            .font(TCType.body(11.5))
                            .foregroundColor(TCPalette.slate)
                            .fixedSize(horizontal: false, vertical: true)
                            .multilineTextAlignment(.leading)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())

                TCGlyphButton(glyph: TCTrashGlyph(),
                               size: 32,
                               glyphSize: 15,
                               color: TCPalette.rust,
                               background: TCPalette.rustSoft) {
                    pendingDelete = (pendingDelete == route.id) ? nil : route.id
                }
            }

            if pendingDelete == route.id {
                HStack(spacing: 8) {
                    Text("Delete this route?")
                        .font(TCType.body(12))
                        .foregroundColor(TCPalette.rust)
                    Spacer(minLength: 4)
                    Button(action: { pendingDelete = nil }) {
                        Text("Keep")
                            .font(TCType.semibold(12))
                            .foregroundColor(TCPalette.ink)
                            .padding(.horizontal, 12).padding(.vertical, 7)
                            .background(RoundedRectangle(cornerRadius: 8).fill(TCPalette.wash))
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())
                    Button(action: {
                        store.deleteRoute(route.id)
                        pendingDelete = nil
                    }) {
                        Text("Delete")
                            .font(TCType.semibold(12))
                            .foregroundColor(Color.white)
                            .padding(.horizontal, 12).padding(.vertical, 7)
                            .background(RoundedRectangle(cornerRadius: 8).fill(TCPalette.rust))
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .padding(TCMetric.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: TCMetric.corner).fill(TCPalette.panel))
        .overlay(RoundedRectangle(cornerRadius: TCMetric.corner)
                    .stroke(store.selectedRoute?.id == route.id ? TCPalette.ink : TCPalette.line,
                            lineWidth: store.selectedRoute?.id == route.id ? 2 : 1))
    }
}
