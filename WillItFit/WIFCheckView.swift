import SwiftUI

/// The main screen: one object, one ordered route, a verdict for every stage and a clear mark on
/// the stage that is tightest.
struct WIFCheckView: View {
    @EnvironmentObject private var store: WIFStore

    var body: some View {
        WIFScaffold(title: "Will It Fit",
                    subtitle: "One object, one route, a verdict per stage") {
            itemPicker
            routePicker
            resultSection
            adjustmentsCard
            WIFNoticeBox(text: "Clearances are worked out from the numbers you enter. "
                         + "Measure the real opening between the frame linings, not the door leaf.")
        }
    }

    // MARK: Pickers

    private var itemPicker: some View {
        VStack(alignment: .leading, spacing: 7) {
            WIFSectionLabel(text: "Object")
            if store.items.isEmpty {
                WIFEmptyState(title: "No objects yet",
                              message: "Add the sofa, fridge or desk you are thinking of buying on the Items tab, then come back here.")
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(store.items) { item in
                            WIFChoiceChip(title: item.name,
                                          detail: WIFMeasure.triple(item.widthMM, item.heightMM,
                                                                    item.depthMM, store.unit),
                                          selected: store.selectedItem?.id == item.id) {
                                store.selectItem(item.id)
                            }
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        }
    }

    private var routePicker: some View {
        VStack(alignment: .leading, spacing: 7) {
            WIFSectionLabel(text: "Route")
            if store.routes.isEmpty {
                WIFEmptyState(title: "No routes yet",
                              message: "A route is the ordered list of things the object has to get past: front door, hallway turn, lift, flat door. Build one on the Routes tab.")
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(store.routes) { route in
                            WIFChoiceChip(title: route.name,
                                          detail: route.stops.count == 1
                                              ? "1 stage" : "\(route.stops.count) stages",
                                          selected: store.selectedRoute?.id == route.id) {
                                store.selectRoute(route.id)
                            }
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        }
    }

    // MARK: Result

    @ViewBuilder
    private var resultSection: some View {
        if let item = store.selectedItem, let route = store.selectedRoute {
            if route.stops.isEmpty {
                WIFEmptyState(title: "This route has no stages",
                              message: "Open the route on the Routes tab and add the doors, turns and lifts the object has to get past.")
            } else {
                // Worked out once per pass and handed to both halves, rather than twice.
                resolved(item: item, route: route, result: store.result(for: item, route: route))
            }
        } else {
            EmptyView()
        }
    }

    private func resolved(item: WIFItem, route: WIFRoute, result: WIFCheckResult) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            summaryCard(item: item, result: result)
            stageList(route: route, item: item, result: result)
        }
    }

    private func summaryCard(item: WIFItem, result: WIFCheckResult) -> some View {
        WIFCard(tint: WIFVerdictStyle.background(result.verdict),
                border: WIFVerdictStyle.foreground(result.verdict).opacity(0.4)) {
            HStack(alignment: .top, spacing: 10) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(overallHeadline(result))
                        .font(WIFType.display(19))
                        .foregroundColor(WIFVerdictStyle.foreground(result.verdict))
                        .fixedSize(horizontal: false, vertical: true)
                    Text(item.name)
                        .font(WIFType.body(12))
                        .foregroundColor(WIFPalette.slate)
                }
                Spacer(minLength: 6)
                WIFVerdictChip(verdict: result.verdict, compact: true)
            }

            WIFHairline()

            WIFKeyValue(key: "Size used",
                        value: WIFMeasure.triple(result.effectiveWidth, result.effectiveHeight,
                                                 result.effectiveDepth, store.unit))
            if result.effectiveWeight > 0 {
                WIFKeyValue(key: "Weight to carry",
                            value: WIFMeasure.weightText(result.effectiveWeight))
            }
            if let tight = result.tightestStage {
                WIFKeyValue(key: "Tightest stage",
                            value: tight.name + "  " + WIFMeasure.signedLabel(tight.marginMM, store.unit),
                            valueColor: WIFVerdictStyle.foreground(tight.verdict))
            }
            ForEach(0..<result.adjustmentNotes.count, id: \.self) { index in
                Text(result.adjustmentNotes[index])
                    .font(WIFType.body(11))
                    .foregroundColor(WIFPalette.slate)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func overallHeadline(_ result: WIFCheckResult) -> String {
        switch result.verdict {
        case .clear: return "It goes in."
        case .rotated: return "It goes in, but it has to be turned."
        case .blocked: return "It will not get in on this route."
        }
    }

    private func stageList(route: WIFRoute, item: WIFItem, result: WIFCheckResult) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            WIFSectionLabel(text: "Stages in order")
            VStack(spacing: 8) {
                ForEach(Array(result.stages.enumerated()), id: \.element.id) { pair in
                    NavigationLink(destination: WIFStageDetailView(outcome: pair.element,
                                                                   obstacle: obstacle(for: pair.element,
                                                                                      in: route),
                                                                   itemName: item.name,
                                                                   position: pair.offset + 1)
                                        .environmentObject(store)) {
                        stageRow(index: pair.offset + 1,
                                 outcome: pair.element,
                                 tightest: pair.element.id == result.tightestStageID)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }

    private func obstacle(for outcome: WIFStageOutcome, in route: WIFRoute) -> WIFObstacle {
        route.stops.first(where: { $0.id == outcome.id })
            ?? WIFObstacle(name: outcome.name, kind: outcome.kind)
    }

    private func stageRow(index: Int, outcome: WIFStageOutcome, tightest: Bool) -> some View {
        HStack(alignment: .top, spacing: 11) {
            VStack(spacing: 5) {
                Text("\(index)")
                    .font(WIFType.figure(12))
                    .foregroundColor(WIFPalette.slate)
                WIFKindIcon(kind: outcome.kind, size: 22, color: WIFPalette.ink)
            }
            .frame(width: 30)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 7) {
                    Text(outcome.name)
                        .font(WIFType.semibold(15))
                        .foregroundColor(WIFPalette.ink)
                        .lineLimit(1)
                    if tightest {
                        Text("TIGHTEST")
                            .font(WIFType.caption(9))
                            .tracking(0.8)
                            .foregroundColor(WIFPalette.amberDeep)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(WIFPalette.amberSoft))
                    }
                }
                Text(outcome.headline)
                    .font(WIFType.body(12))
                    .foregroundColor(WIFPalette.slate)
                    .fixedSize(horizontal: false, vertical: true)
                    .multilineTextAlignment(.leading)
            }

            Spacer(minLength: 4)

            VStack(alignment: .trailing, spacing: 5) {
                WIFVerdictChip(verdict: outcome.verdict, compact: true)
                Text(WIFMeasure.signedLabel(outcome.marginMM, store.unit))
                    .font(WIFType.figure(12))
                    .foregroundColor(WIFVerdictStyle.foreground(outcome.verdict))
                WIFIcon(glyph: WIFChevronGlyph(), size: 14, color: WIFPalette.slate, weight: 2)
                    .rotationEffect(.degrees(90))
            }
        }
        .padding(WIFMetric.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: WIFMetric.corner).fill(WIFPalette.panel))
        .overlay(RoundedRectangle(cornerRadius: WIFMetric.corner)
                    .stroke(tightest ? WIFPalette.amber : WIFPalette.line,
                            lineWidth: tightest ? 2 : 1))
    }

    // MARK: Adjustments

    private var adjustmentsCard: some View {
        WIFCard {
            Text("What if")
                .font(WIFType.heading(16))
                .foregroundColor(WIFPalette.ink)
            Text("Each switch re-runs every stage straight away.")
                .font(WIFType.body(11))
                .foregroundColor(WIFPalette.slate)

            WIFSwitchRow(title: "Take the legs off",
                         detail: "Uses the leg height saved with the object.",
                         isOn: binding(\.removeLegs))
            WIFHairline()
            WIFSwitchRow(title: "Lift door leaves off their hinges",
                         detail: "Adds each opening's own hinge gain to its width.",
                         isOn: binding(\.liftDoorOffHinges))
            WIFHairline()
            WIFSwitchRow(title: "Unwrap the packaging",
                         detail: "Takes the packing thickness off every dimension.",
                         isOn: binding(\.removePackaging))
            WIFHairline()
            WIFSwitchRow(title: "Pull out drawers and shelves",
                         detail: "Weight only. The outside size does not change.",
                         isOn: binding(\.removeDrawers))
            WIFHairline()
            WIFSwitchRow(title: "Tilting allowed",
                         detail: "Off means the object stays on its feet and may only be turned on the spot.",
                         isOn: binding(\.allowTilt))
        }
    }

    private func binding(_ path: WritableKeyPath<WIFAdjustments, Bool>) -> Binding<Bool> {
        Binding(get: { store.adjustments[keyPath: path] },
                set: { newValue in
                    var next = store.adjustments
                    next[keyPath: path] = newValue
                    store.setAdjustments(next)
                })
    }
}
