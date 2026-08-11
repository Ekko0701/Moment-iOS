import SwiftUI

// MARK: - Color Block Container
// Per spec: full-content-width panel with rounded.lg corners and spacing.xxl interior padding
// No shadow — color is the depth device.
public struct ColorBlock<Content: View>: View {
    let color: MomentColor.BlockColor
    let content: Content

    public init(color: MomentColor.BlockColor, @ViewBuilder content: () -> Content) {
        self.color = color
        self.content = content()
    }

    public var body: some View {
        content
            .frame(maxWidth: .infinity)
            .padding(Spacing.xxl)
            .background(color.color)
            .foregroundColor(color.textColor)
            .cornerRadius(Spacing.Radius.lg)
    }
}

// MARK: - Hairline Divider
public struct HairlineDivider: View {
    public init() {}

    public var body: some View {
        Divider()
            .frame(height: Spacing.hair)
            .background(MomentColor.hairline)
    }
}

// MARK: - Eyebrow Text (monospace uppercase)
public struct EyebrowText: View {
    let text: String

    public init(_ text: String) {
        self.text = text
    }

    public var body: some View {
        Text(text.uppercased())
            .font(MomentTypography.eyebrow)
            .tracking(1.2)
            .foregroundColor(MomentColor.ink)
    }
}

// MARK: - Text Input Field
public struct MomentTextField: View {
    let placeholder: String
    @Binding var text: String
    let isSecure: Bool
    let disablesAutocapitalization: Bool
    @State private var isFocused = false
    @Environment(\.colorScheme) private var colorScheme

    public init(_ placeholder: String, text: Binding<String>,
                isSecure: Bool = false, disablesAutocapitalization: Bool = false) {
        self.placeholder = placeholder
        self._text = text
        self.isSecure = isSecure
        self.disablesAutocapitalization = disablesAutocapitalization
    }

    public var body: some View {
        Group {
            if isSecure {
                SecureField(text: $text, prompt: prompt) { Text(placeholder) }
            } else {
                TextField(text: $text, prompt: prompt) { Text(placeholder) }
            }
        }
        .font(MomentTypography.body)
        .foregroundColor(MomentColor.ink)
        .textInputAutocapitalization(disablesAutocapitalization ? .never : .sentences)
        .autocorrectionDisabled(disablesAutocapitalization)
        .padding(.horizontal, 18)
        .frame(minHeight: 52)
        .background(fieldFill)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(fieldStroke, lineWidth: 1)
        )
    }

    // GlassMinimal 시안 입력 필드(52pt, 라운드 16) — 양 테마 대칭:
    // 다크는 흰색 8% 채움 + 14% 테두리, 라이트(화이트 톤)는 잉크 5% 채움 + 10% 테두리.
    // 순백 캔버스와 오브 배경 어디서든 은은하게 읽힌다.
    private var prompt: Text {
        Text(placeholder).foregroundColor(MomentColor.ink.opacity(0.45))
    }

    private var fieldFill: Color {
        colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.05)
    }

    private var fieldStroke: Color {
        colorScheme == .dark ? Color.white.opacity(0.14) : Color.black.opacity(0.10)
    }
}
