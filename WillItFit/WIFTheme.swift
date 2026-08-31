import SwiftUI

/// Fixed palette. The app forces a light appearance (Info.plist `UIUserInterfaceStyle = Light`)
/// and never reads the device theme, so every colour below is an absolute value.
enum WIFPalette {
    static let ink       = Color(red: 0.086, green: 0.149, blue: 0.247)   // #16263F
    static let inkSoft   = Color(red: 0.180, green: 0.259, blue: 0.361)
    static let paper     = Color(red: 0.957, green: 0.937, blue: 0.902)   // #F4EFE6
    static let panel     = Color(red: 1.000, green: 0.996, blue: 0.988)
    static let wash      = Color(red: 0.925, green: 0.906, blue: 0.867)
    static let amber     = Color(red: 0.910, green: 0.588, blue: 0.235)   // #E8963C
    static let amberDeep = Color(red: 0.741, green: 0.431, blue: 0.129)
    static let teal      = Color(red: 0.180, green: 0.620, blue: 0.561)   // #2E9E8F
    static let tealSoft  = Color(red: 0.851, green: 0.929, blue: 0.910)
    static let rust      = Color(red: 0.769, green: 0.333, blue: 0.231)   // #C4553B
    static let rustSoft  = Color(red: 0.976, green: 0.886, blue: 0.859)
    static let slate     = Color(red: 0.420, green: 0.478, blue: 0.561)   // #6B7A8F
    static let line      = Color(red: 0.847, green: 0.812, blue: 0.753)   // #D8CFC0
    static let amberSoft = Color(red: 0.988, green: 0.933, blue: 0.855)
}

enum WIFType {
    static func display(_ size: CGFloat) -> Font { .system(size: size, weight: .heavy) }
    static func heading(_ size: CGFloat) -> Font { .system(size: size, weight: .bold) }
    static func body(_ size: CGFloat) -> Font { .system(size: size, weight: .regular) }
    static func medium(_ size: CGFloat) -> Font { .system(size: size, weight: .medium) }
    static func semibold(_ size: CGFloat) -> Font { .system(size: size, weight: .semibold) }
    static func figure(_ size: CGFloat) -> Font { .system(size: size, weight: .bold, design: .monospaced) }
    static func caption(_ size: CGFloat) -> Font { .system(size: size, weight: .semibold, design: .monospaced) }
}

enum WIFMetric {
    /// Widest the reading column ever gets. Above this the content is centred, which is what
    /// keeps iPad and landscape from stretching a form across the whole screen.
    static let contentMaxWidth: CGFloat = 620
    static let screenPadding: CGFloat = 16
    static let cardPadding: CGFloat = 14
    static let corner: CGFloat = 14
    static let tabBarHeight: CGFloat = 58

    /// Usable width for a fixed-size child, after subtracting every horizontal inset that sits
    /// between the screen edge and that child.
    static func innerWidth(_ available: CGFloat, insets: CGFloat) -> CGFloat {
        max(120, min(available, contentMaxWidth) - insets)
    }

    /// Screen width clamped to the real device width. A bare GeometryReader can report more
    /// than is visible in iPad compatibility mode, which pushes fixed-size content off-screen.
    static func safeWidth(_ proposed: CGFloat) -> CGFloat {
        let screen = UIScreen.main.bounds.width
        if proposed <= 0 { return screen }
        return min(proposed, screen)
    }

    static var isCompactHeight: Bool { UIScreen.main.bounds.height <= 700 }
}
