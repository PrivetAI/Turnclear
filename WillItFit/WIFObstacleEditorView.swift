import SwiftUI

private enum WIFStageField: Hashable {
    case name, openWidth, openHeight, hinge, corridorA, corridorB, headroom, cabinW, cabinD, cabinH
}

struct WIFObstacleEditorView: View {
    let existing: WIFObstacle?
    let unit: WIFUnit
    let onSave: (WIFObstacle) -> Void

    @Environment(\.presentationMode) private var presentationMode
    @FocusState private var focus: WIFStageField?

    @State private var kind: WIFObstacleKind
    @State private var name: String
    @State private var openWidth: String
    @State private var openHeight: String
    @State private var hinge: String
    @State private var corridorA: String
    @State private var corridorB: String
    @State private var headroom: String
    @State private var cabinW: String
    @State private var cabinD: String
    @State private var cabinH: String
    @State private var problem: String?

    init(existing: WIFObstacle?, unit: WIFUnit, onSave: @escaping (WIFObstacle) -> Void) {
        self.existing = existing
        self.unit = unit
        self.onSave = onSave
        let base = existing ?? WIFObstacle(name: "", kind: .opening)
        _kind = State(initialValue: base.kind)
        _name = State(initialValue: existing?.name ?? "")
        _openWidth = State(initialValue: WIFMeasure.text(base.openWidthMM, unit))
        _openHeight = State(initialValue: WIFMeasure.text(base.openHeightMM, unit))
        _hinge = State(initialValue: WIFMeasure.text(base.hingeGainMM, unit))
        _corridorA = State(initialValue: WIFMeasure.text(base.corridorAMM, unit))
        _corridorB = State(initialValue: WIFMeasure.text(base.corridorBMM, unit))
        _headroom = State(initialValue: WIFMeasure.text(base.headroomMM, unit))
        _cabinW = State(initialValue: WIFMeasure.text(base.cabinWidthMM, unit))
        _cabinD = State(initialValue: WIFMeasure.text(base.cabinDepthMM, unit))
        _cabinH = State(initialValue: WIFMeasure.text(base.cabinHeightMM, unit))
    }

    var body: some View {
        WIFScaffold(title: existing == nil ? "New stage" : "Edit stage",
                    subtitle: kind.blurb,
                    showsBack: true) {
            kindPicker
            presetRow
            WIFCard {
                WIFTextField(title: "Stage name", text: $name, field: WIFStageField.name, focus: $focus)
            }
            measurementCard

            if let problem = problem {
                Text(problem)
                    .font(WIFType.semibold(13))
                    .foregroundColor(WIFPalette.rust)
                    .fixedSize(horizontal: false, vertical: true)
            }

            WIFPrimaryButton(title: existing == nil ? "Add this stage" : "Save stage") { save() }
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

    private var kindPicker: some View {
        VStack(alignment: .leading, spacing: 7) {
            WIFSectionLabel(text: "What kind of stage")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(WIFObstacleKind.allCases, id: \.self) { option in
                        WIFChoiceChip(title: option.title,
                                      detail: nil,
                                      selected: kind == option) {
                            kind = option
                            focus = nil
                        }
                    }
                }
                .padding(.vertical, 2)
            }
        }
    }

    private var presetRow: some View {
        VStack(alignment: .leading, spacing: 7) {
            WIFSectionLabel(text: "Start from a typical size")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(WIFPresetLibrary.presets(in: presetGroup)) { preset in
                        WIFChoiceChip(title: preset.title,
                                      detail: preset.detail,
                                      selected: false) {
                            apply(preset)
                        }
                    }
                }
                .padding(.vertical, 2)
            }
            Text(WIFPresetLibrary.disclaimer)
                .font(WIFType.body(11))
                .foregroundColor(WIFPalette.slate)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var presetGroup: WIFPresetGroup {
        switch kind {
        case .opening: return .doors
        case .turn: return .turns
        case .stair: return .stairs
        case .elevator: return .lifts
        }
    }

