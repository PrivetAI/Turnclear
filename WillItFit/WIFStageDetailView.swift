import SwiftUI

/// Preference used to read the real content width of a card, so a fixed-size drawing inside it
/// never has to guess how many nested paddings sit between it and the screen edge.
struct WIFWidthKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

struct WIFStageDetailView: View {
    let outcome: WIFStageOutcome
    let obstacle: WIFObstacle
    let itemName: String
    let position: Int

    @EnvironmentObject private var store: WIFStore
    @State private var boardWidth: CGFloat = 0

    private var side: CGFloat {
        let fallback = min(UIScreen.main.bounds.width, WIFMetric.contentMaxWidth)
            - WIFMetric.screenPadding * 2 - WIFMetric.cardPadding * 2
        let measured = boardWidth > 1 ? boardWidth : fallback
        return max(180, min(measured, 380))
    }

    var body: some View {
        WIFScaffold(title: outcome.name,
                    subtitle: "Stage \(position) — " + itemName,
                    showsBack: true) {
            verdictCard
            diagramCard
            explanationCard
            numbersCard
        }
    }

    private var verdictCard: some View {
        WIFCard(tint: WIFVerdictStyle.background(outcome.verdict),
                border: WIFVerdictStyle.foreground(outcome.verdict).opacity(0.4)) {
            HStack(alignment: .top, spacing: 10) {
                Text(outcome.headline)
                    .font(WIFType.heading(16))
                    .foregroundColor(WIFVerdictStyle.foreground(outcome.verdict))
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 6)
                WIFVerdictChip(verdict: outcome.verdict, compact: true)
            }
            WIFHairline()
            WIFKeyValue(key: "Room at the tightest point",
                        value: WIFMeasure.signedLabel(outcome.marginMM, store.unit),
                        valueColor: WIFVerdictStyle.foreground(outcome.verdict))
            WIFKeyValue(key: "What runs out first", value: outcome.binding)
            if let angle = outcome.angleDeg, angle > 0.01, angle < 89.99 {
                WIFKeyValue(key: outcome.kind == .turn || outcome.kind == .stair
                                ? "Worst angle in the turn" : "Angle it must be held at",
                            value: WIFMeasure.angleText(angle))
            }
            WIFKeyValue(key: "How to carry it", value: outcome.poseLabel)
        }
    }

    @ViewBuilder
    private var diagramCard: some View {
        if let drawing = outcome.drawing {
            WIFCard {
                Text(drawingTitle)
                    .font(WIFType.heading(15))
                    .foregroundColor(WIFPalette.ink)

                HStack {
                    Spacer(minLength: 0)
                    switch drawing {
                    case .turn(let plan):
                        WIFTurnDiagram(plan: plan, unit: store.unit, side: side)
                    case .opening(let plan):
                        WIFOpeningDiagram(plan: plan, unit: store.unit, side: side)
                    }
                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity)
                .background(
                    GeometryReader { geo in
                        Color.clear.preference(key: WIFWidthKey.self, value: geo.size.width)
                    }
                )

                WIFDiagramLegend(entries: legendEntries)
            }
            .onPreferenceChange(WIFWidthKey.self) { width in
                boardWidth = width
            }
        }
    }

    private var drawingTitle: String {
        switch outcome.kind {
        case .turn, .stair: return "Seen from above, at the worst angle"
        case .opening: return "Seen head on, at the angle it has to be held"
        case .elevator: return "The lift door, seen head on"
        }
    }

    private var legendEntries: [WIFLegendEntry] {
        switch outcome.kind {
        case .turn, .stair:
            return [
                WIFLegendEntry(colour: WIFPalette.amberDeep,
                               text: "The object, drawn at the angle where the corner is tightest."),
                WIFLegendEntry(colour: WIFVerdictStyle.foreground(outcome.verdict),
                               text: outcome.marginMM < 0
                                   ? "The marked corner is inside the object — that is the jam."
                                   : "Gap between the object and the inner corner at that moment."),
                WIFLegendEntry(colour: WIFPalette.ink,
                               text: "Corridor walls. The corner is where the two meet.")
            ]
        default:
            return [
                WIFLegendEntry(colour: WIFPalette.amberDeep,
                               text: "The face of the object presented to the opening."),
                WIFLegendEntry(colour: WIFVerdictStyle.foreground(outcome.verdict),
                               text: "Dashed: the space that face actually needs once it is turned."),
                WIFLegendEntry(colour: WIFPalette.ink, text: "The clear opening.")
            ]
        }
    }

    private var explanationCard: some View {
        WIFCard {
            Text("Working")
                .font(WIFType.heading(15))
                .foregroundColor(WIFPalette.ink)
            ForEach(0..<outcome.notes.count, id: \.self) { index in
                HStack(alignment: .top, spacing: 8) {
                    WIFIcon(glyph: WIFDiamondGlyph(), size: 7,
                            color: WIFPalette.amber, weight: 1, filled: true)
                        .padding(.top, 5)
                    Text(outcome.notes[index])
                        .font(WIFType.body(12.5))
                        .foregroundColor(WIFPalette.inkSoft)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private var numbersCard: some View {
        WIFCard {
            Text("Measurements for this stage")
                .font(WIFType.heading(15))
                .foregroundColor(WIFPalette.ink)
            switch obstacle.kind {
            case .opening:
                WIFKeyValue(key: "Clear width", value: WIFMeasure.label(obstacle.openWidthMM, store.unit))
                WIFKeyValue(key: "Clear height", value: WIFMeasure.label(obstacle.openHeightMM, store.unit))
                WIFKeyValue(key: "Gain with the leaf off",
                            value: WIFMeasure.label(obstacle.hingeGainMM, store.unit))
            case .turn:
                WIFKeyValue(key: "Corridor in", value: WIFMeasure.label(obstacle.corridorAMM, store.unit))
                WIFKeyValue(key: "Corridor out", value: WIFMeasure.label(obstacle.corridorBMM, store.unit))
                WIFKeyValue(key: "Headroom",
                            value: obstacle.headroomMM > 0
                                ? WIFMeasure.label(obstacle.headroomMM, store.unit) : "not limited")
            case .stair:
                WIFKeyValue(key: "Flight width", value: WIFMeasure.label(obstacle.corridorAMM, store.unit))
                WIFKeyValue(key: "Landing depth", value: WIFMeasure.label(obstacle.corridorBMM, store.unit))
                WIFKeyValue(key: "Headroom under the flight above",
                            value: obstacle.headroomMM > 0
                                ? WIFMeasure.label(obstacle.headroomMM, store.unit) : "not limited")
            case .elevator:
                WIFKeyValue(key: "Door width", value: WIFMeasure.label(obstacle.openWidthMM, store.unit))
                WIFKeyValue(key: "Door height", value: WIFMeasure.label(obstacle.openHeightMM, store.unit))
                WIFKeyValue(key: "Cabin width", value: WIFMeasure.label(obstacle.cabinWidthMM, store.unit))
                WIFKeyValue(key: "Cabin depth", value: WIFMeasure.label(obstacle.cabinDepthMM, store.unit))
                WIFKeyValue(key: "Cabin height", value: WIFMeasure.label(obstacle.cabinHeightMM, store.unit))
            }
        }
    }
}
