import SwiftUI

// MARK: - Plan view of a turn

struct WIFTurnDiagram: View {
    let plan: WIFTurnPlan
    let unit: WIFUnit
    let side: CGFloat

    var body: some View {
        Canvas { context, _ in
            draw(in: context)
        }
        .frame(width: side, height: side)
        .background(RoundedRectangle(cornerRadius: 12).fill(WIFPalette.panel))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(WIFPalette.line, lineWidth: 1))
    }

    private func draw(in context: GraphicsContext) {
        let margin: CGFloat = 14
        let t = plan.angleDeg * .pi / 180.0
        let c = cos(t)
        let s = sin(t)
        let boxLength = plan.length
        let boxWidth = plan.width
        let a = plan.corridorA
        let b = plan.corridorB

        let normal = CGPoint(x: s, y: c)
        let e1 = CGPoint(x: boxLength * c, y: 0)
        let e2 = CGPoint(x: 0, y: boxLength * s)
        let corners = [
            e1,
            e2,
            CGPoint(x: e2.x + boxWidth * normal.x, y: e2.y + boxWidth * normal.y),
            CGPoint(x: e1.x + boxWidth * normal.x, y: e1.y + boxWidth * normal.y)
        ]
        let innerCorner = CGPoint(x: b, y: a)

        let boxMaxX = corners.map { $0.x }.max() ?? 0
        let boxMaxY = corners.map { $0.y }.max() ?? 0
        let breathe = max(a, b) * 0.30
        let spanX = max(max(b, boxMaxX), a) + breathe
        let spanY = max(max(a, boxMaxY), b) + breathe
        let span = max(max(spanX, spanY), 1)
        let scale = (side - margin * 2) / CGFloat(span)

        func point(_ p: CGPoint) -> CGPoint {
            CGPoint(x: margin + CGFloat(p.x) * scale,
                    y: side - margin - CGFloat(p.y) * scale)
        }

        // How far the two corridors are drawn before they run off the picture.
        let far = span

        var floor = Path()
        floor.move(to: point(CGPoint(x: 0, y: 0)))
        floor.addLine(to: point(CGPoint(x: far, y: 0)))
        floor.addLine(to: point(CGPoint(x: far, y: a)))
        floor.addLine(to: point(innerCorner))
        floor.addLine(to: point(CGPoint(x: b, y: far)))
        floor.addLine(to: point(CGPoint(x: 0, y: far)))
        floor.closeSubpath()
        context.fill(floor, with: .color(WIFPalette.wash))

        var outer = Path()
        outer.move(to: point(CGPoint(x: 0, y: far)))
        outer.addLine(to: point(CGPoint(x: 0, y: 0)))
        outer.addLine(to: point(CGPoint(x: far, y: 0)))
        context.stroke(outer, with: .color(WIFPalette.ink),
                       style: StrokeStyle(lineWidth: 2.4, lineCap: .square))

        var inner = Path()
        inner.move(to: point(CGPoint(x: far, y: a)))
        inner.addLine(to: point(innerCorner))
        inner.addLine(to: point(CGPoint(x: b, y: far)))
        context.stroke(inner, with: .color(WIFPalette.ink),
                       style: StrokeStyle(lineWidth: 2.4, lineCap: .square))

        var box = Path()
        box.move(to: point(corners[0]))
        for corner in corners.dropFirst() { box.addLine(to: point(corner)) }
        box.closeSubpath()
        context.fill(box, with: .color(WIFPalette.amber.opacity(0.55)))
        context.stroke(box, with: .color(WIFPalette.amberDeep),
                       style: StrokeStyle(lineWidth: 2, lineJoin: .round))

        let clearanceColour = plan.clearanceMM < 0 ? WIFPalette.rust : WIFPalette.teal
        let foot = CGPoint(x: innerCorner.x - plan.clearanceMM * normal.x,
                           y: innerCorner.y - plan.clearanceMM * normal.y)
        var gap = Path()
        gap.move(to: point(innerCorner))
        gap.addLine(to: point(foot))
        context.stroke(gap, with: .color(clearanceColour),
                       style: StrokeStyle(lineWidth: 2, dash: [4, 3]))

        let markerSize: CGFloat = 9
        let markerCentre = point(innerCorner)
        var marker = Path()
        marker.move(to: CGPoint(x: markerCentre.x, y: markerCentre.y - markerSize))
        marker.addLine(to: CGPoint(x: markerCentre.x + markerSize, y: markerCentre.y))
        marker.addLine(to: CGPoint(x: markerCentre.x, y: markerCentre.y + markerSize))
        marker.addLine(to: CGPoint(x: markerCentre.x - markerSize, y: markerCentre.y))
        marker.closeSubpath()
        context.fill(marker, with: .color(clearanceColour))
        context.stroke(marker, with: .color(WIFPalette.panel), style: StrokeStyle(lineWidth: 1.5))

        context.draw(Text(WIFMeasure.label(a, unit))
                        .font(WIFType.caption(10))
                        .foregroundColor(WIFPalette.slate),
                     at: CGPoint(x: side - margin - 4, y: point(CGPoint(x: 0, y: a / 2)).y),
                     anchor: .trailing)
        context.draw(Text(WIFMeasure.label(b, unit))
                        .font(WIFType.caption(10))
                        .foregroundColor(WIFPalette.slate),
                     at: CGPoint(x: point(CGPoint(x: b / 2, y: 0)).x, y: margin + 4),
                     anchor: .top)

        let anchorPoint = point(CGPoint(x: (corners[0].x + corners[2].x) / 2,
                                        y: (corners[0].y + corners[2].y) / 2))
        context.draw(Text(WIFMeasure.angleText(plan.angleDeg))
                        .font(WIFType.caption(11))
                        .foregroundColor(WIFPalette.ink),
                     at: CGPoint(x: min(max(anchorPoint.x, margin + 26), side - margin - 26),
                                 y: min(max(anchorPoint.y, margin + 12), side - margin - 12)),
                     anchor: .center)
    }
}

