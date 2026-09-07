import SwiftUI

private enum TCItemField: Hashable {
    case name, width, height, depth, legs, packaging, weight, removable, note
}

struct TCItemEditorView: View {
    let existing: TCItem?
    let unit: TCUnit

    @EnvironmentObject private var store: TCStore
    @Environment(\.presentationMode) private var presentationMode
    @FocusState private var focus: TCItemField?

    @State private var name: String
    @State private var width: String
    @State private var height: String
    @State private var depth: String
    @State private var legs: String
    @State private var packaging: String
    @State private var weight: String
    @State private var removable: String
    @State private var note: String
    @State private var problem: String?

    init(existing: TCItem?, unit: TCUnit) {
        self.existing = existing
        self.unit = unit
        let source = existing
        _name = State(initialValue: source?.name ?? "")
        _width = State(initialValue: source.map { TCMeasure.text($0.widthMM, unit) } ?? "")
        _height = State(initialValue: source.map { TCMeasure.text($0.heightMM, unit) } ?? "")
        _depth = State(initialValue: source.map { TCMeasure.text($0.depthMM, unit) } ?? "")
        _legs = State(initialValue: source.map { TCMeasure.text($0.legHeightMM, unit) } ?? "0")
        _packaging = State(initialValue: source.map { TCMeasure.text($0.packagingMM, unit) } ?? "0")
        _weight = State(initialValue: source.map { TCMeasure.format($0.weightKG, decimals: 1) } ?? "0")
        _removable = State(initialValue: source.map { TCMeasure.format($0.removableWeightKG, decimals: 1) } ?? "0")
        _note = State(initialValue: source?.note ?? "")
    }

    var body: some View {
        TCScaffold(title: existing == nil ? "New object" : "Edit object",
                    subtitle: "Measure over the widest part",
                    showsBack: true) {
            TCCard {
                TCTextField(title: "Name", text: $name, field: TCItemField.name, focus: $focus)
            }

            TCCard {
                Text("Outside size")
                    .font(TCType.heading(15))
                    .foregroundColor(TCPalette.ink)
                TCDimensionField(title: "Width",
                                  hint: "Side to side, as it normally stands.",
                                  text: $width, unitLabel: unit.shortLabel,
                                  field: TCItemField.width, focus: $focus)
                TCDimensionField(title: "Height",
                                  hint: "Floor to the highest point.",
                                  text: $height, unitLabel: unit.shortLabel,
                                  field: TCItemField.height, focus: $focus)
                TCDimensionField(title: "Depth",
                                  hint: "Front to back, handles included.",
                                  text: $depth, unitLabel: unit.shortLabel,
                                  field: TCItemField.depth, focus: $focus)
            }

            TCCard {
                Text("What comes off")
                    .font(TCType.heading(15))
                    .foregroundColor(TCPalette.ink)
                Text("These feed the switches on the check screen.")
                    .font(TCType.body(11))
                    .foregroundColor(TCPalette.slate)
                TCDimensionField(title: "Leg height",
                                  hint: "How much shorter it gets with the legs off.",
                                  text: $legs, unitLabel: unit.shortLabel,
                                  field: TCItemField.legs, focus: $focus)
                TCDimensionField(title: "Packaging adds",
                                  hint: "Extra on every dimension while it is still boxed.",
                                  text: $packaging, unitLabel: unit.shortLabel,
                                  field: TCItemField.packaging, focus: $focus)
            }

            TCCard {
                Text("Weight")
                    .font(TCType.heading(15))
                    .foregroundColor(TCPalette.ink)
                TCDimensionField(title: "Total weight", hint: nil,
                                  text: $weight, unitLabel: "kg",
                                  field: TCItemField.weight, focus: $focus)
                TCDimensionField(title: "Removable weight",
                                  hint: "Drawers, shelves and cushions that come out first.",
                                  text: $removable, unitLabel: "kg",
                                  field: TCItemField.removable, focus: $focus)
            }

            TCCard {
                TCTextField(title: "Note", text: $note, field: TCItemField.note, focus: $focus)
                Text("Anything worth remembering, such as whether the handle was included.")
                    .font(TCType.body(11))
                    .foregroundColor(TCPalette.slate)
            }

            if let problem = problem {
                Text(problem)
                    .font(TCType.semibold(13))
                    .foregroundColor(TCPalette.rust)
                    .fixedSize(horizontal: false, vertical: true)
            }

            TCPrimaryButton(title: existing == nil ? "Save object" : "Save changes") { save() }

            if let current = existing {
                TCGhostButton(title: "Delete this object", tint: TCPalette.rust) {
                    store.deleteItem(current.id)
                    presentationMode.wrappedValue.dismiss()
                }
            }
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

    private func save() {
        guard let w = TCMeasure.parse(width), w > 0,
              let h = TCMeasure.parse(height), h > 0,
              let d = TCMeasure.parse(depth), d > 0 else {
            problem = "Width, height and depth all need a number greater than zero."
            return
        }
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        var item = existing ?? TCItem(name: "", widthMM: 0, heightMM: 0, depthMM: 0)
        item.name = trimmed.isEmpty ? "Untitled object" : trimmed
        item.widthMM = TCMeasure.toMillimetres(w, unit)
        item.heightMM = TCMeasure.toMillimetres(h, unit)
        item.depthMM = TCMeasure.toMillimetres(d, unit)
        item.legHeightMM = TCMeasure.toMillimetres(max(0, TCMeasure.parse(legs) ?? 0), unit)
        item.packagingMM = TCMeasure.toMillimetres(max(0, TCMeasure.parse(packaging) ?? 0), unit)
        item.weightKG = max(0, TCMeasure.parse(weight) ?? 0)
        item.removableWeightKG = max(0, TCMeasure.parse(removable) ?? 0)
        item.note = note.trimmingCharacters(in: .whitespacesAndNewlines)
        problem = nil
        focus = nil
        store.upsert(item: item)
        presentationMode.wrappedValue.dismiss()
    }
}
