import SwiftUI

// Every icon in the app is drawn here from a Path. Nothing comes from the system icon set and
// no glyph font is used, so the look is identical on every device and every iOS version.

struct WIFDoorGlyph: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width, h = rect.height
        let frame = CGRect(x: rect.minX + w * 0.16, y: rect.minY + h * 0.08,
                           width: w * 0.68, height: h * 0.84)
        p.addRect(frame)
        // The leaf, swung open a little.
        p.move(to: CGPoint(x: frame.minX + frame.width * 0.14, y: frame.minY + frame.height * 0.06))
        p.addLine(to: CGPoint(x: frame.minX + frame.width * 0.14, y: frame.maxY))
        p.move(to: CGPoint(x: frame.minX + frame.width * 0.14, y: frame.minY + frame.height * 0.06))
        p.addLine(to: CGPoint(x: frame.maxX - frame.width * 0.10, y: frame.minY + frame.height * 0.20))
        p.addLine(to: CGPoint(x: frame.maxX - frame.width * 0.10, y: frame.maxY))
        return p
    }
}

struct WIFTurnGlyph: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width, h = rect.height
        // An L-shaped run with an arrow head at the top.
        p.move(to: CGPoint(x: rect.minX + w * 0.10, y: rect.maxY - h * 0.16))
        p.addLine(to: CGPoint(x: rect.minX + w * 0.62, y: rect.maxY - h * 0.16))
        p.addLine(to: CGPoint(x: rect.minX + w * 0.62, y: rect.minY + h * 0.28))
        p.move(to: CGPoint(x: rect.minX + w * 0.40, y: rect.minY + h * 0.46))
        p.addLine(to: CGPoint(x: rect.minX + w * 0.62, y: rect.minY + h * 0.18))
        p.addLine(to: CGPoint(x: rect.minX + w * 0.84, y: rect.minY + h * 0.46))
        return p
    }
}

struct WIFStairGlyph: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width, h = rect.height
        let steps = 3
        var x = rect.minX + w * 0.10
        var y = rect.maxY - h * 0.14
        p.move(to: CGPoint(x: x, y: y))
        for _ in 0..<steps {
            y -= h * 0.24
            p.addLine(to: CGPoint(x: x, y: y))
            x += w * 0.26
            p.addLine(to: CGPoint(x: x, y: y))
        }
        return p
    }
}

struct WIFLiftGlyph: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width, h = rect.height
        let cab = CGRect(x: rect.minX + w * 0.14, y: rect.minY + h * 0.10,
                         width: w * 0.72, height: h * 0.80)
        p.addRect(cab)
        p.move(to: CGPoint(x: cab.midX, y: cab.minY + cab.height * 0.06))
        p.addLine(to: CGPoint(x: cab.midX, y: cab.maxY - cab.height * 0.06))
        // Up and down markers inside the cabin.
        p.move(to: CGPoint(x: cab.minX + cab.width * 0.14, y: cab.minY + cab.height * 0.40))
        p.addLine(to: CGPoint(x: cab.minX + cab.width * 0.26, y: cab.minY + cab.height * 0.24))
        p.addLine(to: CGPoint(x: cab.minX + cab.width * 0.38, y: cab.minY + cab.height * 0.40))
        p.move(to: CGPoint(x: cab.maxX - cab.width * 0.38, y: cab.maxY - cab.height * 0.40))
        p.addLine(to: CGPoint(x: cab.maxX - cab.width * 0.26, y: cab.maxY - cab.height * 0.24))
        p.addLine(to: CGPoint(x: cab.maxX - cab.width * 0.14, y: cab.maxY - cab.height * 0.40))
        return p
    }
}

struct WIFSofaGlyph: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width, h = rect.height
        let body = CGRect(x: rect.minX + w * 0.10, y: rect.minY + h * 0.34,
                          width: w * 0.80, height: h * 0.34)
        p.addRoundedRect(in: body, cornerSize: CGSize(width: w * 0.07, height: w * 0.07))
        // Back rest.
        let back = CGRect(x: rect.minX + w * 0.18, y: rect.minY + h * 0.18,
                          width: w * 0.64, height: h * 0.22)
        p.addRoundedRect(in: back, cornerSize: CGSize(width: w * 0.06, height: w * 0.06))
        // Legs.
        p.move(to: CGPoint(x: rect.minX + w * 0.20, y: body.maxY))
        p.addLine(to: CGPoint(x: rect.minX + w * 0.20, y: body.maxY + h * 0.12))
        p.move(to: CGPoint(x: rect.maxX - w * 0.20, y: body.maxY))
        p.addLine(to: CGPoint(x: rect.maxX - w * 0.20, y: body.maxY + h * 0.12))
        return p
    }
}

