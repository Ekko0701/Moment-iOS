import SwiftUI

public enum MomentPillButtonStyle {
    case primary
    case secondary
    case magentaPromo
}

public struct MomentPillButton: View {
    let title: String
    let style: MomentPillButtonStyle
    let action: () -> Void

    public init(_ title: String, style: MomentPillButtonStyle = .primary, action: @escaping () -> Void) {
        self.title = title
        self.style = style
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Text(title)
                .font(MomentTypography.button)
                .frame(maxWidth: .infinity)
                .frame(minHeight: 44)
                .foregroundColor(textColor)
                .background(backgroundColor)
                .cornerRadius(Spacing.Radius.pill)
        }
        .pressState { isPressed in
            if isPressed {
                // Scale on press for tactile feedback (no darkening per spec)
            }
        }
    }

    private var backgroundColor: Color {
        switch style {
        case .primary:
            return MomentColor.ink
        case .secondary:
            return MomentColor.canvas
        case .magentaPromo:
            return MomentColor.accentMagenta
        }
    }

    private var textColor: Color {
        switch style {
        case .primary, .magentaPromo:
            return MomentColor.inverseInk
        case .secondary:
            return MomentColor.ink
        }
    }
}

// MARK: - Secondary Button with hairline border (mobile legibility adjustment)
public struct MomentSecondaryPillButton: View {
    let title: String
    let action: () -> Void

    public init(_ title: String, action: @escaping () -> Void) {
        self.title = title
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Text(title)
                .font(MomentTypography.button)
                .frame(maxWidth: .infinity)
                .frame(minHeight: 44)
                .foregroundColor(MomentColor.ink)
                .background(MomentColor.canvas)
                .overlay(
                    RoundedRectangle(cornerRadius: Spacing.Radius.pill)
                        .stroke(MomentColor.hairline, lineWidth: 1)
                )
                .cornerRadius(Spacing.Radius.pill)
        }
    }
}

// MARK: - Icon Circle Button
public struct MomentIconCircleButton: View {
    let systemName: String
    let inverse: Bool
    let action: () -> Void

    public init(systemName: String, inverse: Bool = false, action: @escaping () -> Void) {
        self.systemName = systemName
        self.inverse = inverse
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(inverse ? MomentColor.inverseInk : MomentColor.ink)
                .frame(width: 44, height: 44)
                .background(
                    inverse
                        ? MomentColor.inverseInk.opacity(0.16)
                        : MomentColor.surfaceSoft
                )
                .cornerRadius(Spacing.Radius.full)
        }
    }
}

// MARK: - Helper modifier for press state
struct PressStateModifier: ViewModifier {
    let onPress: (Bool) -> Void

    func body(content: Content) -> some View {
        content
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in onPress(true) }
                    .onEnded { _ in onPress(false) }
            )
    }
}

extension View {
    fileprivate func pressState(onPress: @escaping (Bool) -> Void) -> some View {
        modifier(PressStateModifier(onPress: onPress))
    }
}
