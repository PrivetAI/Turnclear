import SwiftUI

/// Preference used to read the real content width of a card, so a fixed-size drawing inside it
/// never has to guess how many nested paddings sit between it and the screen edge.
struct TCWidthKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

struct TCStageDetailView: View {
    let outcome: TCStageOutcome
    let obstacle: TCObstacle
    let itemName: String
    let position: Int

    @EnvironmentObject private var store: TCStore
    @State private var boardWidth: CGFloat = 0

    private var side: CGFloat {
        let fallback = min(UIScreen.main.bounds.width, TCMetric.contentMaxWidth)
            - TCMetric.screenPadding * 2 - TCMetric.cardPadding * 2
        let measured = boardWidth > 1 ? boardWidth : fallback
        return max(180, min(measured, 380))
    }

    var body: some View {
        TCScaffold(title: outcome.name,
                    subtitle: "Stage \(position) — " + itemName,
                    showsBack: true) {
            verdictCard
            diagramCard
            explanationCard
            numbersCard
        }
    }

    private var verdictCard: some View {
        TCCard(tint: TCVerdictStyle.background(outcome.verdict),
                border: TCVerdictStyle.foreground(outcome.verdict).opacity(0.4)) {
            HStack(alignment: .top, spacing: 10) {
                Text(outcome.headline)
                    .font(TCType.heading(16))
                    .foregroundColor(TCVerdictStyle.foreground(outcome.verdict))
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 6)
                TCVerdictChip(verdict: outcome.verdict, compact: true)
            }
            TCHairline()
            TCKeyValue(key: "Room at the tightest point",
                        value: TCMeasure.signedLabel(outcome.marginMM, store.unit),
                        valueColor: TCVerdictStyle.foreground(outcome.verdict))
            TCKeyValue(key: "What runs out first", value: outcome.binding)
            if let angle = outcome.angleDeg, angle > 0.01, angle < 89.99 {
                TCKeyValue(key: outcome.kind == .turn || outcome.kind == .stair
                                ? "Worst angle in the turn" : "Angle it must be held at",
                            value: TCMeasure.angleText(angle))
            }
            TCKeyValue(key: "How to carry it", value: outcome.poseLabel)
        }
    }

    @ViewBuilder
    private var diagramCard: some View {
        if let drawing = outcome.drawing {
            TCCard {
                Text(drawingTitle)
                    .font(TCType.heading(15))
                    .foregroundColor(TCPalette.ink)

                HStack {
                    Spacer(minLength: 0)
                    switch drawing {
                    case .turn(let plan):
                        TCTurnDiagram(plan: plan, unit: store.unit, side: side)
                    case .opening(let plan):
                        TCOpeningDiagram(plan: plan, unit: store.unit, side: side)
                    }
                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity)
                .background(
                    GeometryReader { geo in
                        Color.clear.preference(key: TCWidthKey.self, value: geo.size.width)
                    }
                )

                TCDiagramLegend(entries: legendEntries)
            }
            .onPreferenceChange(TCWidthKey.self) { width in
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

    private var legendEntries: [TCLegendEntry] {
        switch outcome.kind {
        case .turn, .stair:
            return [
                TCLegendEntry(colour: TCPalette.amberDeep,
                               text: "The object, drawn at the angle where the corner is tightest."),
                TCLegendEntry(colour: TCVerdictStyle.foreground(outcome.verdict),
                               text: outcome.marginMM < 0
                                   ? "The marked corner is inside the object — that is the jam."
                                   : "Gap between the object and the inner corner at that moment."),
                TCLegendEntry(colour: TCPalette.ink,
                               text: "Corridor walls. The corner is where the two meet.")
            ]
        default:
            return [
                TCLegendEntry(colour: TCPalette.amberDeep,
                               text: "The face of the object presented to the opening."),
                TCLegendEntry(colour: TCVerdictStyle.foreground(outcome.verdict),
                               text: "Dashed: the space that face actually needs once it is turned."),
                TCLegendEntry(colour: TCPalette.ink, text: "The clear opening.")
            ]
        }
    }

    private var explanationCard: some View {
        TCCard {
            Text("Working")
                .font(TCType.heading(15))
                .foregroundColor(TCPalette.ink)
            ForEach(0..<outcome.notes.count, id: \.self) { index in
                HStack(alignment: .top, spacing: 8) {
                    TCIcon(glyph: TCDiamondGlyph(), size: 7,
                            color: TCPalette.amber, weight: 1, filled: true)
                        .padding(.top, 5)
                    Text(outcome.notes[index])
                        .font(TCType.body(12.5))
                        .foregroundColor(TCPalette.inkSoft)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private var numbersCard: some View {
        TCCard {
            Text("Measurements for this stage")
                .font(TCType.heading(15))
                .foregroundColor(TCPalette.ink)
            switch obstacle.kind {
            case .opening:
                TCKeyValue(key: "Clear width", value: TCMeasure.label(obstacle.openWidthMM, store.unit))
                TCKeyValue(key: "Clear height", value: TCMeasure.label(obstacle.openHeightMM, store.unit))
                TCKeyValue(key: "Gain with the leaf off",
                            value: TCMeasure.label(obstacle.hingeGainMM, store.unit))
            case .turn:
                TCKeyValue(key: "Corridor in", value: TCMeasure.label(obstacle.corridorAMM, store.unit))
                TCKeyValue(key: "Corridor out", value: TCMeasure.label(obstacle.corridorBMM, store.unit))
                TCKeyValue(key: "Headroom",
                            value: obstacle.headroomMM > 0
                                ? TCMeasure.label(obstacle.headroomMM, store.unit) : "not limited")
            case .stair:
                TCKeyValue(key: "Flight width", value: TCMeasure.label(obstacle.corridorAMM, store.unit))
                TCKeyValue(key: "Landing depth", value: TCMeasure.label(obstacle.corridorBMM, store.unit))
                TCKeyValue(key: "Headroom under the flight above",
                            value: obstacle.headroomMM > 0
                                ? TCMeasure.label(obstacle.headroomMM, store.unit) : "not limited")
            case .elevator:
                TCKeyValue(key: "Door width", value: TCMeasure.label(obstacle.openWidthMM, store.unit))
                TCKeyValue(key: "Door height", value: TCMeasure.label(obstacle.openHeightMM, store.unit))
                TCKeyValue(key: "Cabin width", value: TCMeasure.label(obstacle.cabinWidthMM, store.unit))
                TCKeyValue(key: "Cabin depth", value: TCMeasure.label(obstacle.cabinDepthMM, store.unit))
                TCKeyValue(key: "Cabin height", value: TCMeasure.label(obstacle.cabinHeightMM, store.unit))
            }
        }
    }
}
