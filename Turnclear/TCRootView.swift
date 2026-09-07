import SwiftUI

/// Five sections behind a hand-built tab bar. A SwiftUI TabView cannot show a custom drawn icon
/// in `.tabItem`, so the bar is an HStack of ordinary buttons with a switch for the content.
struct TCRootView: View {
    @EnvironmentObject private var store: TCStore
    @State private var tab = 0

    var body: some View {
        VStack(spacing: 0) {
            Group {
                switch tab {
                case 0:
                    NavigationView { TCCheckView() }
                        .navigationViewStyle(StackNavigationViewStyle())
                case 1:
                    NavigationView { TCItemsView() }
                        .navigationViewStyle(StackNavigationViewStyle())
                case 2:
                    NavigationView { TCRoutesView() }
                        .navigationViewStyle(StackNavigationViewStyle())
                case 3:
                    NavigationView { TCPresetsView() }
                        .navigationViewStyle(StackNavigationViewStyle())
                default:
                    NavigationView { TCSettingsView() }
                        .navigationViewStyle(StackNavigationViewStyle())
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            tabBar
        }
        .background(TCPalette.paper.edgesIgnoringSafeArea(.all))
    }

    private var tabBar: some View {
        HStack(spacing: 0) {
            tabButton(index: 0, label: "Check") { colour in
                AnyView(TCIcon(glyph: TCDoorGlyph(), size: 23, color: colour, weight: 1.9))
            }
            tabButton(index: 1, label: "Items") { colour in
                AnyView(TCIcon(glyph: TCSofaGlyph(), size: 23, color: colour, weight: 1.7))
            }
            tabButton(index: 2, label: "Routes") { colour in
                AnyView(TCIcon(glyph: TCRouteGlyph(), size: 23, color: colour, weight: 1.9))
            }
            tabButton(index: 3, label: "Presets") { colour in
                AnyView(TCIcon(glyph: TCRulerGlyph(), size: 23, color: colour, weight: 1.7))
            }
            tabButton(index: 4, label: "Setup") { colour in
                AnyView(TCIcon(glyph: TCSlidersGlyph(), size: 23, color: colour, weight: 1.7))
            }
        }
        .padding(.top, 7)
        .padding(.bottom, 4)
        .background(
            TCPalette.panel
                .overlay(Rectangle().fill(TCPalette.line).frame(height: 1), alignment: .top)
                .edgesIgnoringSafeArea(.bottom)
        )
    }

    private func tabButton(index: Int,
                           label: String,
                           icon: (Color) -> AnyView) -> some View {
        let active = tab == index
        let tint = active ? TCPalette.ink : TCPalette.slate.opacity(0.6)
        return Button(action: { tab = index }) {
            VStack(spacing: 3) {
                icon(tint)
                Text(label)
                    .font(TCType.semibold(10))
                    .foregroundColor(tint)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Capsule()
                    .fill(active ? TCPalette.amber : Color.clear)
                    .frame(width: 16, height: 2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 3)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}
