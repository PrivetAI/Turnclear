import SwiftUI

struct TCItemsView: View {
    @EnvironmentObject private var store: TCStore
    @State private var pendingDelete: UUID?

    var body: some View {
        TCScaffold(title: "Items", subtitle: "The things you want to move") {
            NavigationLink(destination: TCItemEditorView(existing: nil, unit: store.unit)
                            .environmentObject(store)) {
                HStack(spacing: 8) {
                    TCIcon(glyph: TCPlusGlyph(), size: 16, color: Color.white, weight: 2.2)
                    Text("Add an object")
                        .font(TCType.semibold(15))
                        .foregroundColor(Color.white)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
                .background(RoundedRectangle(cornerRadius: 12).fill(TCPalette.ink))
                .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())

            if store.items.isEmpty {
                TCEmptyState(title: "Nothing saved yet",
                              message: "Add the width, height and depth of the piece you are thinking of buying. Measure over the widest part, handles and feet included.")
            } else {
                ForEach(store.items) { item in
                    itemCard(item)
                }
            }

            TCNoticeBox(text: "Measure over the widest point: arms, handles, hinges and feet all count. "
                         + "A number taken off a shop listing is a starting point, not a fact.")
        }
    }

    private func itemCard(_ item: TCItem) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            // The row and the delete control are siblings, never nested — a button inside another
            // button's label never fires.
            HStack(alignment: .top, spacing: 10) {
                NavigationLink(destination: TCItemEditorView(existing: item, unit: store.unit)
                                .environmentObject(store)) {
                    HStack(alignment: .top, spacing: 11) {
                        TCIcon(glyph: TCSofaGlyph(), size: 26, color: TCPalette.ink, weight: 1.7)
                        VStack(alignment: .leading, spacing: 3) {
                            Text(item.name)
                                .font(TCType.semibold(15))
                                .foregroundColor(TCPalette.ink)
                                .lineLimit(2)
                                .multilineTextAlignment(.leading)
                            Text(TCMeasure.triple(item.widthMM, item.heightMM, item.depthMM, store.unit))
                                .font(TCType.figure(12))
                                .foregroundColor(TCPalette.slate)
                            if item.weightKG > 0 {
                                Text(TCMeasure.weightText(item.weightKG)
                                     + (item.removableWeightKG > 0
                                        ? "  (" + TCMeasure.weightText(item.removableWeightKG) + " removable)" : ""))
                                    .font(TCType.body(11))
                                    .foregroundColor(TCPalette.slate)
                            }
                        }
                        Spacer(minLength: 4)
                        TCIcon(glyph: TCChevronGlyph(), size: 15, color: TCPalette.slate, weight: 2)
                            .rotationEffect(.degrees(90))
                            .padding(.top, 3)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())

                TCGlyphButton(glyph: TCTrashGlyph(),
                               size: 32,
                               glyphSize: 15,
                               color: TCPalette.rust,
                               background: TCPalette.rustSoft) {
                    pendingDelete = (pendingDelete == item.id) ? nil : item.id
                }
            }

            if pendingDelete == item.id {
                HStack(spacing: 8) {
                    Text("Delete this object?")
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
                        store.deleteItem(item.id)
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
                    .stroke(store.selectedItem?.id == item.id ? TCPalette.ink : TCPalette.line,
                            lineWidth: store.selectedItem?.id == item.id ? 2 : 1))
    }
}
