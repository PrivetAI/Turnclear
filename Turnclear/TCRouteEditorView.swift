import SwiftUI

private enum TCRouteField: Hashable {
    case name
}

struct TCRouteEditorView: View {
    let existing: TCRoute?

    @EnvironmentObject private var store: TCStore
    @Environment(\.presentationMode) private var presentationMode
    @FocusState private var focus: TCRouteField?

    @State private var draft: TCRoute
    @State private var name: String

    init(existing: TCRoute?) {
        self.existing = existing
        let base = existing ?? TCRoute(name: "New route", stops: [])
        _draft = State(initialValue: base)
        _name = State(initialValue: base.name)
    }

    var body: some View {
        TCScaffold(title: existing == nil ? "New route" : "Edit route",
                    subtitle: "Stages are checked in the order they are listed",
                    showsBack: true) {
            TCCard {
                TCTextField(title: "Route name", text: $name, field: TCRouteField.name, focus: $focus)
            }

            stagesSection

            NavigationLink(destination: TCObstacleEditorView(existing: nil,
                                                              unit: store.unit,
                                                              onSave: appendStage)) {
                HStack(spacing: 8) {
                    TCIcon(glyph: TCPlusGlyph(), size: 16, color: Color.white, weight: 2.2)
                    Text("Add a stage")
                        .font(TCType.semibold(15))
                        .foregroundColor(Color.white)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
                .background(RoundedRectangle(cornerRadius: 12).fill(TCPalette.ink))
                .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())

            TCPrimaryButton(title: "Save route", tint: TCPalette.teal) { saveRoute() }

            TCNoticeBox(text: "The Presets tab has typical doors, lifts, turns and stairwells you "
                         + "can drop straight into this route.")
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button(action: { focus = nil }) {
                    Text("Done")
                        .font(TCType.semibold(15))
                        .foregroundColor(TCPalette.ink)
                }
            }
        }
    }

    @ViewBuilder
    private var stagesSection: some View {
        if draft.stops.isEmpty {
            TCEmptyState(title: "No stages yet",
                          message: "Add every door, turn, stairwell and lift between the street and the room, in the order they come.")
        } else {
            VStack(alignment: .leading, spacing: 7) {
                TCSectionLabel(text: "Stages")
                VStack(spacing: 8) {
                    ForEach(Array(draft.stops.enumerated()), id: \.element.id) { pair in
                        stageCard(index: pair.offset, stage: pair.element)
                    }
                }
            }
        }
    }

    private func stageCard(index: Int, stage: TCObstacle) -> some View {
        VStack(alignment: .leading, spacing: 9) {
            NavigationLink(destination: TCObstacleEditorView(existing: stage,
                                                              unit: store.unit,
                                                              onSave: { updated in replaceStage(updated) })) {
                HStack(alignment: .top, spacing: 11) {
                    VStack(spacing: 5) {
                        Text("\(index + 1)")
                            .font(TCType.figure(12))
                            .foregroundColor(TCPalette.slate)
                        TCKindIcon(kind: stage.kind, size: 21, color: TCPalette.ink)
                    }
                    .frame(width: 28)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(stage.name)
                            .font(TCType.semibold(14.5))
                            .foregroundColor(TCPalette.ink)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                        Text(stage.summary(store.unit))
                            .font(TCType.figure(11))
                            .foregroundColor(TCPalette.slate)
                            .fixedSize(horizontal: false, vertical: true)
                            .multilineTextAlignment(.leading)
                    }
                    Spacer(minLength: 4)
                    TCIcon(glyph: TCChevronGlyph(), size: 14, color: TCPalette.slate, weight: 2)
                        .rotationEffect(.degrees(90))
                        .padding(.top, 3)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())

            HStack(spacing: 8) {
                TCGlyphButton(glyph: TCChevronGlyph(), size: 30, glyphSize: 14,
                               color: TCPalette.ink, background: TCPalette.wash,
                               enabled: index > 0) {
                    moveStage(stage, by: -1)
                }
                TCGlyphButton(glyph: TCChevronGlyph(), size: 30, glyphSize: 14,
                               color: TCPalette.ink, background: TCPalette.wash,
                               enabled: index < draft.stops.count - 1) {
                    moveStage(stage, by: 1)
                }
                .rotationEffect(.degrees(180))
                Spacer(minLength: 4)
                TCGlyphButton(glyph: TCTrashGlyph(), size: 30, glyphSize: 14,
                               color: TCPalette.rust, background: TCPalette.rustSoft) {
                    removeStage(stage)
                }
            }
        }
        .padding(TCMetric.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: TCMetric.corner).fill(TCPalette.panel))
        .overlay(RoundedRectangle(cornerRadius: TCMetric.corner).stroke(TCPalette.line, lineWidth: 1))
    }

    // MARK: Mutations

    private func appendStage(_ stage: TCObstacle) {
        var next = stage
        next.id = UUID()
        draft.stops.append(next)
        persist()
    }

    private func replaceStage(_ stage: TCObstacle) {
        if let index = draft.stops.firstIndex(where: { $0.id == stage.id }) {
            draft.stops[index] = stage
        } else {
            draft.stops.append(stage)
        }
        persist()
    }

    private func removeStage(_ stage: TCObstacle) {
        draft.stops.removeAll(where: { $0.id == stage.id })
        persist()
    }

    private func moveStage(_ stage: TCObstacle, by offset: Int) {
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
