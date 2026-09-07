import SwiftUI

private enum TCStageField: Hashable {
    case name, openWidth, openHeight, hinge, corridorA, corridorB, headroom, cabinW, cabinD, cabinH
}

struct TCObstacleEditorView: View {
    let existing: TCObstacle?
    let unit: TCUnit
    let onSave: (TCObstacle) -> Void

    @Environment(\.presentationMode) private var presentationMode
    @FocusState private var focus: TCStageField?

    @State private var kind: TCObstacleKind
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

    init(existing: TCObstacle?, unit: TCUnit, onSave: @escaping (TCObstacle) -> Void) {
        self.existing = existing
        self.unit = unit
        self.onSave = onSave
        let base = existing ?? TCObstacle(name: "", kind: .opening)
        _kind = State(initialValue: base.kind)
        _name = State(initialValue: existing?.name ?? "")
        _openWidth = State(initialValue: TCMeasure.text(base.openWidthMM, unit))
        _openHeight = State(initialValue: TCMeasure.text(base.openHeightMM, unit))
        _hinge = State(initialValue: TCMeasure.text(base.hingeGainMM, unit))
        _corridorA = State(initialValue: TCMeasure.text(base.corridorAMM, unit))
        _corridorB = State(initialValue: TCMeasure.text(base.corridorBMM, unit))
        _headroom = State(initialValue: TCMeasure.text(base.headroomMM, unit))
        _cabinW = State(initialValue: TCMeasure.text(base.cabinWidthMM, unit))
        _cabinD = State(initialValue: TCMeasure.text(base.cabinDepthMM, unit))
        _cabinH = State(initialValue: TCMeasure.text(base.cabinHeightMM, unit))
    }

