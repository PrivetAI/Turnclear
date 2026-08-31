import SwiftUI

/// Five sections behind a hand-built tab bar. A SwiftUI TabView cannot show a custom drawn icon
/// in `.tabItem`, so the bar is an HStack of ordinary buttons with a switch for the content.
struct WIFRootView: View {
    @EnvironmentObject private var store: WIFStore
    @State private var tab = 0

    var body: some View {
        VStack(spacing: 0) {
            Group {
                switch tab {
                case 0:
                    NavigationView { WIFCheckView() }
                        .navigationViewStyle(StackNavigationViewStyle())
                case 1:
                    NavigationView { WIFItemsView() }
                        .navigationViewStyle(StackNavigationViewStyle())
                case 2:
                    NavigationView { WIFRoutesView() }
                        .navigationViewStyle(StackNavigationViewStyle())
                case 3:
                    NavigationView { WIFPresetsView() }
                        .navigationViewStyle(StackNavigationViewStyle())
                default:
                    NavigationView { WIFSettingsView() }
                        .navigationViewStyle(StackNavigationViewStyle())
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            tabBar
        }
        .background(WIFPalette.paper.edgesIgnoringSafeArea(.all))
    }

    private var tabBar: some View {
        HStack(spacing: 0) {
            tabButton(index: 0, label: "Check") { colour in
                AnyView(WIFIcon(glyph: WIFDoorGlyph(), size: 23, color: colour, weight: 1.9))
            }
            tabButton(index: 1, label: "Items") { colour in
                AnyView(WIFIcon(glyph: WIFSofaGlyph(), size: 23, color: colour, weight: 1.7))
            }
            tabButton(index: 2, label: "Routes") { colour in
                AnyView(WIFIcon(glyph: WIFRouteGlyph(), size: 23, color: colour, weight: 1.9))
            }
            tabButton(index: 3, label: "Presets") { colour in
                AnyView(WIFIcon(glyph: WIFRulerGlyph(), size: 23, color: colour, weight: 1.7))
            }
            tabButton(index: 4, label: "Setup") { colour in
                AnyView(WIFIcon(glyph: WIFSlidersGlyph(), size: 23, color: colour, weight: 1.7))
            }
        }
        .padding(.top, 7)
        .padding(.bottom, 4)
        .background(
            WIFPalette.panel
                .overlay(Rectangle().fill(WIFPalette.line).frame(height: 1), alignment: .top)
                .edgesIgnoringSafeArea(.bottom)
        )
    }

    private func tabButton(index: Int,
                           label: String,
                           icon: (Color) -> AnyView) -> some View {
        let active = tab == index
        let tint = active ? WIFPalette.ink : WIFPalette.slate.opacity(0.6)
        return Button(action: { tab = index }) {
            VStack(spacing: 3) {
                icon(tint)
                Text(label)
                    .font(WIFType.semibold(10))
                    .foregroundColor(tint)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Capsule()
                    .fill(active ? WIFPalette.amber : Color.clear)
                    .frame(width: 16, height: 2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 3)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}
