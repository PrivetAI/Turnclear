import SwiftUI

/// The main screen: one object, one ordered route, a verdict for every stage and a clear mark on
/// the stage that is tightest.
struct TCCheckView: View {
    @EnvironmentObject private var store: TCStore

    var body: some View {
        TCScaffold(title: "Turnclear",
                    subtitle: "One object, one route, a verdict per stage") {
            itemPicker
            routePicker
            resultSection
            adjustmentsCard
            TCNoticeBox(text: "Clearances are worked out from the numbers you enter. "
                         + "Measure the real opening between the frame linings, not the door leaf.")
        }
    }

    // MARK: Pickers

    private var itemPicker: some View {
        VStack(alignment: .leading, spacing: 7) {
            TCSectionLabel(text: "Object")
            if store.items.isEmpty {
                TCEmptyState(title: "No objects yet",
                              message: "Add the sofa, fridge or desk you are thinking of buying on the Items tab, then come back here.")
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(store.items) { item in
                            TCChoiceChip(title: item.name,
                                          detail: TCMeasure.triple(item.widthMM, item.heightMM,
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
            TCSectionLabel(text: "Route")
            if store.routes.isEmpty {
                TCEmptyState(title: "No routes yet",
                              message: "A route is the ordered list of things the object has to get past: front door, hallway turn, lift, flat door. Build one on the Routes tab.")
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(store.routes) { route in
                            TCChoiceChip(title: route.name,
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
                TCEmptyState(title: "This route has no stages",
                              message: "Open the route on the Routes tab and add the doors, turns and lifts the object has to get past.")
            } else {
                // Worked out once per pass and handed to both halves, rather than twice.
                resolved(item: item, route: route, result: store.result(for: item, route: route))
            }
        } else {
            EmptyView()
        }
    }

    private func resolved(item: TCItem, route: TCRoute, result: TCCheckResult) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            summaryCard(item: item, result: result)
            stageList(route: route, item: item, result: result)
        }
    }

    private func summaryCard(item: TCItem, result: TCCheckResult) -> some View {
        TCCard(tint: TCVerdictStyle.background(result.verdict),
                border: TCVerdictStyle.foreground(result.verdict).opacity(0.4)) {
            HStack(alignment: .top, spacing: 10) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(overallHeadline(result))
                        .font(TCType.display(19))
                        .foregroundColor(TCVerdictStyle.foreground(result.verdict))
                        .fixedSize(horizontal: false, vertical: true)
                    Text(item.name)
                        .font(TCType.body(12))
                        .foregroundColor(TCPalette.slate)
                }
                Spacer(minLength: 6)
                TCVerdictChip(verdict: result.verdict, compact: true)
            }

            TCHairline()

            TCKeyValue(key: "Size used",
                        value: TCMeasure.triple(result.effectiveWidth, result.effectiveHeight,
                                                 result.effectiveDepth, store.unit))
            if result.effectiveWeight > 0 {
                TCKeyValue(key: "Weight to carry",
                            value: TCMeasure.weightText(result.effectiveWeight))
            }
            if let tight = result.tightestStage {
                TCKeyValue(key: "Tightest stage",
                            value: tight.name + "  " + TCMeasure.signedLabel(tight.marginMM, store.unit),
                            valueColor: TCVerdictStyle.foreground(tight.verdict))
            }
            ForEach(0..<result.adjustmentNotes.count, id: \.self) { index in
                Text(result.adjustmentNotes[index])
                    .font(TCType.body(11))
                    .foregroundColor(TCPalette.slate)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func overallHeadline(_ result: TCCheckResult) -> String {
        switch result.verdict {
        case .clear: return "It goes in."
        case .rotated: return "It goes in, but it has to be turned."
        case .blocked: return "It will not get in on this route."
        }
    }

    private func stageList(route: TCRoute, item: TCItem, result: TCCheckResult) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            TCSectionLabel(text: "Stages in order")
            VStack(spacing: 8) {
                ForEach(Array(result.stages.enumerated()), id: \.element.id) { pair in
                    NavigationLink(destination: TCStageDetailView(outcome: pair.element,
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

    private func obstacle(for outcome: TCStageOutcome, in route: TCRoute) -> TCObstacle {
        route.stops.first(where: { $0.id == outcome.id })
            ?? TCObstacle(name: outcome.name, kind: outcome.kind)
    }

    private func stageRow(index: Int, outcome: TCStageOutcome, tightest: Bool) -> some View {
        HStack(alignment: .top, spacing: 11) {
            VStack(spacing: 5) {
                Text("\(index)")
                    .font(TCType.figure(12))
                    .foregroundColor(TCPalette.slate)
                TCKindIcon(kind: outcome.kind, size: 22, color: TCPalette.ink)
            }
            .frame(width: 30)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 7) {
                    Text(outcome.name)
                        .font(TCType.semibold(15))
                        .foregroundColor(TCPalette.ink)
                        .lineLimit(1)
                    if tightest {
                        Text("TIGHTEST")
                            .font(TCType.caption(9))
                            .tracking(0.8)
                            .foregroundColor(TCPalette.amberDeep)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(TCPalette.amberSoft))
                    }
                }
                Text(outcome.headline)
                    .font(TCType.body(12))
                    .foregroundColor(TCPalette.slate)
                    .fixedSize(horizontal: false, vertical: true)
                    .multilineTextAlignment(.leading)
            }

            Spacer(minLength: 4)

            VStack(alignment: .trailing, spacing: 5) {
                TCVerdictChip(verdict: outcome.verdict, compact: true)
                Text(TCMeasure.signedLabel(outcome.marginMM, store.unit))
                    .font(TCType.figure(12))
                    .foregroundColor(TCVerdictStyle.foreground(outcome.verdict))
                TCIcon(glyph: TCChevronGlyph(), size: 14, color: TCPalette.slate, weight: 2)
                    .rotationEffect(.degrees(90))
            }
        }
        .padding(TCMetric.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: TCMetric.corner).fill(TCPalette.panel))
        .overlay(RoundedRectangle(cornerRadius: TCMetric.corner)
                    .stroke(tightest ? TCPalette.amber : TCPalette.line,
                            lineWidth: tightest ? 2 : 1))
    }

    // MARK: Adjustments

    private var adjustmentsCard: some View {
        TCCard {
            Text("What if")
                .font(TCType.heading(16))
                .foregroundColor(TCPalette.ink)
            Text("Each switch re-runs every stage straight away.")
                .font(TCType.body(11))
                .foregroundColor(TCPalette.slate)

            TCSwitchRow(title: "Take the legs off",
                         detail: "Uses the leg height saved with the object.",
                         isOn: binding(\.removeLegs))
            TCHairline()
            TCSwitchRow(title: "Lift door leaves off their hinges",
                         detail: "Adds each opening's own hinge gain to its width.",
                         isOn: binding(\.liftDoorOffHinges))
            TCHairline()
            TCSwitchRow(title: "Unwrap the packaging",
                         detail: "Takes the packing thickness off every dimension.",
                         isOn: binding(\.removePackaging))
            TCHairline()
            TCSwitchRow(title: "Pull out drawers and shelves",
                         detail: "Weight only. The outside size does not change.",
                         isOn: binding(\.removeDrawers))
            TCHairline()
            TCSwitchRow(title: "Tilting allowed",
                         detail: "Off means the object stays on its feet and may only be turned on the spot.",
                         isOn: binding(\.allowTilt))
        }
    }

    private func binding(_ path: WritableKeyPath<TCAdjustments, Bool>) -> Binding<Bool> {
        Binding(get: { store.adjustments[keyPath: path] },
                set: { newValue in
                    var next = store.adjustments
                    next[keyPath: path] = newValue
                    store.setAdjustments(next)
                })
    }
}
