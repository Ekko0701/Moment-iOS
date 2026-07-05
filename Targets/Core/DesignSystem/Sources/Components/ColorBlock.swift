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
    @State private var isFocused = false

    public init(_ placeholder: String, text: Binding<String>) {
        self.placeholder = placeholder
        self._text = text
    }

    public var body: some View {
        TextField(placeholder, text: $text)
            .font(MomentTypography.body)
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(MomentColor.canvas)
            .border(isFocused ? MomentColor.ink : MomentColor.hairline, width: 1)
            .cornerRadius(Spacing.Radius.md)
    }
}
