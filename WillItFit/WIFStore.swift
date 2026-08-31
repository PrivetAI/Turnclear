import Foundation
import SwiftUI

/// The whole saved state, as one JSON blob in UserDefaults. Every field is optional on the way
/// in so a payload written by an older build can never throw and wipe the library.
private struct WIFSaveFile: Codable {
    var items: [WIFItem]
    var routes: [WIFRoute]
    var unit: WIFUnit
    var adjustments: WIFAdjustments
    var selectedItemID: UUID?
    var selectedRouteID: UUID?
    var hasSeeded: Bool

    init(items: [WIFItem],
         routes: [WIFRoute],
         unit: WIFUnit,
         adjustments: WIFAdjustments,
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
        items = (try? box.decodeIfPresent([WIFItem].self, forKey: .items)) ?? []
        routes = (try? box.decodeIfPresent([WIFRoute].self, forKey: .routes)) ?? []
        unit = (try? box.decodeIfPresent(WIFUnit.self, forKey: .unit)) ?? .centimetres
        adjustments = (try? box.decodeIfPresent(WIFAdjustments.self, forKey: .adjustments)) ?? WIFAdjustments()
        selectedItemID = (try? box.decodeIfPresent(UUID.self, forKey: .selectedItemID)) ?? nil
        selectedRouteID = (try? box.decodeIfPresent(UUID.self, forKey: .selectedRouteID)) ?? nil
        hasSeeded = (try? box.decodeIfPresent(Bool.self, forKey: .hasSeeded)) ?? false
    }
}

final class WIFStore: ObservableObject {
    private static let storageKey = "willitfit.library.v1"

    @Published var items: [WIFItem] = []
    @Published var routes: [WIFRoute] = []
    @Published var unit: WIFUnit = .centimetres
    @Published var adjustments = WIFAdjustments()
    @Published var selectedItemID: UUID?
    @Published var selectedRouteID: UUID?

    private var hasSeeded = false
    /// Set while the first load is running so nothing writes back over the payload mid-restore.
    private var loading = false

    init() {
        load()
    }

    // MARK: Derived

    var selectedItem: WIFItem? {
        guard let id = selectedItemID else { return items.first }
        return items.first(where: { $0.id == id }) ?? items.first
    }

    var selectedRoute: WIFRoute? {
        guard let id = selectedRouteID else { return routes.first }
        return routes.first(where: { $0.id == id }) ?? routes.first
    }

    var currentResult: WIFCheckResult? {
        guard let item = selectedItem, let route = selectedRoute, !route.stops.isEmpty else { return nil }
        return WIFEngine.run(item: item, route: route, adjust: adjustments, unit: unit)
    }

    func result(for item: WIFItem, route: WIFRoute) -> WIFCheckResult {
        WIFEngine.run(item: item, route: route, adjust: adjustments, unit: unit)
    }

    // MARK: Items

    func upsert(item: WIFItem) {
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

    func upsert(route: WIFRoute) {
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

    func append(obstacle: WIFObstacle, toRouteID routeID: UUID) {
        guard let index = routes.firstIndex(where: { $0.id == routeID }) else { return }
        var stage = obstacle
        stage.id = UUID()
        routes[index].stops.append(stage)
        save()
    }

    func replace(obstacle: WIFObstacle, inRouteID routeID: UUID) {
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

    func setUnit(_ newUnit: WIFUnit) {
        guard newUnit != unit else { return }
        unit = newUnit
        save()
    }

    func setAdjustments(_ newValue: WIFAdjustments) {
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
        adjustments = WIFAdjustments()
        selectedItemID = nil
        selectedRouteID = nil
        hasSeeded = false
        seedIfNeeded()
        save()
    }

    // MARK: Persistence

    func save() {
        guard !loading else { return }
        let payload = WIFSaveFile(items: items,
                                  routes: routes,
                                  unit: unit,
                                  adjustments: adjustments,
                                  selectedItemID: selectedItemID,
                                  selectedRouteID: selectedRouteID,
                                  hasSeeded: hasSeeded)
        guard let data = try? JSONEncoder().encode(payload) else { return }
        UserDefaults.standard.set(data, forKey: WIFStore.storageKey)
    }

    private func load() {
        loading = true
        if let data = UserDefaults.standard.data(forKey: WIFStore.storageKey),
           let payload = try? JSONDecoder().decode(WIFSaveFile.self, from: data) {
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

        let sofa = WIFItem(name: "Three-seat sofa",
                           widthMM: 2100,
                           heightMM: 880,
                           depthMM: 950,
                           legHeightMM: 120,
                           packagingMM: 60,
                           weightKG: 62,
                           removableWeightKG: 9,
                           note: "Measured over the arms, back cushions in place.")
        let fridge = WIFItem(name: "Tall fridge freezer",
                             widthMM: 600,
                             heightMM: 1850,
                             depthMM: 660,
                             legHeightMM: 20,
                             packagingMM: 45,
                             weightKG: 74,
                             removableWeightKG: 6,
                             note: "Depth includes the door handle.")

        let route = WIFRoute(name: "Street to living room", stops: [
            WIFObstacle(name: "Building entrance", kind: .opening,
                        openWidthMM: 1000, openHeightMM: 2100, hingeGainMM: 40),
            WIFObstacle(name: "Ground floor turn", kind: .turn,
                        corridorAMM: 1400, corridorBMM: 1150, headroomMM: 0),
            WIFObstacle(name: "Lift", kind: .elevator,
                        openWidthMM: 900, openHeightMM: 2000, hingeGainMM: 0,
                        cabinWidthMM: 1100, cabinDepthMM: 1400, cabinHeightMM: 2200),
            WIFObstacle(name: "Flat door", kind: .opening,
                        openWidthMM: 900, openHeightMM: 2050, hingeGainMM: 45),
            WIFObstacle(name: "Hallway turn", kind: .turn,
                        corridorAMM: 1100, corridorBMM: 950, headroomMM: 0),
            WIFObstacle(name: "Living room door", kind: .opening,
                        openWidthMM: 850, openHeightMM: 2000, hingeGainMM: 35)
        ])

        let stairRoute = WIFRoute(name: "Back stairs, no lift", stops: [
            WIFObstacle(name: "Back entrance", kind: .opening,
                        openWidthMM: 900, openHeightMM: 2000, hingeGainMM: 40),
            WIFObstacle(name: "First landing", kind: .stair,
                        corridorAMM: 1050, corridorBMM: 1200, headroomMM: 2150),
            WIFObstacle(name: "Second landing", kind: .stair,
                        corridorAMM: 1050, corridorBMM: 1100, headroomMM: 2050),
            WIFObstacle(name: "Flat door", kind: .opening,
                        openWidthMM: 850, openHeightMM: 2000, hingeGainMM: 40)
        ])

        if items.isEmpty { items = [sofa, fridge] }
        if routes.isEmpty { routes = [route, stairRoute] }
        if selectedItemID == nil { selectedItemID = items.first?.id }
        if selectedRouteID == nil { selectedRouteID = routes.first?.id }
    }
}
