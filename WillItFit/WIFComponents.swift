import SwiftUI

// MARK: - Screen scaffold

/// Header plus a scrolling body. The header sits inside the safe area and the scroll view is
/// below it, so nothing is ever drawn over the status bar. The reading column is capped so the
/// same code reads well on a 4.7 inch phone, an iPad and in landscape.
struct WIFScaffold<Content: View>: View {
    let title: String
    var subtitle: String?
    var showsBack: Bool
    var trailing: AnyView?
    let content: Content

    @Environment(\.presentationMode) private var presentationMode

    init(title: String,
         subtitle: String? = nil,
         showsBack: Bool = false,
         trailing: AnyView? = nil,
         @ViewBuilder content: () -> Content) {
        self.title = title
        self.subtitle = subtitle
        self.showsBack = showsBack
        self.trailing = trailing
        self.content = content()
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 14) {
                    content
                }
                .padding(.horizontal, WIFMetric.screenPadding)
                .padding(.top, 12)
                .padding(.bottom, 28)
                .frame(maxWidth: WIFMetric.contentMaxWidth, alignment: .leading)
                .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .background(WIFPalette.paper.edgesIgnoringSafeArea(.all))
        .navigationBarHidden(true)
        .navigationBarTitle("")
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 10) {
            if showsBack {
                Button(action: { presentationMode.wrappedValue.dismiss() }) {
                    HStack(spacing: 5) {
                        WIFIcon(glyph: WIFChevronGlyph(), size: 18, color: WIFPalette.ink, weight: 2.2)
                            .rotationEffect(.degrees(-90))
                        Text("Back")
                            .font(WIFType.semibold(14))
                            .foregroundColor(WIFPalette.ink)
                    }
                    .padding(.vertical, 8)
                    .padding(.trailing, 6)
                    .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())
            }
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(WIFType.display(showsBack ? 18 : 22))
                    .foregroundColor(WIFPalette.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                if let subtitle = subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(WIFType.body(11))
                        .foregroundColor(WIFPalette.slate)
                        .lineLimit(2)
                }
            }
            Spacer(minLength: 6)
            if let trailing = trailing { trailing }
        }
        .padding(.horizontal, WIFMetric.screenPadding)
        .padding(.top, 8)
        .padding(.bottom, 10)
        .frame(maxWidth: WIFMetric.contentMaxWidth)
        .frame(maxWidth: .infinity)
        .background(
            WIFPalette.paper
                .overlay(Rectangle().fill(WIFPalette.line).frame(height: 1), alignment: .bottom)
        )
    }
}

// MARK: - Building blocks

struct WIFCard<Content: View>: View {
    var tint: Color = WIFPalette.panel
    var border: Color = WIFPalette.line
    let content: Content

    init(tint: Color = WIFPalette.panel,
         border: Color = WIFPalette.line,
         @ViewBuilder content: () -> Content) {
        self.tint = tint
        self.border = border
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) { content }
            .padding(WIFMetric.cardPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: WIFMetric.corner).fill(tint))
            .overlay(RoundedRectangle(cornerRadius: WIFMetric.corner).stroke(border, lineWidth: 1))
    }
}

struct WIFSectionLabel: View {
    let text: String
    var body: some View {
        Text(text.uppercased())
            .font(WIFType.caption(11))
            .tracking(1.1)
            .foregroundColor(WIFPalette.slate)
    }
}

struct WIFHairline: View {
    var body: some View {
        Rectangle().fill(WIFPalette.line).frame(height: 1)
    }
}

struct WIFKeyValue: View {
    let key: String
    let value: String
    var valueColor: Color = WIFPalette.ink
    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Text(key)
                .font(WIFType.body(13))
                .foregroundColor(WIFPalette.slate)
            Spacer(minLength: 8)
            Text(value)
                .font(WIFType.figure(13))
                .foregroundColor(valueColor)
                .multilineTextAlignment(.trailing)
        }
    }
}

struct WIFNoticeBox: View {
    let text: String
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            WIFIcon(glyph: WIFRulerGlyph(), size: 18, color: WIFPalette.amberDeep, weight: 1.6)
            Text(text)
                .font(WIFType.body(12))
                .foregroundColor(WIFPalette.amberDeep)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 12).fill(WIFPalette.amberSoft))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(WIFPalette.amber.opacity(0.55), lineWidth: 1))
    }
}

// MARK: - Controls

