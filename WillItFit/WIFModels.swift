import Foundation

// MARK: - Item

/// A rigid object the user wants to move. All dimensions in millimetres.
struct WIFItem: Identifiable, Codable, Equatable {
    var id: UUID
    var name: String
    /// Side to side, as the object normally stands.
    var widthMM: Double
    /// Floor to top, as the object normally stands.
    var heightMM: Double
    /// Front to back.
    var depthMM: Double
    /// How much of the height is legs that unscrew.
    var legHeightMM: Double
    /// How much the packaging adds to every dimension.
    var packagingMM: Double
    var weightKG: Double
    /// Weight of drawers / shelves / cushions that come out before the carry.
    var removableWeightKG: Double
    var note: String

    init(id: UUID = UUID(),
         name: String,
         widthMM: Double,
         heightMM: Double,
         depthMM: Double,
         legHeightMM: Double = 0,
         packagingMM: Double = 0,
         weightKG: Double = 0,
         removableWeightKG: Double = 0,
         note: String = "") {
        self.id = id
        self.name = name
        self.widthMM = widthMM
        self.heightMM = heightMM
        self.depthMM = depthMM
        self.legHeightMM = legHeightMM
        self.packagingMM = packagingMM
        self.weightKG = weightKG
        self.removableWeightKG = removableWeightKG
        self.note = note
    }

    // Hand-written so that a field added in a later version cannot throw while decoding an
    // older saved payload. A synthesised decoder would fail on the first missing key and the
    // whole library would silently come back empty.
    init(from decoder: Decoder) throws {
        let box = try decoder.container(keyedBy: CodingKeys.self)
        id = (try? box.decodeIfPresent(UUID.self, forKey: .id)) ?? UUID()
        name = (try? box.decodeIfPresent(String.self, forKey: .name)) ?? "Item"
        widthMM = (try? box.decodeIfPresent(Double.self, forKey: .widthMM)) ?? 600
        heightMM = (try? box.decodeIfPresent(Double.self, forKey: .heightMM)) ?? 600
        depthMM = (try? box.decodeIfPresent(Double.self, forKey: .depthMM)) ?? 600
        legHeightMM = (try? box.decodeIfPresent(Double.self, forKey: .legHeightMM)) ?? 0
        packagingMM = (try? box.decodeIfPresent(Double.self, forKey: .packagingMM)) ?? 0
        weightKG = (try? box.decodeIfPresent(Double.self, forKey: .weightKG)) ?? 0
        removableWeightKG = (try? box.decodeIfPresent(Double.self, forKey: .removableWeightKG)) ?? 0
        note = (try? box.decodeIfPresent(String.self, forKey: .note)) ?? ""
    }

    var sortedDimensions: [Double] { [widthMM, heightMM, depthMM].sorted() }
    var longestSideMM: Double { sortedDimensions[2] }
    var carryWeightKG: Double { max(0, weightKG) }
}

// MARK: - Obstacle

enum WIFObstacleKind: String, Codable, CaseIterable {
    case opening
    case turn
    case stair
    case elevator

    var title: String {
        switch self {
        case .opening: return "Opening"
        case .turn: return "Corridor turn"
        case .stair: return "Stairwell turn"
        case .elevator: return "Lift"
        }
    }

    var shortTitle: String {
        switch self {
        case .opening: return "Opening"
        case .turn: return "Turn"
        case .stair: return "Stairs"
        case .elevator: return "Lift"
        }
    }

    var blurb: String {
        switch self {
        case .opening:
            return "A doorway, hatch or gate the object is carried straight through."
        case .turn:
            return "A right-angle turn between two corridors."
        case .stair:
            return "A turn on a stair landing, with the flight above limiting the headroom."
        case .elevator:
            return "A lift: the object has to pass the door and then stand inside the cabin."
        }
    }
}

/// One stage of a route. Every kind keeps its own set of fields; the unused ones simply stay
/// at their defaults so an obstacle can be switched from one kind to another without loss.
struct WIFObstacle: Identifiable, Codable, Equatable {
    var id: UUID
    var name: String
    var kind: WIFObstacleKind

    // Opening (also the lift door).
    var openWidthMM: Double
    var openHeightMM: Double
    /// Width gained by lifting the leaf off its hinges — usually the leaf thickness plus the
    /// stop, 30-40 mm on a typical interior door.
    var hingeGainMM: Double

    // Turn / stair: the two corridor widths meeting at the corner.
    var corridorAMM: Double
    var corridorBMM: Double
    /// Ceiling or the underside of the flight above. 0 means "not limited".
    var headroomMM: Double

    // Lift cabin.
    var cabinWidthMM: Double
    var cabinDepthMM: Double
    var cabinHeightMM: Double

    init(id: UUID = UUID(),
         name: String,
         kind: WIFObstacleKind,
         openWidthMM: Double = 800,
         openHeightMM: Double = 2000,
         hingeGainMM: Double = 35,
         corridorAMM: Double = 1100,
         corridorBMM: Double = 1100,
         headroomMM: Double = 0,
         cabinWidthMM: Double = 1100,
         cabinDepthMM: Double = 1400,
         cabinHeightMM: Double = 2100) {
        self.id = id
        self.name = name
        self.kind = kind
        self.openWidthMM = openWidthMM
        self.openHeightMM = openHeightMM
        self.hingeGainMM = hingeGainMM
        self.corridorAMM = corridorAMM
        self.corridorBMM = corridorBMM
        self.headroomMM = headroomMM
        self.cabinWidthMM = cabinWidthMM
        self.cabinDepthMM = cabinDepthMM
        self.cabinHeightMM = cabinHeightMM
    }

