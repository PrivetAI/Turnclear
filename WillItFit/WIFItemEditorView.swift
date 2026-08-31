import SwiftUI

private enum WIFItemField: Hashable {
    case name, width, height, depth, legs, packaging, weight, removable, note
}

struct WIFItemEditorView: View {
    let existing: WIFItem?
    let unit: WIFUnit

    @EnvironmentObject private var store: WIFStore
    @Environment(\.presentationMode) private var presentationMode
    @FocusState private var focus: WIFItemField?

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

    init(existing: WIFItem?, unit: WIFUnit) {
        self.existing = existing
        self.unit = unit
        let source = existing
        _name = State(initialValue: source?.name ?? "")
        _width = State(initialValue: source.map { WIFMeasure.text($0.widthMM, unit) } ?? "")
        _height = State(initialValue: source.map { WIFMeasure.text($0.heightMM, unit) } ?? "")
        _depth = State(initialValue: source.map { WIFMeasure.text($0.depthMM, unit) } ?? "")
        _legs = State(initialValue: source.map { WIFMeasure.text($0.legHeightMM, unit) } ?? "0")
        _packaging = State(initialValue: source.map { WIFMeasure.text($0.packagingMM, unit) } ?? "0")
        _weight = State(initialValue: source.map { WIFMeasure.format($0.weightKG, decimals: 1) } ?? "0")
        _removable = State(initialValue: source.map { WIFMeasure.format($0.removableWeightKG, decimals: 1) } ?? "0")
        _note = State(initialValue: source?.note ?? "")
    }

    var body: some View {
        WIFScaffold(title: existing == nil ? "New object" : "Edit object",
                    subtitle: "Measure over the widest part",
                    showsBack: true) {
            WIFCard {
                WIFTextField(title: "Name", text: $name, field: WIFItemField.name, focus: $focus)
            }

            WIFCard {
                Text("Outside size")
                    .font(WIFType.heading(15))
                    .foregroundColor(WIFPalette.ink)
                WIFDimensionField(title: "Width",
                                  hint: "Side to side, as it normally stands.",
                                  text: $width, unitLabel: unit.shortLabel,
                                  field: WIFItemField.width, focus: $focus)
                WIFDimensionField(title: "Height",
                                  hint: "Floor to the highest point.",
                                  text: $height, unitLabel: unit.shortLabel,
                                  field: WIFItemField.height, focus: $focus)
                WIFDimensionField(title: "Depth",
                                  hint: "Front to back, handles included.",
                                  text: $depth, unitLabel: unit.shortLabel,
                                  field: WIFItemField.depth, focus: $focus)
            }

            WIFCard {
                Text("What comes off")
                    .font(WIFType.heading(15))
                    .foregroundColor(WIFPalette.ink)
                Text("These feed the switches on the check screen.")
                    .font(WIFType.body(11))
                    .foregroundColor(WIFPalette.slate)
                WIFDimensionField(title: "Leg height",
                                  hint: "How much shorter it gets with the legs off.",
                                  text: $legs, unitLabel: unit.shortLabel,
                                  field: WIFItemField.legs, focus: $focus)
                WIFDimensionField(title: "Packaging adds",
                                  hint: "Extra on every dimension while it is still boxed.",
                                  text: $packaging, unitLabel: unit.shortLabel,
                                  field: WIFItemField.packaging, focus: $focus)
            }

            WIFCard {
                Text("Weight")
                    .font(WIFType.heading(15))
                    .foregroundColor(WIFPalette.ink)
                WIFDimensionField(title: "Total weight", hint: nil,
                                  text: $weight, unitLabel: "kg",
                                  field: WIFItemField.weight, focus: $focus)
                WIFDimensionField(title: "Removable weight",
                                  hint: "Drawers, shelves and cushions that come out first.",
                                  text: $removable, unitLabel: "kg",
                                  field: WIFItemField.removable, focus: $focus)
            }

            WIFCard {
                WIFTextField(title: "Note", text: $note, field: WIFItemField.note, focus: $focus)
                Text("Anything worth remembering, such as whether the handle was included.")
                    .font(WIFType.body(11))
                    .foregroundColor(WIFPalette.slate)
            }

            if let problem = problem {
                Text(problem)
                    .font(WIFType.semibold(13))
                    .foregroundColor(WIFPalette.rust)
                    .fixedSize(horizontal: false, vertical: true)
            }

            WIFPrimaryButton(title: existing == nil ? "Save object" : "Save changes") { save() }

            if let current = existing {
                WIFGhostButton(title: "Delete this object", tint: WIFPalette.rust) {
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
                        .font(WIFType.semibold(15))
                        .foregroundColor(WIFPalette.ink)
                }
            }
        }
    }

    private func save() {
        guard let w = WIFMeasure.parse(width), w > 0,
              let h = WIFMeasure.parse(height), h > 0,
              let d = WIFMeasure.parse(depth), d > 0 else {
            problem = "Width, height and depth all need a number greater than zero."
            return
        }
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        var item = existing ?? WIFItem(name: "", widthMM: 0, heightMM: 0, depthMM: 0)
        item.name = trimmed.isEmpty ? "Untitled object" : trimmed
        item.widthMM = WIFMeasure.toMillimetres(w, unit)
        item.heightMM = WIFMeasure.toMillimetres(h, unit)
        item.depthMM = WIFMeasure.toMillimetres(d, unit)
        item.legHeightMM = WIFMeasure.toMillimetres(max(0, WIFMeasure.parse(legs) ?? 0), unit)
        item.packagingMM = WIFMeasure.toMillimetres(max(0, WIFMeasure.parse(packaging) ?? 0), unit)
        item.weightKG = max(0, WIFMeasure.parse(weight) ?? 0)
        item.removableWeightKG = max(0, WIFMeasure.parse(removable) ?? 0)
        item.note = note.trimmingCharacters(in: .whitespacesAndNewlines)
        problem = nil
        focus = nil
        store.upsert(item: item)
        presentationMode.wrappedValue.dismiss()
    }
}