struct WIFRouteGlyph: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width, h = rect.height
        let a = CGPoint(x: rect.minX + w * 0.16, y: rect.maxY - h * 0.18)
        let b = CGPoint(x: rect.midX, y: rect.midY)
        let c = CGPoint(x: rect.maxX - w * 0.16, y: rect.minY + h * 0.18)
        p.move(to: a)
        p.addLine(to: b)
        p.addLine(to: c)
        let r = min(w, h) * 0.11
        for point in [a, b, c] {
            p.addEllipse(in: CGRect(x: point.x - r, y: point.y - r, width: r * 2, height: r * 2))
        }
        return p
    }
}

struct WIFRulerGlyph: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width, h = rect.height
        let body = CGRect(x: rect.minX + w * 0.08, y: rect.minY + h * 0.30,
                          width: w * 0.84, height: h * 0.40)
        p.addRect(body)
        var i = 1
        while i < 6 {
            let x = body.minX + body.width * CGFloat(i) / 6.0
            let depth = i % 2 == 0 ? body.height * 0.55 : body.height * 0.34
            p.move(to: CGPoint(x: x, y: body.minY))
            p.addLine(to: CGPoint(x: x, y: body.minY + depth))
            i += 1
        }
        return p
    }
}

struct WIFSlidersGlyph: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width, h = rect.height
        let rows: [CGFloat] = [0.26, 0.50, 0.74]
        let knobs: [CGFloat] = [0.66, 0.34, 0.56]
        for (index, row) in rows.enumerated() {
            let y = rect.minY + h * row
            p.move(to: CGPoint(x: rect.minX + w * 0.10, y: y))
            p.addLine(to: CGPoint(x: rect.maxX - w * 0.10, y: y))
            let cx = rect.minX + w * knobs[index]
            let r = min(w, h) * 0.10
            p.addEllipse(in: CGRect(x: cx - r, y: y - r, width: r * 2, height: r * 2))
        }
        return p
    }
}

struct WIFCheckGlyph: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.minX + rect.width * 0.18, y: rect.minY + rect.height * 0.54))
        p.addLine(to: CGPoint(x: rect.minX + rect.width * 0.41, y: rect.minY + rect.height * 0.76))
        p.addLine(to: CGPoint(x: rect.minX + rect.width * 0.82, y: rect.minY + rect.height * 0.26))
        return p
    }
}

struct WIFCrossGlyph: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let inset = min(rect.width, rect.height) * 0.24
        p.move(to: CGPoint(x: rect.minX + inset, y: rect.minY + inset))
        p.addLine(to: CGPoint(x: rect.maxX - inset, y: rect.maxY - inset))
        p.move(to: CGPoint(x: rect.maxX - inset, y: rect.minY + inset))
        p.addLine(to: CGPoint(x: rect.minX + inset, y: rect.maxY - inset))
        return p
    }
}

/// A turned-object mark: a small rectangle drawn on a slant.
struct WIFTiltGlyph: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let c = CGPoint(x: rect.midX, y: rect.midY)
        let halfW = rect.width * 0.34
        let halfH = rect.height * 0.17
        let angle: CGFloat = -0.55
        let corners = [CGPoint(x: -halfW, y: -halfH), CGPoint(x: halfW, y: -halfH),
                       CGPoint(x: halfW, y: halfH), CGPoint(x: -halfW, y: halfH)]
        let rotated = corners.map { point -> CGPoint in
            CGPoint(x: c.x + point.x * cos(angle) - point.y * sin(angle),
                    y: c.y + point.x * sin(angle) + point.y * cos(angle))
        }
        p.move(to: rotated[0])
        for point in rotated.dropFirst() { p.addLine(to: point) }
        p.closeSubpath()
        return p
    }
}

