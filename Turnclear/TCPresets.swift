import Foundation

/// A typical set of measurements the user can drop into a route instead of typing.
/// These are common building sizes, not a guarantee about any particular building — every
/// screen that shows them repeats that they still have to be checked with a tape measure.
struct TCPreset: Identifiable {
    let id: String
    let title: String
    let detail: String
    let group: TCPresetGroup
    let build: () -> TCObstacle
}

enum TCPresetGroup: String, CaseIterable, Identifiable {
    case doors
    case lifts
    case turns
    case stairs

    var id: String { rawValue }

    var title: String {
        switch self {
        case .doors: return "Doors and openings"
        case .lifts: return "Lift cabins"
        case .turns: return "Corridor turns"
        case .stairs: return "Stairwells"
        }
    }

    var blurb: String {
        switch self {
        case .doors: return "Clear opening between the frame linings — not the leaf, and not the outside of the frame."
        case .lifts: return "Cabin inside faces plus the clear door opening."
        case .turns: return "The two corridor widths that meet at the corner, wall to wall."
        case .stairs: return "Flight width, landing depth and the headroom under the flight above."
        }
    }
}

enum TCPresetLibrary {
    static let disclaimer = "Presets are typical values, not measurements of your building. "
        + "Check every number with a tape measure before you buy."

