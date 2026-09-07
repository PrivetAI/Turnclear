import SwiftUI

// MARK: - Screen scaffold

/// Header plus a scrolling body. The header sits inside the safe area and the scroll view is
/// below it, so nothing is ever drawn over the status bar. The reading column is capped so the
/// same code reads well on a 4.7 inch phone, an iPad and in landscape.
struct TCScaffold<Content: View>: View {
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
                .padding(.horizontal, TCMetric.screenPadding)
                .padding(.top, 12)
                .padding(.bottom, 28)
                .frame(maxWidth: TCMetric.contentMaxWidth, alignment: .leading)
                .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .background(TCPalette.paper.edgesIgnoringSafeArea(.all))
        .navigationBarHidden(true)
        .navigationBarTitle("")
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 10) {
            if showsBack {
                Button(action: { presentationMode.wrappedValue.dismiss() }) {
                    HStack(spacing: 5) {
                        TCIcon(glyph: TCChevronGlyph(), size: 18, color: TCPalette.ink, weight: 2.2)
                            .rotationEffect(.degrees(-90))
                        Text("Back")
                            .font(TCType.semibold(14))
                            .foregroundColor(TCPalette.ink)
                    }
                    .padding(.vertical, 8)
                    .padding(.trailing, 6)
                    .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())
            }
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(TCType.display(showsBack ? 18 : 22))
                    .foregroundColor(TCPalette.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                if let subtitle = subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(TCType.body(11))
                        .foregroundColor(TCPalette.slate)
                        .lineLimit(2)
                }
            }
            Spacer(minLength: 6)
            if let trailing = trailing { trailing }
        }
        .padding(.horizontal, TCMetric.screenPadding)
        .padding(.top, 8)
        .padding(.bottom, 10)
        .frame(maxWidth: TCMetric.contentMaxWidth)
        .frame(maxWidth: .infinity)
        .background(
            TCPalette.paper
                .overlay(Rectangle().fill(TCPalette.line).frame(height: 1), alignment: .bottom)
        )
    }
}

// MARK: - Building blocks

struct TCCard<Content: View>: View {
    var tint: Color = TCPalette.panel
    var border: Color = TCPalette.line
    let content: Content

    init(tint: Color = TCPalette.panel,
         border: Color = TCPalette.line,
         @ViewBuilder content: () -> Content) {
        self.tint = tint
        self.border = border
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) { content }
            .padding(TCMetric.cardPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: TCMetric.corner).fill(tint))
            .overlay(RoundedRectangle(cornerRadius: TCMetric.corner).stroke(border, lineWidth: 1))
    }
}

struct TCSectionLabel: View {
    let text: String
    var body: some View {
        Text(text.uppercased())
            .font(TCType.caption(11))
            .tracking(1.1)
            .foregroundColor(TCPalette.slate)
    }
}

struct TCHairline: View {
    var body: some View {
        Rectangle().fill(TCPalette.line).frame(height: 1)
    }
}

struct TCKeyValue: View {
    let key: String
    let value: String
    var valueColor: Color = TCPalette.ink
    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Text(key)
                .font(TCType.body(13))
                .foregroundColor(TCPalette.slate)
            Spacer(minLength: 8)
            Text(value)
                .font(TCType.figure(13))
                .foregroundColor(valueColor)
                .multilineTextAlignment(.trailing)
        }
    }
}

struct TCNoticeBox: View {
    let text: String
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            TCIcon(glyph: TCRulerGlyph(), size: 18, color: TCPalette.amberDeep, weight: 1.6)
            Text(text)
                .font(TCType.body(12))
                .foregroundColor(TCPalette.amberDeep)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 12).fill(TCPalette.amberSoft))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(TCPalette.amber.opacity(0.55), lineWidth: 1))
    }
}

// MARK: - Controls

