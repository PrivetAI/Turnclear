import SwiftUI

struct TCPresetsView: View {
    @EnvironmentObject private var store: TCStore
    @State private var group: TCPresetGroup = .doors

    var body: some View {
        TCScaffold(title: "Presets", subtitle: "Typical sizes, so you have somewhere to start") {
            TCNoticeBox(text: TCPresetLibrary.disclaimer)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(TCPresetGroup.allCases) { option in
                        TCChoiceChip(title: option.title,
                                      detail: nil,
                                      selected: group == option) {
                            group = option
                        }
                    }
                }
                .padding(.vertical, 2)
            }

            Text(group.blurb)
                .font(TCType.body(12))
                .foregroundColor(TCPalette.slate)
                .fixedSize(horizontal: false, vertical: true)

            ForEach(TCPresetLibrary.presets(in: group)) { preset in
                presetCard(preset)
            }
        }
    }

    private func presetCard(_ preset: TCPreset) -> some View {
        let built = preset.build()
        return TCCard {
            HStack(alignment: .top, spacing: 11) {
                TCKindIcon(kind: built.kind, size: 24, color: TCPalette.ink)
                VStack(alignment: .leading, spacing: 3) {
                    Text(preset.title)
                        .font(TCType.semibold(15))
                        .foregroundColor(TCPalette.ink)
                        .fixedSize(horizontal: false, vertical: true)
                        .multilineTextAlignment(.leading)
                    Text(built.summary(store.unit))
                        .font(TCType.figure(11.5))
                        .foregroundColor(TCPalette.slate)
                        .fixedSize(horizontal: false, vertical: true)
                        .multilineTextAlignment(.leading)
                }
                Spacer(minLength: 4)
            }

            NavigationLink(destination: TCPresetAddView(presetTitle: preset.title, stage: built)
                            .environmentObject(store)) {
                HStack(spacing: 7) {
                    TCIcon(glyph: TCPlusGlyph(), size: 14, color: TCPalette.ink, weight: 2.2)
                    Text("Add to a route")
                        .font(TCType.semibold(13))
                        .foregroundColor(TCPalette.ink)
                    Spacer(minLength: 4)
                    TCIcon(glyph: TCChevronGlyph(), size: 13, color: TCPalette.slate, weight: 2)
                        .rotationEffect(.degrees(90))
                }
                .padding(.horizontal, 11)
                .padding(.vertical, 9)
                .background(RoundedRectangle(cornerRadius: 10).fill(TCPalette.wash))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(TCPalette.line, lineWidth: 1))
                .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
}