    var body: some View {
        TCScaffold(title: existing == nil ? "New stage" : "Edit stage",
                    subtitle: kind.blurb,
                    showsBack: true) {
            kindPicker
            presetRow
            TCCard {
                TCTextField(title: "Stage name", text: $name, field: TCStageField.name, focus: $focus)
            }
            measurementCard

            if let problem = problem {
                Text(problem)
                    .font(TCType.semibold(13))
                    .foregroundColor(TCPalette.rust)
                    .fixedSize(horizontal: false, vertical: true)
            }

            TCPrimaryButton(title: existing == nil ? "Add this stage" : "Save stage") { save() }
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

    private var kindPicker: some View {
        VStack(alignment: .leading, spacing: 7) {
            TCSectionLabel(text: "What kind of stage")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(TCObstacleKind.allCases, id: \.self) { option in
                        TCChoiceChip(title: option.title,
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
            TCSectionLabel(text: "Start from a typical size")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(TCPresetLibrary.presets(in: presetGroup)) { preset in
                        TCChoiceChip(title: preset.title,
                                      detail: preset.detail,
                                      selected: false) {
                            apply(preset)
                        }
                    }
                }
                .padding(.vertical, 2)
            }
            Text(TCPresetLibrary.disclaimer)
                .font(TCType.body(11))
                .foregroundColor(TCPalette.slate)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var presetGroup: TCPresetGroup {
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
            TCCard {
                Text("The clear opening")
                    .font(TCType.heading(15))
                    .foregroundColor(TCPalette.ink)
                TCDimensionField(title: "Clear width",
                                  hint: "Lining to lining, with the door open.",
                                  text: $openWidth, unitLabel: unit.shortLabel,
                                  field: TCStageField.openWidth, focus: $focus)
                TCDimensionField(title: "Clear height",
                                  hint: "Floor to the underside of the head.",
                                  text: $openHeight, unitLabel: unit.shortLabel,
                                  field: TCStageField.openHeight, focus: $focus)
                TCDimensionField(title: "Gain with the leaf off",
                                  hint: "How much wider it gets with the door lifted off its hinges. Usually 3 to 4 cm.",
                                  text: $hinge, unitLabel: unit.shortLabel,
                                  field: TCStageField.hinge, focus: $focus)
            }
        case .turn:
            TCCard {
                Text("The two corridors")
                    .font(TCType.heading(15))
                    .foregroundColor(TCPalette.ink)
                TCDimensionField(title: "Corridor coming in",
                                  hint: "Wall to wall, where the object arrives.",
                                  text: $corridorA, unitLabel: unit.shortLabel,
                                  field: TCStageField.corridorA, focus: $focus)
                TCDimensionField(title: "Corridor going out",
                                  hint: "Wall to wall, after the turn.",
                                  text: $corridorB, unitLabel: unit.shortLabel,
                                  field: TCStageField.corridorB, focus: $focus)
                TCDimensionField(title: "Headroom",
                                  hint: "Leave at 0 if the ceiling is not a problem here.",
                                  text: $headroom, unitLabel: unit.shortLabel,
                                  field: TCStageField.headroom, focus: $focus)
            }
        case .stair:
            TCCard {
                Text("The landing")
                    .font(TCType.heading(15))
                    .foregroundColor(TCPalette.ink)
                TCDimensionField(title: "Flight width",
                                  hint: "Wall to handrail on the flight itself.",
                                  text: $corridorA, unitLabel: unit.shortLabel,
                                  field: TCStageField.corridorA, focus: $focus)
                TCDimensionField(title: "Landing depth",
                                  hint: "How far the landing runs before the next flight.",
                                  text: $corridorB, unitLabel: unit.shortLabel,
                                  field: TCStageField.corridorB, focus: $focus)
                TCDimensionField(title: "Headroom",
                                  hint: "Landing to the underside of the flight above.",
                                  text: $headroom, unitLabel: unit.shortLabel,
                                  field: TCStageField.headroom, focus: $focus)
            }
        case .elevator:
            TCCard {
                Text("The door")
                    .font(TCType.heading(15))
                    .foregroundColor(TCPalette.ink)
                TCDimensionField(title: "Door width", hint: nil,
                                  text: $openWidth, unitLabel: unit.shortLabel,
                                  field: TCStageField.openWidth, focus: $focus)
                TCDimensionField(title: "Door height", hint: nil,
                                  text: $openHeight, unitLabel: unit.shortLabel,
                                  field: TCStageField.openHeight, focus: $focus)
            }
            TCCard {
                Text("The cabin")
                    .font(TCType.heading(15))
                    .foregroundColor(TCPalette.ink)
                TCDimensionField(title: "Cabin width", hint: nil,
                                  text: $cabinW, unitLabel: unit.shortLabel,
                                  field: TCStageField.cabinW, focus: $focus)
                TCDimensionField(title: "Cabin depth", hint: nil,
                                  text: $cabinD, unitLabel: unit.shortLabel,
                                  field: TCStageField.cabinD, focus: $focus)
                TCDimensionField(title: "Cabin height",
                                  hint: "Floor to ceiling inside the cabin.",
                                  text: $cabinH, unitLabel: unit.shortLabel,
                                  field: TCStageField.cabinH, focus: $focus)
            }
        }
    }

    // MARK: Actions

    private func apply(_ preset: TCPreset) {
        let built = preset.build()
        kind = built.kind
        if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            name = built.name
        }
        openWidth = TCMeasure.text(built.openWidthMM, unit)
        openHeight = TCMeasure.text(built.openHeightMM, unit)
        hinge = TCMeasure.text(built.hingeGainMM, unit)
        corridorA = TCMeasure.text(built.corridorAMM, unit)
        corridorB = TCMeasure.text(built.corridorBMM, unit)
        headroom = TCMeasure.text(built.headroomMM, unit)
        cabinW = TCMeasure.text(built.cabinWidthMM, unit)
        cabinD = TCMeasure.text(built.cabinDepthMM, unit)
        cabinH = TCMeasure.text(built.cabinHeightMM, unit)
        focus = nil
    }

    private func save() {
        var stage = existing ?? TCObstacle(name: "", kind: kind)
        stage.kind = kind

        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        stage.name = trimmed.isEmpty ? kind.title : trimmed

        func value(_ raw: String) -> Double? {
            guard let parsed = TCMeasure.parse(raw), parsed > 0 else { return nil }
            return TCMeasure.toMillimetres(parsed, unit)
        }

        switch kind {
        case .opening, .elevator:
            guard let w = value(openWidth), let h = value(openHeight) else {
                problem = "The opening needs a width and a height greater than zero."
                return
            }
            stage.openWidthMM = w
            stage.openHeightMM = h
            stage.hingeGainMM = TCMeasure.toMillimetres(max(0, TCMeasure.parse(hinge) ?? 0), unit)
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
            let head = max(0, TCMeasure.parse(headroom) ?? 0)
            stage.headroomMM = head > 0 ? TCMeasure.toMillimetres(head, unit) : 0
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