struct TCPrimaryButton: View {
    let title: String
    var tint: Color = TCPalette.ink
    var textColor: Color = Color.white
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(TCType.semibold(15))
                .foregroundColor(textColor)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
                .background(RoundedRectangle(cornerRadius: 12).fill(tint))
                .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct TCGhostButton: View {
    let title: String
    var tint: Color = TCPalette.ink
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(TCType.semibold(14))
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
struct TCGlyphButton<G: Shape>: View {
    let glyph: G
    var size: CGFloat = 34
    var glyphSize: CGFloat = 17
    var color: Color = TCPalette.ink
    var background: Color = TCPalette.wash
    var enabled: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: { if enabled { action() } }) {
            TCIcon(glyph: glyph, size: glyphSize, color: enabled ? color : color.opacity(0.3), weight: 2.0)
                .frame(width: size, height: size)
                .background(RoundedRectangle(cornerRadius: 9).fill(background))
                .overlay(RoundedRectangle(cornerRadius: 9).stroke(TCPalette.line, lineWidth: 1))
                .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct TCChoiceChip: View {
    let title: String
    var detail: String?
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(TCType.semibold(14))
                    .foregroundColor(selected ? Color.white : TCPalette.ink)
                    .lineLimit(1)
                if let detail = detail, !detail.isEmpty {
                    Text(detail)
                        .font(TCType.caption(10))
                        .foregroundColor(selected ? Color.white.opacity(0.85) : TCPalette.slate)
                        .lineLimit(1)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(RoundedRectangle(cornerRadius: 11).fill(selected ? TCPalette.ink : TCPalette.panel))
            .overlay(RoundedRectangle(cornerRadius: 11)
                        .stroke(selected ? TCPalette.ink : TCPalette.line, lineWidth: 1))
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

/// A custom switch. The system Toggle is not used anywhere in the app.
struct TCSwitchRow: View {
    let title: String
    var detail: String?
    @Binding var isOn: Bool

    var body: some View {
        Button(action: { isOn.toggle() }) {
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(TCType.semibold(14))
                        .foregroundColor(TCPalette.ink)
                        .multilineTextAlignment(.leading)
                    if let detail = detail, !detail.isEmpty {
                        Text(detail)
                            .font(TCType.body(11))
                            .foregroundColor(TCPalette.slate)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                Spacer(minLength: 8)
                TCSwitchTrack(isOn: isOn)
            }
            .padding(.vertical, 7)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct TCSwitchTrack: View {
    let isOn: Bool
    var body: some View {
        ZStack(alignment: isOn ? .trailing : .leading) {
            RoundedRectangle(cornerRadius: 12)
                .fill(isOn ? TCPalette.teal : TCPalette.line)
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
struct TCDimensionField<F: Hashable>: View {
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
                .font(TCType.caption(10))
                .tracking(0.8)
                .foregroundColor(TCPalette.slate)
            HStack(spacing: 8) {
                TextField("0", text: $text)
                    .keyboardType(.decimalPad)
                    .font(TCType.figure(17))
                    .foregroundColor(TCPalette.ink)
                    .accentColor(TCPalette.amberDeep)
                    .focused(focus, equals: field)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text(unitLabel)
                    .font(TCType.caption(12))
                    .foregroundColor(TCPalette.slate)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 11)
            .background(RoundedRectangle(cornerRadius: 10)
                            .fill(isFocused ? TCPalette.amberSoft : TCPalette.wash))
            .overlay(RoundedRectangle(cornerRadius: 10)
                        .stroke(isFocused ? TCPalette.amber : TCPalette.line,
                                lineWidth: isFocused ? 2 : 1))
            .contentShape(Rectangle())
            .onTapGesture { focus.wrappedValue = field }
            if let hint = hint, !hint.isEmpty {
                Text(hint)
                    .font(TCType.body(10))
                    .foregroundColor(TCPalette.slate)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

/// A plain text field for names, with the same explicit focus handling.
struct TCTextField<F: Hashable>: View {
    let title: String
    @Binding var text: String
    let field: F
    let focus: FocusState<F?>.Binding

    private var isFocused: Bool { focus.wrappedValue == field }

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title.uppercased())
                .font(TCType.caption(10))
                .tracking(0.8)
                .foregroundColor(TCPalette.slate)
            TextField("", text: $text)
                .font(TCType.medium(15))
                .foregroundColor(TCPalette.ink)
                .accentColor(TCPalette.amberDeep)
                .disableAutocorrection(true)
                .focused(focus, equals: field)
                .padding(.horizontal, 12)
                .padding(.vertical, 11)
                .background(RoundedRectangle(cornerRadius: 10)
                                .fill(isFocused ? TCPalette.amberSoft : TCPalette.wash))
                .overlay(RoundedRectangle(cornerRadius: 10)
                            .stroke(isFocused ? TCPalette.amber : TCPalette.line,
                                    lineWidth: isFocused ? 2 : 1))
                .contentShape(Rectangle())
                .onTapGesture { focus.wrappedValue = field }
        }
    }
}

// MARK: - Verdict presentation

struct TCVerdictChip: View {
    let verdict: TCVerdict
    var compact: Bool = false

    var body: some View {
        HStack(spacing: 5) {
            glyph
            Text(compact ? verdict.shortTitle : verdict.title)
                .font(TCType.semibold(compact ? 11 : 13))
                .foregroundColor(TCVerdictStyle.foreground(verdict))
                .lineLimit(1)
        }
        .padding(.horizontal, compact ? 8 : 11)
        .padding(.vertical, compact ? 5 : 7)
        .background(Capsule().fill(TCVerdictStyle.background(verdict)))
        .overlay(Capsule().stroke(TCVerdictStyle.foreground(verdict).opacity(0.35), lineWidth: 1))
    }

    private var glyph: some View {
        let size: CGFloat = compact ? 12 : 14
        switch verdict {
        case .clear:
            return AnyView(TCIcon(glyph: TCCheckGlyph(), size: size,
                                   color: TCVerdictStyle.foreground(verdict), weight: 2.2))
        case .rotated:
            return AnyView(TCIcon(glyph: TCTiltGlyph(), size: size,
                                   color: TCVerdictStyle.foreground(verdict), weight: 1.8))
        case .blocked:
            return AnyView(TCIcon(glyph: TCCrossGlyph(), size: size,
                                   color: TCVerdictStyle.foreground(verdict), weight: 2.2))
        }
    }
}

enum TCVerdictStyle {
    static func foreground(_ verdict: TCVerdict) -> Color {
        switch verdict {
        case .clear: return TCPalette.teal
        case .rotated: return TCPalette.amberDeep
        case .blocked: return TCPalette.rust
        }
    }

    static func background(_ verdict: TCVerdict) -> Color {
        switch verdict {
        case .clear: return TCPalette.tealSoft
        case .rotated: return TCPalette.amberSoft
        case .blocked: return TCPalette.rustSoft
        }
    }
}

// MARK: - Empty state

struct TCEmptyState: View {
    let title: String
    let message: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(TCType.heading(16))
                .foregroundColor(TCPalette.ink)
            Text(message)
                .font(TCType.body(13))
                .foregroundColor(TCPalette.slate)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(TCMetric.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: TCMetric.corner).fill(TCPalette.wash))
        .overlay(RoundedRectangle(cornerRadius: TCMetric.corner)
                    .stroke(TCPalette.line, lineWidth: 1))
    }
}