struct WIFPlusGlyph: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let inset = min(rect.width, rect.height) * 0.24
        p.move(to: CGPoint(x: rect.midX, y: rect.minY + inset))
        p.addLine(to: CGPoint(x: rect.midX, y: rect.maxY - inset))
        p.move(to: CGPoint(x: rect.minX + inset, y: rect.midY))
        p.addLine(to: CGPoint(x: rect.maxX - inset, y: rect.midY))
        return p
    }
}

struct WIFTrashGlyph: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width, h = rect.height
        p.move(to: CGPoint(x: rect.minX + w * 0.16, y: rect.minY + h * 0.26))
        p.addLine(to: CGPoint(x: rect.maxX - w * 0.16, y: rect.minY + h * 0.26))
        let body = CGRect(x: rect.minX + w * 0.24, y: rect.minY + h * 0.30,
                          width: w * 0.52, height: h * 0.56)
        p.addRect(body)
        p.move(to: CGPoint(x: rect.minX + w * 0.40, y: rect.minY + h * 0.26))
        p.addLine(to: CGPoint(x: rect.minX + w * 0.40, y: rect.minY + h * 0.16))
        p.addLine(to: CGPoint(x: rect.maxX - w * 0.40, y: rect.minY + h * 0.16))
        p.addLine(to: CGPoint(x: rect.maxX - w * 0.40, y: rect.minY + h * 0.26))
        return p
    }
}

/// Points up by default; rotate for the other directions.
struct WIFChevronGlyph: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.minX + rect.width * 0.22, y: rect.minY + rect.height * 0.64))
        p.addLine(to: CGPoint(x: rect.midX, y: rect.minY + rect.height * 0.34))
        p.addLine(to: CGPoint(x: rect.maxX - rect.width * 0.22, y: rect.minY + rect.height * 0.64))
        return p
    }
}

struct WIFDiamondGlyph: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.midX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        p.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.midY))
        p.closeSubpath()
        return p
    }
}

struct WIFBoxGlyph: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width, h = rect.height
        let front = CGRect(x: rect.minX + w * 0.10, y: rect.minY + h * 0.30,
                           width: w * 0.60, height: h * 0.58)
        p.addRect(front)
        p.move(to: CGPoint(x: front.minX, y: front.minY))
        p.addLine(to: CGPoint(x: front.minX + w * 0.20, y: rect.minY + h * 0.12))
        p.addLine(to: CGPoint(x: front.maxX + w * 0.20, y: rect.minY + h * 0.12))
        p.addLine(to: CGPoint(x: front.maxX, y: front.minY))
        p.move(to: CGPoint(x: front.maxX, y: front.maxY))
        p.addLine(to: CGPoint(x: front.maxX + w * 0.20, y: front.maxY - h * 0.18))
        p.addLine(to: CGPoint(x: front.maxX + w * 0.20, y: rect.minY + h * 0.12))
        return p
    }
}

// MARK: - Rendering helper

/// Wraps a glyph in a fixed square so icons line up wherever they are used. The tap target is
/// always added by the caller — a stroked path on its own has almost no hit area.
struct WIFIcon<G: Shape>: View {
    let glyph: G
    var size: CGFloat = 22
    var color: Color = WIFPalette.ink
    var weight: CGFloat = 1.8
    var filled: Bool = false

    var body: some View {
        Group {
            if filled {
                glyph.fill(color)
            } else {
                glyph.stroke(color, style: StrokeStyle(lineWidth: weight, lineCap: .round, lineJoin: .round))
            }
        }
        .frame(width: size, height: size)
    }
}

/// The icon that belongs to an obstacle kind, ready to drop into a row.
struct WIFKindIcon: View {
    let kind: WIFObstacleKind
    var size: CGFloat = 22
    var color: Color = WIFPalette.ink

    var body: some View {
        switch kind {
        case .opening: return AnyView(WIFIcon(glyph: WIFDoorGlyph(), size: size, color: color))
        case .turn: return AnyView(WIFIcon(glyph: WIFTurnGlyph(), size: size, color: color))
        case .stair: return AnyView(WIFIcon(glyph: WIFStairGlyph(), size: size, color: color))
        case .elevator: return AnyView(WIFIcon(glyph: WIFLiftGlyph(), size: size, color: color))
        }
    }
}
