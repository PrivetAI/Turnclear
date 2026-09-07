import Foundation
import SwiftUI

/// The whole saved state, as one JSON blob in UserDefaults. Every field is optional on the way
/// in so a payload written by an older build can never throw and wipe the library.
private struct TCSaveFile: Codable {
    var items: [TCItem]
    var routes: [TCRoute]
    var unit: TCUnit
    var adjustments: TCAdjustments
    var selectedItemID: UUID?
    var selectedRouteID: UUID?
    var hasSeeded: Bool

    init(items: [TCItem],
         routes: [TCRoute],
         unit: TCUnit,
         adjustments: TCAdjustments,
         selectedItemID: UUID?,
         selectedRouteID: UUID?,
         hasSeeded: Bool) {
        self.items = items
        self.routes = routes
        self.unit = unit
        self.adjustments = adjustments
        self.selectedItemID = selectedItemID
        self.selectedRouteID = selectedRouteID
        self.hasSeeded = hasSeeded
    }

    init(from decoder: Decoder) throws {
        let box = try decoder.container(keyedBy: CodingKeys.self)
        items = (try? box.decodeIfPresent([TCItem].self, forKey: .items)) ?? []
        routes = (try? box.decodeIfPresent([TCRoute].self, forKey: .routes)) ?? []
        unit = (try? box.decodeIfPresent(TCUnit.self, forKey: .unit)) ?? .centimetres
        adjustments = (try? box.decodeIfPresent(TCAdjustments.self, forKey: .adjustments)) ?? TCAdjustments()
        selectedItemID = (try? box.decodeIfPresent(UUID.self, forKey: .selectedItemID)) ?? nil
        selectedRouteID = (try? box.decodeIfPresent(UUID.self, forKey: .selectedRouteID)) ?? nil
        hasSeeded = (try? box.decodeIfPresent(Bool.self, forKey: .hasSeeded)) ?? false
    }
}

final class TCStore: ObservableObject {
    private static let storageKey = "turnclear.library.v1"

    @Published var items: [TCItem] = []
    @Published var routes: [TCRoute] = []
    @Published var unit: TCUnit = .centimetres
    @Published var adjustments = TCAdjustments()
    @Published var selectedItemID: UUID?
    @Published var selectedRouteID: UUID?

    private var hasSeeded = false
    /// Set while the first load is running so nothing writes back over the payload mid-restore.
    private var loading = false

    init() {
        load()
    }

    // MARK: Derived

    var selectedItem: TCItem? {
        guard let id = selectedItemID else { return items.first }
        return items.first(where: { $0.id == id }) ?? items.first
    }

    var selectedRoute: TCRoute? {
        guard let id = selectedRouteID else { return routes.first }
        return routes.first(where: { $0.id == id }) ?? routes.first
    }

    var currentResult: TCCheckResult? {
        guard let item = selectedItem, let route = selectedRoute, !route.stops.isEmpty else { return nil }
        return TCEngine.run(item: item, route: route, adjust: adjustments, unit: unit)
    }

    func result(for item: TCItem, route: TCRoute) -> TCCheckResult {
        TCEngine.run(item: item, route: route, adjust: adjustments, unit: unit)
    }

    // MARK: Items

    func upsert(item: TCItem) {
        if let index = items.firstIndex(where: { $0.id == item.id }) {
            items[index] = item
        } else {
            items.append(item)
        }
        selectedItemID = item.id
        save()
    }

    func deleteItem(_ id: UUID) {
        items.removeAll(where: { $0.id == id })
        if selectedItemID == id { selectedItemID = items.first?.id }
        save()
    }

    func duplicateItem(_ id: UUID) {
        guard let source = items.first(where: { $0.id == id }) else { return }
        var copy = source
        copy.id = UUID()
        copy.name = source.name + " copy"
        items.append(copy)
        save()
    }

    // MARK: Routes

    func upsert(route: TCRoute) {
        if let index = routes.firstIndex(where: { $0.id == route.id }) {
            routes[index] = route
        } else {
            routes.append(route)
        }
        selectedRouteID = route.id
        save()
    }

    func deleteRoute(_ id: UUID) {
        routes.removeAll(where: { $0.id == id })
        if selectedRouteID == id { selectedRouteID = routes.first?.id }
        save()
    }

    func append(obstacle: TCObstacle, toRouteID routeID: UUID) {
        guard let index = routes.firstIndex(where: { $0.id == routeID }) else { return }
        var stage = obstacle
        stage.id = UUID()
        routes[index].stops.append(stage)
        save()
    }

    func replace(obstacle: TCObstacle, inRouteID routeID: UUID) {
        guard let routeIndex = routes.firstIndex(where: { $0.id == routeID }) else { return }
        guard let stopIndex = routes[routeIndex].stops.firstIndex(where: { $0.id == obstacle.id }) else {
            routes[routeIndex].stops.append(obstacle)
            save()
            return
        }
        routes[routeIndex].stops[stopIndex] = obstacle
        save()
    }

    func removeObstacle(_ obstacleID: UUID, fromRouteID routeID: UUID) {
        guard let index = routes.firstIndex(where: { $0.id == routeID }) else { return }
        routes[index].stops.removeAll(where: { $0.id == obstacleID })
        save()
    }