struct WIFPrimaryButton: View {
    let title: String
    var tint: Color = WIFPalette.ink
    var textColor: Color = Color.white
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(WIFType.semibold(15))
                .foregroundColor(textColor)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
                .background(RoundedRectangle(cornerRadius: 12).fill(tint))
                .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct WIFGhostButton: View {
    let title: String
    var tint: Color = WIFPalette.ink
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(WIFType.semibold(14))
                .foregroundColor(tint)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 11)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color.clear))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(tint.opacity(0.5), lineWidth: 1.4))
                .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

/// A small square control built around a glyph. The content shape is set on the label, because a
/// stroked path over a clear background has effectively no tap area of its own.
struct WIFGlyphButton<G: Shape>: View {
    let glyph: G
    var size: CGFloat = 34
    var glyphSize: CGFloat = 17
    var color: Color = WIFPalette.ink
    var background: Color = WIFPalette.wash
    var enabled: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: { if enabled { action() } }) {
            WIFIcon(glyph: glyph, size: glyphSize, color: enabled ? color : color.opacity(0.3), weight: 2.0)
                .frame(width: size, height: size)
                .background(RoundedRectangle(cornerRadius: 9).fill(background))
                .overlay(RoundedRectangle(cornerRadius: 9).stroke(WIFPalette.line, lineWidth: 1))
                .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct WIFChoiceChip: View {
    let title: String
    var detail: String?
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(WIFType.semibold(14))
                    .foregroundColor(selected ? Color.white : WIFPalette.ink)
                    .lineLimit(1)
                if let detail = detail, !detail.isEmpty {
                    Text(detail)
                        .font(WIFType.caption(10))
                        .foregroundColor(selected ? Color.white.opacity(0.85) : WIFPalette.slate)
                        .lineLimit(1)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(RoundedRectangle(cornerRadius: 11).fill(selected ? WIFPalette.ink : WIFPalette.panel))
            .overlay(RoundedRectangle(cornerRadius: 11)
                        .stroke(selected ? WIFPalette.ink : WIFPalette.line, lineWidth: 1))
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

/// A custom switch. The system Toggle is not used anywhere in the app.
struct WIFSwitchRow: View {
    let title: String
    var detail: String?
    @Binding var isOn: Bool

    var body: some View {
        Button(action: { isOn.toggle() }) {
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(WIFType.semibold(14))
                        .foregroundColor(WIFPalette.ink)
                        .multilineTextAlignment(.leading)
                    if let detail = detail, !detail.isEmpty {
                        Text(detail)
                            .font(WIFType.body(11))
                            .foregroundColor(WIFPalette.slate)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                Spacer(minLength: 8)
                WIFSwitchTrack(isOn: isOn)
            }
            .padding(.vertical, 7)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct WIFSwitchTrack: View {
    let isOn: Bool
    var body: some View {
        ZStack(alignment: isOn ? .trailing : .leading) {
            RoundedRectangle(cornerRadius: 12)
                .fill(isOn ? WIFPalette.teal : WIFPalette.line)
                .frame(width: 46, height: 26)
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white)
                .frame(width: 20, height: 20)
                .padding(.horizontal, 3)
                .shadow(color: Color.black.opacity(0.12), radius: 1, x: 0, y: 1)
        }
        .frame(width: 46, height: 26)
        .animation(.easeInOut(duration: 0.15), value: isOn)
    }
}

// MARK: - Numeric entry

/// A single measurement field.
///
/// Every field carries its own case of the screen's focus enum and sets that focus from a tap on
/// the whole box, not just the text run. Without that, a form of several fields ends up with only
/// the first one reachable and the rest look dead.
struct WIFDimensionField<F: Hashable>: View {
    let title: String
    var hint: String?
    @Binding var text: String
    let unitLabel: String
    let field: F
    let focus: FocusState<F?>.Binding

    private var isFocused: Bool { focus.wrappedValue == field }

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title.uppercased())
                .font(WIFType.caption(10))
                .tracking(0.8)
                .foregroundColor(WIFPalette.slate)
            HStack(spacing: 8) {
                TextField("0", text: $text)
                    .keyboardType(.decimalPad)
                    .font(WIFType.figure(17))
                    .foregroundColor(WIFPalette.ink)
                    .accentColor(WIFPalette.amberDeep)
                    .focused(focus, equals: field)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text(unitLabel)
                    .font(WIFType.caption(12))
                    .foregroundColor(WIFPalette.slate)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 11)
            .background(RoundedRectangle(cornerRadius: 10)
                            .fill(isFocused ? WIFPalette.amberSoft : WIFPalette.wash))
            .overlay(RoundedRectangle(cornerRadius: 10)
                        .stroke(isFocused ? WIFPalette.amber : WIFPalette.line,
                                lineWidth: isFocused ? 2 : 1))
            .contentShape(Rectangle())
            .onTapGesture { focus.wrappedValue = field }
            if let hint = hint, !hint.isEmpty {
                Text(hint)
                    .font(WIFType.body(10))
                    .foregroundColor(WIFPalette.slate)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

/// A plain text field for names, with the same explicit focus handling.
struct WIFTextField<F: Hashable>: View {
    let title: String
    @Binding var text: String
    let field: F
    let focus: FocusState<F?>.Binding

    private var isFocused: Bool { focus.wrappedValue == field }

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title.uppercased())
                .font(WIFType.caption(10))
                .tracking(0.8)
                .foregroundColor(WIFPalette.slate)
            TextField("", text: $text)
                .font(WIFType.medium(15))
                .foregroundColor(WIFPalette.ink)
                .accentColor(WIFPalette.amberDeep)
                .disableAutocorrection(true)
                .focused(focus, equals: field)
                .padding(.horizontal, 12)
                .padding(.vertical, 11)
                .background(RoundedRectangle(cornerRadius: 10)
                                .fill(isFocused ? WIFPalette.amberSoft : WIFPalette.wash))
                .overlay(RoundedRectangle(cornerRadius: 10)
                            .stroke(isFocused ? WIFPalette.amber : WIFPalette.line,
                                    lineWidth: isFocused ? 2 : 1))
                .contentShape(Rectangle())
                .onTapGesture { focus.wrappedValue = field }
        }
    }
}

// MARK: - Verdict presentation

struct WIFVerdictChip: View {
    let verdict: WIFVerdict
    var compact: Bool = false

    var body: some View {
        HStack(spacing: 5) {
            glyph
            Text(compact ? verdict.shortTitle : verdict.title)
                .font(WIFType.semibold(compact ? 11 : 13))
                .foregroundColor(WIFVerdictStyle.foreground(verdict))
                .lineLimit(1)
        }
        .padding(.horizontal, compact ? 8 : 11)
        .padding(.vertical, compact ? 5 : 7)
        .background(Capsule().fill(WIFVerdictStyle.background(verdict)))
        .overlay(Capsule().stroke(WIFVerdictStyle.foreground(verdict).opacity(0.35), lineWidth: 1))
    }

    private var glyph: some View {
        let size: CGFloat = compact ? 12 : 14
        switch verdict {
        case .clear:
            return AnyView(WIFIcon(glyph: WIFCheckGlyph(), size: size,
                                   color: WIFVerdictStyle.foreground(verdict), weight: 2.2))
        case .rotated:
            return AnyView(WIFIcon(glyph: WIFTiltGlyph(), size: size,
                                   color: WIFVerdictStyle.foreground(verdict), weight: 1.8))
        case .blocked:
            return AnyView(WIFIcon(glyph: WIFCrossGlyph(), size: size,
                                   color: WIFVerdictStyle.foreground(verdict), weight: 2.2))
        }
    }
}

enum WIFVerdictStyle {
    static func foreground(_ verdict: WIFVerdict) -> Color {
        switch verdict {
        case .clear: return WIFPalette.teal
        case .rotated: return WIFPalette.amberDeep
        case .blocked: return WIFPalette.rust
        }
    }

    static func background(_ verdict: WIFVerdict) -> Color {
        switch verdict {
        case .clear: return WIFPalette.tealSoft
        case .rotated: return WIFPalette.amberSoft
        case .blocked: return WIFPalette.rustSoft
        }
    }
}

// MARK: - Empty state

struct WIFEmptyState: View {
    let title: String
    let message: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(WIFType.heading(16))
                .foregroundColor(WIFPalette.ink)
            Text(message)
                .font(WIFType.body(13))
                .foregroundColor(WIFPalette.slate)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(WIFMetric.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: WIFMetric.corner).fill(WIFPalette.wash))
        .overlay(RoundedRectangle(cornerRadius: WIFMetric.corner)
                    .stroke(WIFPalette.line, lineWidth: 1))
    }
}
