import SwiftUI

struct WIFItemsView: View {
    @EnvironmentObject private var store: WIFStore
    @State private var pendingDelete: UUID?

    var body: some View {
        WIFScaffold(title: "Items", subtitle: "The things you want to move") {
            NavigationLink(destination: WIFItemEditorView(existing: nil, unit: store.unit)
                            .environmentObject(store)) {
                HStack(spacing: 8) {
                    WIFIcon(glyph: WIFPlusGlyph(), size: 16, color: Color.white, weight: 2.2)
                    Text("Add an object")
                        .font(WIFType.semibold(15))
                        .foregroundColor(Color.white)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
                .background(RoundedRectangle(cornerRadius: 12).fill(WIFPalette.ink))
                .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())

            if store.items.isEmpty {
                WIFEmptyState(title: "Nothing saved yet",
                              message: "Add the width, height and depth of the piece you are thinking of buying. Measure over the widest part, handles and feet included.")
            } else {
                ForEach(store.items) { item in
                    itemCard(item)
                }
            }

            WIFNoticeBox(text: "Measure over the widest point: arms, handles, hinges and feet all count. "
                         + "A number taken off a shop listing is a starting point, not a fact.")
        }
    }

    private func itemCard(_ item: WIFItem) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            // The row and the delete control are siblings, never nested — a button inside another
            // button's label never fires.
            HStack(alignment: .top, spacing: 10) {
                NavigationLink(destination: WIFItemEditorView(existing: item, unit: store.unit)
                                .environmentObject(store)) {
                    HStack(alignment: .top, spacing: 11) {
                        WIFIcon(glyph: WIFSofaGlyph(), size: 26, color: WIFPalette.ink, weight: 1.7)
                        VStack(alignment: .leading, spacing: 3) {
                            Text(item.name)
                                .font(WIFType.semibold(15))
                                .foregroundColor(WIFPalette.ink)
                                .lineLimit(2)
                                .multilineTextAlignment(.leading)
                            Text(WIFMeasure.triple(item.widthMM, item.heightMM, item.depthMM, store.unit))
                                .font(WIFType.figure(12))
                                .foregroundColor(WIFPalette.slate)
                            if item.weightKG > 0 {
                                Text(WIFMeasure.weightText(item.weightKG)
                                     + (item.removableWeightKG > 0
                                        ? "  (" + WIFMeasure.weightText(item.removableWeightKG) + " removable)" : ""))
                                    .font(WIFType.body(11))
                                    .foregroundColor(WIFPalette.slate)
                            }
                        }
                        Spacer(minLength: 4)
                        WIFIcon(glyph: WIFChevronGlyph(), size: 15, color: WIFPalette.slate, weight: 2)
                            .rotationEffect(.degrees(90))
                            .padding(.top, 3)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())

                WIFGlyphButton(glyph: WIFTrashGlyph(),
                               size: 32,
                               glyphSize: 15,
                               color: WIFPalette.rust,
                               background: WIFPalette.rustSoft) {
                    pendingDelete = (pendingDelete == item.id) ? nil : item.id
                }
            }

            if pendingDelete == item.id {
                HStack(spacing: 8) {
                    Text("Delete this object?")
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
                        store.deleteItem(item.id)
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
                    .stroke(store.selectedItem?.id == item.id ? WIFPalette.ink : WIFPalette.line,
                            lineWidth: store.selectedItem?.id == item.id ? 2 : 1))
    }
}