    func moveObstacle(_ obstacleID: UUID, inRouteID routeID: UUID, by offset: Int) {
        guard let routeIndex = routes.firstIndex(where: { $0.id == routeID }) else { return }
        guard let from = routes[routeIndex].stops.firstIndex(where: { $0.id == obstacleID }) else { return }
        let to = from + offset
        guard to >= 0 && to < routes[routeIndex].stops.count else { return }
        let stage = routes[routeIndex].stops.remove(at: from)
        routes[routeIndex].stops.insert(stage, at: to)
        save()
    }

    // MARK: Settings

    func setUnit(_ newUnit: TCUnit) {
        guard newUnit != unit else { return }
        unit = newUnit
        save()
    }

    func setAdjustments(_ newValue: TCAdjustments) {
        adjustments = newValue
        save()
    }

    func selectItem(_ id: UUID) {
        selectedItemID = id
        save()
    }

    func selectRoute(_ id: UUID) {
        selectedRouteID = id
        save()
    }

    func resetEverything() {
        items = []
        routes = []
        adjustments = TCAdjustments()
        selectedItemID = nil
        selectedRouteID = nil
        hasSeeded = false
        seedIfNeeded()
        save()
    }

    // MARK: Persistence

    func save() {
        guard !loading else { return }
        let payload = TCSaveFile(items: items,
                                  routes: routes,
                                  unit: unit,
                                  adjustments: adjustments,
                                  selectedItemID: selectedItemID,
                                  selectedRouteID: selectedRouteID,
                                  hasSeeded: hasSeeded)
        guard let data = try? JSONEncoder().encode(payload) else { return }
        UserDefaults.standard.set(data, forKey: TCStore.storageKey)
    }

    private func load() {
        loading = true
        if let data = UserDefaults.standard.data(forKey: TCStore.storageKey),
           let payload = try? JSONDecoder().decode(TCSaveFile.self, from: data) {
            items = payload.items
            routes = payload.routes
            unit = payload.unit
            adjustments = payload.adjustments
            selectedItemID = payload.selectedItemID
            selectedRouteID = payload.selectedRouteID
            hasSeeded = payload.hasSeeded
        }
        loading = false

        // Write the seed out straight away, so the examples cannot reappear on a later launch
        // after somebody has deliberately deleted them.
        let seeding = !hasSeeded
        seedIfNeeded()
        if seeding { save() }
    }

    /// First launch gets one worked example, so the check screen has something to show and the
    /// shape of a route is obvious without reading anything.
    private func seedIfNeeded() {
        guard !hasSeeded else { return }
        hasSeeded = true

        let sofa = TCItem(name: "Three-seat sofa",
                           widthMM: 2100,
                           heightMM: 880,
                           depthMM: 950,
                           legHeightMM: 120,
                           packagingMM: 60,
                           weightKG: 62,
                           removableWeightKG: 9,
                           note: "Measured over the arms, back cushions in place.")
        let fridge = TCItem(name: "Tall fridge freezer",
                             widthMM: 600,
                             heightMM: 1850,
                             depthMM: 660,
                             legHeightMM: 20,
                             packagingMM: 45,
                             weightKG: 74,
                             removableWeightKG: 6,
                             note: "Depth includes the door handle.")

        let route = TCRoute(name: "Street to living room", stops: [
            TCObstacle(name: "Building entrance", kind: .opening,
                        openWidthMM: 1000, openHeightMM: 2100, hingeGainMM: 40),
            TCObstacle(name: "Ground floor turn", kind: .turn,
                        corridorAMM: 1400, corridorBMM: 1150, headroomMM: 0),
            TCObstacle(name: "Lift", kind: .elevator,
                        openWidthMM: 900, openHeightMM: 2000, hingeGainMM: 0,
                        cabinWidthMM: 1100, cabinDepthMM: 1400, cabinHeightMM: 2200),
            TCObstacle(name: "Flat door", kind: .opening,
                        openWidthMM: 900, openHeightMM: 2050, hingeGainMM: 45),
            TCObstacle(name: "Hallway turn", kind: .turn,
                        corridorAMM: 1100, corridorBMM: 950, headroomMM: 0),
            TCObstacle(name: "Living room door", kind: .opening,
                        openWidthMM: 850, openHeightMM: 2000, hingeGainMM: 35)
        ])

        let stairRoute = TCRoute(name: "Back stairs, no lift", stops: [
            TCObstacle(name: "Back entrance", kind: .opening,
                        openWidthMM: 900, openHeightMM: 2000, hingeGainMM: 40),
            TCObstacle(name: "First landing", kind: .stair,
                        corridorAMM: 1050, corridorBMM: 1200, headroomMM: 2150),
            TCObstacle(name: "Second landing", kind: .stair,
                        corridorAMM: 1050, corridorBMM: 1100, headroomMM: 2050),
            TCObstacle(name: "Flat door", kind: .opening,
                        openWidthMM: 850, openHeightMM: 2000, hingeGainMM: 40)
        ])

        if items.isEmpty { items = [sofa, fridge] }
        if routes.isEmpty { routes = [route, stairRoute] }
        if selectedItemID == nil { selectedItemID = items.first?.id }
        if selectedRouteID == nil { selectedRouteID = routes.first?.id }
    }
}