    init(from decoder: Decoder) throws {
        let box = try decoder.container(keyedBy: CodingKeys.self)
        id = (try? box.decodeIfPresent(UUID.self, forKey: .id)) ?? UUID()
        name = (try? box.decodeIfPresent(String.self, forKey: .name)) ?? "Stage"
        kind = (try? box.decodeIfPresent(WIFObstacleKind.self, forKey: .kind)) ?? .opening
        openWidthMM = (try? box.decodeIfPresent(Double.self, forKey: .openWidthMM)) ?? 800
        openHeightMM = (try? box.decodeIfPresent(Double.self, forKey: .openHeightMM)) ?? 2000
        hingeGainMM = (try? box.decodeIfPresent(Double.self, forKey: .hingeGainMM)) ?? 35
        corridorAMM = (try? box.decodeIfPresent(Double.self, forKey: .corridorAMM)) ?? 1100
        corridorBMM = (try? box.decodeIfPresent(Double.self, forKey: .corridorBMM)) ?? 1100
        headroomMM = (try? box.decodeIfPresent(Double.self, forKey: .headroomMM)) ?? 0
        cabinWidthMM = (try? box.decodeIfPresent(Double.self, forKey: .cabinWidthMM)) ?? 1100
        cabinDepthMM = (try? box.decodeIfPresent(Double.self, forKey: .cabinDepthMM)) ?? 1400
        cabinHeightMM = (try? box.decodeIfPresent(Double.self, forKey: .cabinHeightMM)) ?? 2100
    }

    /// One-line summary of the numbers that actually matter for this kind.
    func summary(_ unit: WIFUnit) -> String {
        switch kind {
        case .opening:
            return "Opening " + WIFMeasure.pair(openWidthMM, openHeightMM, unit)
        case .turn:
            let base = "Corridors " + WIFMeasure.pair(corridorAMM, corridorBMM, unit)
            return headroomMM > 0 ? base + ", headroom " + WIFMeasure.label(headroomMM, unit) : base
        case .stair:
            return "Flight " + WIFMeasure.text(corridorAMM, unit)
                + ", landing " + WIFMeasure.text(corridorBMM, unit)
                + ", headroom " + WIFMeasure.label(headroomMM, unit)
        case .elevator:
            return "Cabin " + WIFMeasure.triple(cabinWidthMM, cabinDepthMM, cabinHeightMM, unit)
                + ", door " + WIFMeasure.pair(openWidthMM, openHeightMM, unit)
        }
    }
}

// MARK: - Route

/// An ordered list of obstacles — the whole point of the app. A single doorway verdict is a
/// calculator; a route is the answer to "will it get into my flat".
struct WIFRoute: Identifiable, Codable, Equatable {
    var id: UUID
    var name: String
    var stops: [WIFObstacle]

    init(id: UUID = UUID(), name: String, stops: [WIFObstacle]) {
        self.id = id
        self.name = name
        self.stops = stops
    }

    init(from decoder: Decoder) throws {
        let box = try decoder.container(keyedBy: CodingKeys.self)
        id = (try? box.decodeIfPresent(UUID.self, forKey: .id)) ?? UUID()
        name = (try? box.decodeIfPresent(String.self, forKey: .name)) ?? "Route"
        stops = (try? box.decodeIfPresent([WIFObstacle].self, forKey: .stops)) ?? []
    }
}

// MARK: - Adjustments

/// The live "what if" panel. Every flag re-runs the geometry, none of them edits the saved item.
struct WIFAdjustments: Codable, Equatable {
    var removeLegs: Bool
    var liftDoorOffHinges: Bool
    var removePackaging: Bool
    var removeDrawers: Bool
    var allowTilt: Bool

    init(removeLegs: Bool = false,
         liftDoorOffHinges: Bool = false,
         removePackaging: Bool = false,
         removeDrawers: Bool = false,
         allowTilt: Bool = true) {
        self.removeLegs = removeLegs
        self.liftDoorOffHinges = liftDoorOffHinges
        self.removePackaging = removePackaging
        self.removeDrawers = removeDrawers
        self.allowTilt = allowTilt
    }

    init(from decoder: Decoder) throws {
        let box = try decoder.container(keyedBy: CodingKeys.self)
        removeLegs = (try? box.decodeIfPresent(Bool.self, forKey: .removeLegs)) ?? false
        liftDoorOffHinges = (try? box.decodeIfPresent(Bool.self, forKey: .liftDoorOffHinges)) ?? false
        removePackaging = (try? box.decodeIfPresent(Bool.self, forKey: .removePackaging)) ?? false
        removeDrawers = (try? box.decodeIfPresent(Bool.self, forKey: .removeDrawers)) ?? false
        allowTilt = (try? box.decodeIfPresent(Bool.self, forKey: .allowTilt)) ?? true
    }

    static let untouched = WIFAdjustments()
}
