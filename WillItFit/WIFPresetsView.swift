import SwiftUI

struct WIFPresetsView: View {
    @EnvironmentObject private var store: WIFStore
    @State private var group: WIFPresetGroup = .doors

    var body: some View {
        WIFScaffold(title: "Presets", subtitle: "Typical sizes, so you have somewhere to start") {
            WIFNoticeBox(text: WIFPresetLibrary.disclaimer)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(WIFPresetGroup.allCases) { option in
                        WIFChoiceChip(title: option.title,
                                      detail: nil,
                                      selected: group == option) {
                            group = option
                        }
                    }
                }
                .padding(.vertical, 2)
            }

            Text(group.blurb)
                .font(WIFType.body(12))
                .foregroundColor(WIFPalette.slate)
                .fixedSize(horizontal: false, vertical: true)

            ForEach(WIFPresetLibrary.presets(in: group)) { preset in
                presetCard(preset)
            }
        }
    }

    private func presetCard(_ preset: WIFPreset) -> some View {
        let built = preset.build()
        return WIFCard {
            HStack(alignment: .top, spacing: 11) {
                WIFKindIcon(kind: built.kind, size: 24, color: WIFPalette.ink)
                VStack(alignment: .leading, spacing: 3) {
                    Text(preset.title)
                        .font(WIFType.semibold(15))
                        .foregroundColor(WIFPalette.ink)
                        .fixedSize(horizontal: false, vertical: true)
                        .multilineTextAlignment(.leading)
                    Text(built.summary(store.unit))
                        .font(WIFType.figure(11.5))
                        .foregroundColor(WIFPalette.slate)
                        .fixedSize(horizontal: false, vertical: true)
                        .multilineTextAlignment(.leading)
                }
                Spacer(minLength: 4)
            }

            NavigationLink(destination: WIFPresetAddView(presetTitle: preset.title, stage: built)
                            .environmentObject(store)) {
                HStack(spacing: 7) {
                    WIFIcon(glyph: WIFPlusGlyph(), size: 14, color: WIFPalette.ink, weight: 2.2)
                    Text("Add to a route")
                        .font(WIFType.semibold(13))
                        .foregroundColor(WIFPalette.ink)
                    Spacer(minLength: 4)
                    WIFIcon(glyph: WIFChevronGlyph(), size: 13, color: WIFPalette.slate, weight: 2)
                        .rotationEffect(.degrees(90))
                }
                .padding(.horizontal, 11)
                .padding(.vertical, 9)
                .background(RoundedRectangle(cornerRadius: 10).fill(WIFPalette.wash))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(WIFPalette.line, lineWidth: 1))
                .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
}
