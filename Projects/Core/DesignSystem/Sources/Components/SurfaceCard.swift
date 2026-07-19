import SwiftUI

public struct SurfaceCard<Content: View>: View {
    let content: Content

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        content
            .background(.ultraThinMaterial)
            .background(Color.white.opacity(0.35))
            .clipShape(RoundedRectangle(cornerRadius: 22))
            .overlay(
                RoundedRectangle(cornerRadius: 22)
                    .stroke(Color.white.opacity(0.75), lineWidth: 1)
            )
            .shadow(color: MomentColor.ink.opacity(0.10), radius: 14, x: 0, y: 8)
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
