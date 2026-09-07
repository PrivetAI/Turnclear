import Foundation

/// Every measurement in this app is stored in millimetres and only converted at the edges
/// (text fields and labels). Keeping one canonical unit is what stops a value from drifting
/// when the user flips the global unit switch back and forth.
enum TCUnit: String, Codable, CaseIterable {
    case centimetres
    case inches

    var shortLabel: String {
        switch self {
        case .centimetres: return "cm"
        case .inches: return "in"
        }
    }

    var longLabel: String {
        switch self {
        case .centimetres: return "Centimetres"
        case .inches: return "Inches"
        }
    }

    /// Millimetres in one unit.
    var millimetresPerUnit: Double {
        switch self {
        case .centimetres: return 10.0
        case .inches: return 25.4
        }
    }

    var decimals: Int {
        switch self {
        case .centimetres: return 1
        case .inches: return 2
        }
    }
}

enum TCMeasure {
    /// mm -> display unit, rounded for presentation only.
    static func toUnit(_ millimetres: Double, _ unit: TCUnit) -> Double {
        millimetres / unit.millimetresPerUnit
    }

    /// display unit -> mm, snapped to a tenth of a millimetre so a value survives a
    /// cm -> in -> cm round trip unchanged.
    static func toMillimetres(_ value: Double, _ unit: TCUnit) -> Double {
        ((value * unit.millimetresPerUnit) * 10.0).rounded() / 10.0
    }

    static func text(_ millimetres: Double, _ unit: TCUnit) -> String {
        format(toUnit(millimetres, unit), decimals: unit.decimals)
    }

    /// Number plus unit, e.g. "182.5 cm".
    static func label(_ millimetres: Double, _ unit: TCUnit) -> String {
        text(millimetres, unit) + " " + unit.shortLabel
    }

    /// A signed clearance, e.g. "+3.4 cm" or "-1.2 cm".
    static func signedLabel(_ millimetres: Double, _ unit: TCUnit) -> String {
        let value = toUnit(millimetres, unit)
        let sign = value < -0.00001 ? "-" : "+"
        return sign + format(abs(value), decimals: unit.decimals) + " " + unit.shortLabel
    }

    static func triple(_ a: Double, _ b: Double, _ c: Double, _ unit: TCUnit) -> String {
        text(a, unit) + " x " + text(b, unit) + " x " + text(c, unit) + " " + unit.shortLabel
    }

    static func pair(_ a: Double, _ b: Double, _ unit: TCUnit) -> String {
        text(a, unit) + " x " + text(b, unit) + " " + unit.shortLabel
    }

    static func format(_ value: Double, decimals: Int) -> String {
        let rounded = (value * pow(10.0, Double(decimals))).rounded() / pow(10.0, Double(decimals))
        var out = String(format: "%.\(decimals)f", rounded)
        // Trim a trailing ".0" / ".00" so plain numbers read as plain numbers.
        if out.contains(".") {
            while out.hasSuffix("0") { out.removeLast() }
            if out.hasSuffix(".") { out.removeLast() }
        }
        return out.isEmpty ? "0" : out
    }

    static func angleText(_ degrees: Double) -> String {
        String(format: "%.2f", degrees) + " deg"
    }

    static func weightText(_ kilograms: Double) -> String {
        format(kilograms, decimals: 1) + " kg"
    }

    /// Accepts "72", "72.5" and "72,5" — a comma decimal separator is what a lot of tape
    /// measures and keyboards produce, and rejecting it silently loses the digit.
    static func parse(_ raw: String) -> Double? {
        let cleaned = raw
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: ",", with: ".")
        if cleaned.isEmpty { return nil }
        return Double(cleaned)
    }
}
