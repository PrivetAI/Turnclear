import SwiftUI

private enum WIFRouteField: Hashable {
    case name
}

struct WIFRouteEditorView: View {
    let existing: WIFRoute?

    @EnvironmentObject private var store: WIFStore
    @Environment(\.presentationMode) private var presentationMode
    @FocusState private var focus: WIFRouteField?

    @State private var draft: WIFRoute
    @State private var name: String

    init(existing: WIFRoute?) {
        self.existing = existing
        let base = existing ?? WIFRoute(name: "New route", stops: [])
        _draft = State(initialValue: base)
        _name = State(initialValue: base.name)
    }

    var body: some View {
        WIFScaffold(title: existing == nil ? "New route" : "Edit route",
                    subtitle: "Stages are checked in the order they are listed",
                    showsBack: true) {
            WIFCard {
                WIFTextField(title: "Route name", text: $name, field: WIFRouteField.name, focus: $focus)
            }

            stagesSection

            NavigationLink(destination: WIFObstacleEditorView(existing: nil,
                                                              unit: store.unit,
                                                              onSave: appendStage)) {
                HStack(spacing: 8) {
                    WIFIcon(glyph: WIFPlusGlyph(), size: 16, color: Color.white, weight: 2.2)
                    Text("Add a stage")
                        .font(WIFType.semibold(15))
                        .foregroundColor(Color.white)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
                .background(RoundedRectangle(cornerRadius: 12).fill(WIFPalette.ink))
                .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())

            WIFPrimaryButton(title: "Save route", tint: WIFPalette.teal) { saveRoute() }

            WIFNoticeBox(text: "The Presets tab has typical doors, lifts, turns and stairwells you "
                         + "can drop straight into this route.")
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button(action: { focus = nil }) {
                    Text("Done")
                        .font(WIFType.semibold(15))
                        .foregroundColor(WIFPalette.ink)
                }
            }
        }
    }

    @ViewBuilder
    private var stagesSection: some View {
        if draft.stops.isEmpty {
            WIFEmptyState(title: "No stages yet",
                          message: "Add every door, turn, stairwell and lift between the street and the room, in the order they come.")
        } else {
            VStack(alignment: .leading, spacing: 7) {
                WIFSectionLabel(text: "Stages")
                VStack(spacing: 8) {
                    ForEach(Array(draft.stops.enumerated()), id: \.element.id) { pair in
                        stageCard(index: pair.offset, stage: pair.element)
                    }
                }
            }
        }
    }

    private func stageCard(index: Int, stage: WIFObstacle) -> some View {
        VStack(alignment: .leading, spacing: 9) {
            NavigationLink(destination: WIFObstacleEditorView(existing: stage,
                                                              unit: store.unit,
                                                              onSave: { updated in replaceStage(updated) })) {
                HStack(alignment: .top, spacing: 11) {
                    VStack(spacing: 5) {
                        Text("\(index + 1)")
                            .font(WIFType.figure(12))
                            .foregroundColor(WIFPalette.slate)
                        WIFKindIcon(kind: stage.kind, size: 21, color: WIFPalette.ink)
                    }
                    .frame(width: 28)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(stage.name)
                            .font(WIFType.semibold(14.5))
                            .foregroundColor(WIFPalette.ink)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                        Text(stage.summary(store.unit))
                            .font(WIFType.figure(11))
                            .foregroundColor(WIFPalette.slate)
                            .fixedSize(horizontal: false, vertical: true)
                            .multilineTextAlignment(.leading)
                    }
                    Spacer(minLength: 4)
                    WIFIcon(glyph: WIFChevronGlyph(), size: 14, color: WIFPalette.slate, weight: 2)
                        .rotationEffect(.degrees(90))
                        .padding(.top, 3)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())

            HStack(spacing: 8) {
                WIFGlyphButton(glyph: WIFChevronGlyph(), size: 30, glyphSize: 14,
                               color: WIFPalette.ink, background: WIFPalette.wash,
                               enabled: index > 0) {
                    moveStage(stage, by: -1)
                }
                WIFGlyphButton(glyph: WIFChevronGlyph(), size: 30, glyphSize: 14,
                               color: WIFPalette.ink, background: WIFPalette.wash,
                               enabled: index < draft.stops.count - 1) {
                    moveStage(stage, by: 1)
                }
                .rotationEffect(.degrees(180))
                Spacer(minLength: 4)
                WIFGlyphButton(glyph: WIFTrashGlyph(), size: 30, glyphSize: 14,
                               color: WIFPalette.rust, background: WIFPalette.rustSoft) {
                    removeStage(stage)
                }
            }
        }
        .padding(WIFMetric.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: WIFMetric.corner).fill(WIFPalette.panel))
        .overlay(RoundedRectangle(cornerRadius: WIFMetric.corner).stroke(WIFPalette.line, lineWidth: 1))
    }

    // MARK: Mutations

    private func appendStage(_ stage: WIFObstacle) {
        var next = stage
        next.id = UUID()
        draft.stops.append(next)
        persist()
    }

    private func replaceStage(_ stage: WIFObstacle) {
        if let index = draft.stops.firstIndex(where: { $0.id == stage.id }) {
            draft.stops[index] = stage
        } else {
            draft.stops.append(stage)
        }
        persist()
    }

    private func removeStage(_ stage: WIFObstacle) {
        draft.stops.removeAll(where: { $0.id == stage.id })
        persist()
    }

    private func moveStage(_ stage: WIFObstacle, by offset: Int) {
        guard let from = draft.stops.firstIndex(where: { $0.id == stage.id }) else { return }
        let to = from + offset
        guard to >= 0 && to < draft.stops.count else { return }
        let moved = draft.stops.remove(at: from)
        draft.stops.insert(moved, at: to)
        persist()
    }

    /// Stage edits are kept immediately, so nothing is lost by walking back out of the screen.
    private func persist() {
        draft.name = cleanedName
        store.upsert(route: draft)
    }

    private func saveRoute() {
        draft.name = cleanedName
        focus = nil
        store.upsert(route: draft)
        presentationMode.wrappedValue.dismiss()
    }

    private var cleanedName: String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "Untitled route" : trimmed
    }
}
