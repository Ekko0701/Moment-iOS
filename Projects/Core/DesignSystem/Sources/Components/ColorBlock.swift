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
                SecureField(placeholder, text: $text)
            } else {
                TextField(placeholder, text: $text)
            }
        }
        .font(MomentTypography.body)
        .textInputAutocapitalization(disablesAutocapitalization ? .never : .sentences)
        .autocorrectionDisabled(disablesAutocapitalization)
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .background(Color.white.opacity(0.66))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.7), lineWidth: 1)
        )
    }
}