    static let all: [TCPreset] = [
        // Doors
        TCPreset(id: "door-interior-60", title: "Interior door, narrow",
                  detail: "60 x 200 cm clear opening", group: .doors) {
            TCObstacle(name: "Interior door", kind: .opening,
                        openWidthMM: 600, openHeightMM: 2000, hingeGainMM: 35)
        },
        TCPreset(id: "door-interior-70", title: "Interior door, standard",
                  detail: "70 x 200 cm clear opening", group: .doors) {
            TCObstacle(name: "Interior door", kind: .opening,
                        openWidthMM: 700, openHeightMM: 2000, hingeGainMM: 35)
        },
        TCPreset(id: "door-interior-80", title: "Interior door, wide",
                  detail: "80 x 200 cm clear opening", group: .doors) {
            TCObstacle(name: "Interior door", kind: .opening,
                        openWidthMM: 800, openHeightMM: 2000, hingeGainMM: 35)
        },
        TCPreset(id: "door-entrance-90", title: "Flat entrance door",
                  detail: "90 x 205 cm clear opening, heavier leaf", group: .doors) {
            TCObstacle(name: "Flat door", kind: .opening,
                        openWidthMM: 900, openHeightMM: 2050, hingeGainMM: 45)
        },
        TCPreset(id: "door-building-100", title: "Building entrance",
                  detail: "100 x 210 cm clear opening", group: .doors) {
            TCObstacle(name: "Building entrance", kind: .opening,
                        openWidthMM: 1000, openHeightMM: 2100, hingeGainMM: 40)
        },
        TCPreset(id: "door-balcony", title: "Balcony door",
                  detail: "70 x 210 cm, glazed leaf", group: .doors) {
            TCObstacle(name: "Balcony door", kind: .opening,
                        openWidthMM: 700, openHeightMM: 2100, hingeGainMM: 30)
        },

        // Lifts
        TCPreset(id: "lift-small", title: "Small passenger lift",
                  detail: "Cabin 100 x 125 x 210 cm, door 70 x 200 cm", group: .lifts) {
            TCObstacle(name: "Lift", kind: .elevator,
                        openWidthMM: 700, openHeightMM: 2000, hingeGainMM: 0,
                        cabinWidthMM: 1000, cabinDepthMM: 1250, cabinHeightMM: 2100)
        },
        TCPreset(id: "lift-standard", title: "Standard passenger lift",
                  detail: "Cabin 110 x 140 x 220 cm, door 80 x 200 cm", group: .lifts) {
            TCObstacle(name: "Lift", kind: .elevator,
                        openWidthMM: 800, openHeightMM: 2000, hingeGainMM: 0,
                        cabinWidthMM: 1100, cabinDepthMM: 1400, cabinHeightMM: 2200)
        },
        TCPreset(id: "lift-large", title: "Large passenger lift",
                  detail: "Cabin 160 x 140 x 220 cm, door 110 x 210 cm", group: .lifts) {
            TCObstacle(name: "Lift", kind: .elevator,
                        openWidthMM: 1600, openHeightMM: 2100, hingeGainMM: 0,
                        cabinWidthMM: 1600, cabinDepthMM: 1400, cabinHeightMM: 2200)
        },
        TCPreset(id: "lift-goods", title: "Goods lift",
                  detail: "Cabin 150 x 250 x 230 cm, door 130 x 210 cm", group: .lifts) {
            TCObstacle(name: "Goods lift", kind: .elevator,
                        openWidthMM: 1300, openHeightMM: 2100, hingeGainMM: 0,
                        cabinWidthMM: 1500, cabinDepthMM: 2500, cabinHeightMM: 2300)
        },
        TCPreset(id: "lift-stretcher", title: "Stretcher lift",
                  detail: "Cabin 110 x 210 x 220 cm, door 90 x 210 cm", group: .lifts) {
            TCObstacle(name: "Stretcher lift", kind: .elevator,
                        openWidthMM: 900, openHeightMM: 2100, hingeGainMM: 0,
                        cabinWidthMM: 1100, cabinDepthMM: 2100, cabinHeightMM: 2200)
        },

        // Turns
        TCPreset(id: "turn-narrow", title: "Narrow hallway turn",
                  detail: "90 x 90 cm corridors", group: .turns) {
            TCObstacle(name: "Hallway turn", kind: .turn,
                        corridorAMM: 900, corridorBMM: 900, headroomMM: 0)
        },
        TCPreset(id: "turn-standard", title: "Standard hallway turn",
                  detail: "110 x 110 cm corridors", group: .turns) {
            TCObstacle(name: "Hallway turn", kind: .turn,
                        corridorAMM: 1100, corridorBMM: 1100, headroomMM: 0)
        },
        TCPreset(id: "turn-wide", title: "Wide corridor turn",
                  detail: "140 x 120 cm corridors", group: .turns) {
            TCObstacle(name: "Corridor turn", kind: .turn,
                        corridorAMM: 1400, corridorBMM: 1200, headroomMM: 0)
        },
        TCPreset(id: "turn-low", title: "Turn under a low ceiling",
                  detail: "100 x 100 cm corridors, 210 cm headroom", group: .turns) {
            TCObstacle(name: "Low turn", kind: .turn,
                        corridorAMM: 1000, corridorBMM: 1000, headroomMM: 2100)
        },

        // Stairs
        TCPreset(id: "stair-narrow", title: "Narrow stair landing",
                  detail: "90 cm flight, 100 cm landing, 200 cm headroom", group: .stairs) {
            TCObstacle(name: "Stair landing", kind: .stair,
                        corridorAMM: 900, corridorBMM: 1000, headroomMM: 2000)
        },
        TCPreset(id: "stair-standard", title: "Standard stair landing",
                  detail: "105 cm flight, 120 cm landing, 210 cm headroom", group: .stairs) {
            TCObstacle(name: "Stair landing", kind: .stair,
                        corridorAMM: 1050, corridorBMM: 1200, headroomMM: 2100)
        },
        TCPreset(id: "stair-wide", title: "Wide stair landing",
                  detail: "120 cm flight, 140 cm landing, 220 cm headroom", group: .stairs) {
            TCObstacle(name: "Stair landing", kind: .stair,
                        corridorAMM: 1200, corridorBMM: 1400, headroomMM: 2200)
        },
        TCPreset(id: "stair-spiral-quarter", title: "Quarter-turn stair",
                  detail: "95 cm flight, 95 cm landing, 195 cm headroom", group: .stairs) {
            TCObstacle(name: "Quarter-turn stair", kind: .stair,
                        corridorAMM: 950, corridorBMM: 950, headroomMM: 1950)
        }
    ]

    static func presets(in group: TCPresetGroup) -> [TCPreset] {
        all.filter { $0.group == group }
    }
}
