import SwiftUI

// MARK: - Press Feedback Style

/// 눌리는 순간 살짝 축소되는 촉감 피드백. 모든 pressable 요소가 공유한다.
/// scale은 접근성 "동작 줄이기"에서 비활성화하되, opacity 피드백은 유지한다.
public struct MomentPressStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let scale: CGFloat

    public init(scale: CGFloat = 0.97) {
        self.scale = scale
    }

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed && !reduceMotion ? scale : 1)
            .opacity(configuration.isPressed ? 0.92 : 1)
            .animation(.easeOut(duration: 0.16), value: configuration.isPressed)
    }
}

public enum MomentPillButtonStyle {
    case primary
    case secondary
    case magentaPromo
}

public struct MomentPillButton: View {
    let title: String
    let style: MomentPillButtonStyle
    let minHeight: CGFloat
    let action: () -> Void

    public init(_ title: String, style: MomentPillButtonStyle = .primary,
            minHeight: CGFloat = 44, action: @escaping () -> Void) {
        self.title = title
        self.style = style
        self.minHeight = minHeight
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Text(title)
                .font(MomentTypography.button)
                .frame(maxWidth: .infinity)
                .frame(minHeight: minHeight)
                .foregroundColor(textColor)
                .background(backgroundColor)
                .cornerRadius(Spacing.Radius.pill)
        }
        .buttonStyle(MomentPressStyle())
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

// MARK: - Glass Pill Button (Final-MVP — 오브 배경 위 보조 CTA)
public struct MomentGlassPillButton: View {
    let title: String
    let minHeight: CGFloat
    let action: () -> Void

    public init(_ title: String, minHeight: CGFloat = 44, action: @escaping () -> Void) {
        self.title = title
        self.minHeight = minHeight
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Text(title)
                .font(MomentTypography.button)
                .frame(maxWidth: .infinity)
                .frame(minHeight: minHeight)
                .foregroundColor(MomentColor.ink)
                // 프레스 피드백은 MomentPressStyle이 전 버전 일관 담당 — 네이티브 interactive와 이중 스케일 방지
                .glassCapsule(isInteractive: false)
        }
        .buttonStyle(MomentPressStyle())
    }
}

// MARK: - Secondary Button with hairline border (mobile legibility adjustment)
public struct MomentSecondaryPillButton: View {
    let title: String
    let minHeight: CGFloat
    let action: () -> Void

    public init(_ title: String, minHeight: CGFloat = 44, action: @escaping () -> Void) {
        self.title = title
        self.minHeight = minHeight
        self.action = action
    }

    public var body: some View {
        // 시안: 보조 CTA는 그레이 서피스 캡슐 — 순백 캔버스 위에서 canvas 배경은 사라져 보인다
        Button(action: action) {
            Text(title)
                .font(MomentTypography.button)
                .frame(maxWidth: .infinity)
                .frame(minHeight: minHeight)
                .foregroundColor(MomentColor.ink)
                .background(MomentColor.surfaceSoft)
                .overlay(
                    RoundedRectangle(cornerRadius: Spacing.Radius.pill)
                        .stroke(MomentColor.surfaceStroke, lineWidth: 1)
                )
                .cornerRadius(Spacing.Radius.pill)
        }
        .buttonStyle(MomentPressStyle())
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
        .buttonStyle(MomentPressStyle(scale: 0.9))
    }
}