// MARK: - Head-on view of an opening

struct WIFOpeningDiagram: View {
    let plan: WIFOpeningPlan
    let unit: WIFUnit
    let side: CGFloat

    private var boardHeight: CGFloat { side * 0.82 }

    var body: some View {
        Canvas { context, _ in
            draw(in: context)
        }
        .frame(width: side, height: boardHeight)
        .background(RoundedRectangle(cornerRadius: 12).fill(WIFPalette.panel))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(WIFPalette.line, lineWidth: 1))
    }

    private func draw(in context: GraphicsContext) {
        let boardH = boardHeight
        let margin: CGFloat = 20
        let t = plan.angleDeg * .pi / 180.0
        let c = cos(t)
        let s = sin(t)
        let needWidth = plan.sideAcross * c + plan.sideUp * s
        let needHeight = plan.sideAcross * s + plan.sideUp * c

        let spanX = max(plan.openWidth, needWidth) * 1.20
        let spanY = max(plan.openHeight, needHeight) * 1.14
        let scaleX = (side - margin * 2) / CGFloat(max(spanX, 1))
        let scaleY = (boardH - margin * 2) / CGFloat(max(spanY, 1))
        let scale = min(scaleX, scaleY)

        let centre = CGPoint(x: side / 2, y: boardH / 2)

        func centredRect(_ width: Double, _ height: Double) -> Path {
            let w = CGFloat(width) * scale
            let h = CGFloat(height) * scale
            return Path(CGRect(x: centre.x - w / 2, y: centre.y - h / 2, width: w, height: h))
        }

        let openingRect = centredRect(plan.openWidth, plan.openHeight)
        var surround = Path(CGRect(x: 0, y: 0, width: side, height: boardH))
        surround.addPath(openingRect)
        context.fill(surround, with: .color(WIFPalette.wash), style: FillStyle(eoFill: true))
        context.stroke(openingRect, with: .color(WIFPalette.ink), style: StrokeStyle(lineWidth: 2.6))

        let halfAcross = CGFloat(plan.sideAcross) * scale / 2
        let halfUp = CGFloat(plan.sideUp) * scale / 2
        let raw = [CGPoint(x: -halfAcross, y: -halfUp), CGPoint(x: halfAcross, y: -halfUp),
                   CGPoint(x: halfAcross, y: halfUp), CGPoint(x: -halfAcross, y: halfUp)]
        let turned = raw.map { p -> CGPoint in
            CGPoint(x: centre.x + p.x * CGFloat(c) - p.y * CGFloat(s),
                    y: centre.y + p.x * CGFloat(s) + p.y * CGFloat(c))
        }
        var object = Path()
        object.move(to: turned[0])
        for p in turned.dropFirst() { object.addLine(to: p) }
        object.closeSubpath()
        context.fill(object, with: .color(WIFPalette.amber.opacity(0.55)))
        context.stroke(object, with: .color(WIFPalette.amberDeep),
                       style: StrokeStyle(lineWidth: 2, lineJoin: .round))

        let tightOnWidth = plan.slackWidth <= plan.slackHeight
        let needColour = min(plan.slackWidth, plan.slackHeight) < 0 ? WIFPalette.rust : WIFPalette.teal
        let needed = centredRect(needWidth, needHeight)
        context.stroke(needed, with: .color(needColour), style: StrokeStyle(lineWidth: 1.6, dash: [5, 4]))

        let markerSize: CGFloat = 8
        let markerCentre = tightOnWidth
            ? CGPoint(x: centre.x + CGFloat(needWidth) * scale / 2, y: centre.y)
            : CGPoint(x: centre.x, y: centre.y - CGFloat(needHeight) * scale / 2)
        var marker = Path()
        marker.move(to: CGPoint(x: markerCentre.x, y: markerCentre.y - markerSize))
        marker.addLine(to: CGPoint(x: markerCentre.x + markerSize, y: markerCentre.y))
        marker.addLine(to: CGPoint(x: markerCentre.x, y: markerCentre.y + markerSize))
        marker.addLine(to: CGPoint(x: markerCentre.x - markerSize, y: markerCentre.y))
        marker.closeSubpath()
        context.fill(marker, with: .color(needColour))

        context.draw(Text(WIFMeasure.label(plan.openWidth, unit))
                        .font(WIFType.caption(10))
                        .foregroundColor(WIFPalette.slate),
                     at: CGPoint(x: centre.x,
                                 y: max(9, centre.y - CGFloat(plan.openHeight) * scale / 2 - 9)),
                     anchor: .center)
        context.draw(Text(WIFMeasure.label(plan.openHeight, unit))
                        .font(WIFType.caption(10))
                        .foregroundColor(WIFPalette.slate),
                     at: CGPoint(x: max(26, centre.x - CGFloat(plan.openWidth) * scale / 2 - 6),
                                 y: centre.y),
                     anchor: .trailing)
        if plan.angleDeg > 0.01 && plan.angleDeg < 89.99 {
            context.draw(Text(WIFMeasure.angleText(plan.angleDeg))
                            .font(WIFType.caption(11))
                            .foregroundColor(WIFPalette.ink),
                         at: CGPoint(x: centre.x, y: boardH - 11),
                         anchor: .center)
        }
    }
}

// MARK: - Legend

struct WIFLegendEntry: Identifiable {
    let colour: Color
    let text: String
    // Stable across redraws: a fresh UUID each pass would make SwiftUI rebuild the whole legend
    // every time the parent re-evaluates.
    var id: String { text }
}

struct WIFDiagramLegend: View {
    let entries: [WIFLegendEntry]

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            ForEach(entries) { entry in
                HStack(spacing: 7) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(entry.colour)
                        .frame(width: 14, height: 4)
                    Text(entry.text)
                        .font(WIFType.body(11))
                        .foregroundColor(WIFPalette.slate)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }
}