    @ViewBuilder
    private var measurementCard: some View {
        switch kind {
        case .opening:
            WIFCard {
                Text("The clear opening")
                    .font(WIFType.heading(15))
                    .foregroundColor(WIFPalette.ink)
                WIFDimensionField(title: "Clear width",
                                  hint: "Lining to lining, with the door open.",
                                  text: $openWidth, unitLabel: unit.shortLabel,
                                  field: WIFStageField.openWidth, focus: $focus)
                WIFDimensionField(title: "Clear height",
                                  hint: "Floor to the underside of the head.",
                                  text: $openHeight, unitLabel: unit.shortLabel,
                                  field: WIFStageField.openHeight, focus: $focus)
                WIFDimensionField(title: "Gain with the leaf off",
                                  hint: "How much wider it gets with the door lifted off its hinges. Usually 3 to 4 cm.",
                                  text: $hinge, unitLabel: unit.shortLabel,
                                  field: WIFStageField.hinge, focus: $focus)
            }
        case .turn:
            WIFCard {
                Text("The two corridors")
                    .font(WIFType.heading(15))
                    .foregroundColor(WIFPalette.ink)
                WIFDimensionField(title: "Corridor coming in",
                                  hint: "Wall to wall, where the object arrives.",
                                  text: $corridorA, unitLabel: unit.shortLabel,
                                  field: WIFStageField.corridorA, focus: $focus)
                WIFDimensionField(title: "Corridor going out",
                                  hint: "Wall to wall, after the turn.",
                                  text: $corridorB, unitLabel: unit.shortLabel,
                                  field: WIFStageField.corridorB, focus: $focus)
                WIFDimensionField(title: "Headroom",
                                  hint: "Leave at 0 if the ceiling is not a problem here.",
                                  text: $headroom, unitLabel: unit.shortLabel,
                                  field: WIFStageField.headroom, focus: $focus)
            }
        case .stair:
            WIFCard {
                Text("The landing")
                    .font(WIFType.heading(15))
                    .foregroundColor(WIFPalette.ink)
                WIFDimensionField(title: "Flight width",
                                  hint: "Wall to handrail on the flight itself.",
                                  text: $corridorA, unitLabel: unit.shortLabel,
                                  field: WIFStageField.corridorA, focus: $focus)
                WIFDimensionField(title: "Landing depth",
                                  hint: "How far the landing runs before the next flight.",
                                  text: $corridorB, unitLabel: unit.shortLabel,
                                  field: WIFStageField.corridorB, focus: $focus)
                WIFDimensionField(title: "Headroom",
                                  hint: "Landing to the underside of the flight above.",
                                  text: $headroom, unitLabel: unit.shortLabel,
                                  field: WIFStageField.headroom, focus: $focus)
            }
        case .elevator:
            WIFCard {
                Text("The door")
                    .font(WIFType.heading(15))
                    .foregroundColor(WIFPalette.ink)
                WIFDimensionField(title: "Door width", hint: nil,
                                  text: $openWidth, unitLabel: unit.shortLabel,
                                  field: WIFStageField.openWidth, focus: $focus)
                WIFDimensionField(title: "Door height", hint: nil,
                                  text: $openHeight, unitLabel: unit.shortLabel,
                                  field: WIFStageField.openHeight, focus: $focus)
            }
            WIFCard {
                Text("The cabin")
                    .font(WIFType.heading(15))
                    .foregroundColor(WIFPalette.ink)
                WIFDimensionField(title: "Cabin width", hint: nil,
                                  text: $cabinW, unitLabel: unit.shortLabel,
                                  field: WIFStageField.cabinW, focus: $focus)
                WIFDimensionField(title: "Cabin depth", hint: nil,
                                  text: $cabinD, unitLabel: unit.shortLabel,
                                  field: WIFStageField.cabinD, focus: $focus)
                WIFDimensionField(title: "Cabin height",
                                  hint: "Floor to ceiling inside the cabin.",
                                  text: $cabinH, unitLabel: unit.shortLabel,
                                  field: WIFStageField.cabinH, focus: $focus)
            }
        }
    }

    // MARK: Actions

    private func apply(_ preset: WIFPreset) {
        let built = preset.build()
        kind = built.kind
        if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            name = built.name
        }
        openWidth = WIFMeasure.text(built.openWidthMM, unit)
        openHeight = WIFMeasure.text(built.openHeightMM, unit)
        hinge = WIFMeasure.text(built.hingeGainMM, unit)
        corridorA = WIFMeasure.text(built.corridorAMM, unit)
        corridorB = WIFMeasure.text(built.corridorBMM, unit)
        headroom = WIFMeasure.text(built.headroomMM, unit)
        cabinW = WIFMeasure.text(built.cabinWidthMM, unit)
        cabinD = WIFMeasure.text(built.cabinDepthMM, unit)
        cabinH = WIFMeasure.text(built.cabinHeightMM, unit)
        focus = nil
    }

    private func save() {
        var stage = existing ?? WIFObstacle(name: "", kind: kind)
        stage.kind = kind

        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        stage.name = trimmed.isEmpty ? kind.title : trimmed

        func value(_ raw: String) -> Double? {
            guard let parsed = WIFMeasure.parse(raw), parsed > 0 else { return nil }
            return WIFMeasure.toMillimetres(parsed, unit)
        }

        switch kind {
        case .opening, .elevator:
            guard let w = value(openWidth), let h = value(openHeight) else {
                problem = "The opening needs a width and a height greater than zero."
                return
            }
            stage.openWidthMM = w
            stage.openHeightMM = h
            stage.hingeGainMM = WIFMeasure.toMillimetres(max(0, WIFMeasure.parse(hinge) ?? 0), unit)
            if kind == .elevator {
                guard let cw = value(cabinW), let cd = value(cabinD), let ch = value(cabinH) else {
                    problem = "The cabin needs a width, a depth and a height greater than zero."
                    return
                }
                stage.cabinWidthMM = cw
                stage.cabinDepthMM = cd
                stage.cabinHeightMM = ch
                stage.hingeGainMM = 0
            }
        case .turn, .stair:
            guard let a = value(corridorA), let b = value(corridorB) else {
                problem = "Both corridor widths need a number greater than zero."
                return
            }
            stage.corridorAMM = a
            stage.corridorBMM = b
            let head = max(0, WIFMeasure.parse(headroom) ?? 0)
            stage.headroomMM = head > 0 ? WIFMeasure.toMillimetres(head, unit) : 0
            if kind == .stair && stage.headroomMM <= 0 {
                problem = "A stairwell needs a headroom figure — that is what makes it different from a plain turn."
                return
            }
        }

        problem = nil
        focus = nil
        onSave(stage)
        presentationMode.wrappedValue.dismiss()
    }
}
