import SwiftUI

public struct SurfaceCard<Content: View>: View {
    let content: Content

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        content
            .background(MomentColor.surface)
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(MomentColor.hairline, lineWidth: 1)
            )
            .shadow(color: MomentColor.ink.opacity(0.08), radius: 15, x: 0, y: 10)
    }
}

#Preview {
    ZStack {
        MomentColor.canvas.ignoresSafeArea()
        VStack(spacing: 20) {
            SurfaceCard {
                VStack(spacing: 12) {
                    Text("Card Title")
                        .font(.system(.headline, design: .default))
                        .foregroundColor(MomentColor.ink)
                    Text("This is example card content with surface styling")
                        .font(.body)
                        .foregroundColor(MomentColor.ink)
                }
                .padding(16)
            }
            Spacer()
        }
        .padding()
    }
}
