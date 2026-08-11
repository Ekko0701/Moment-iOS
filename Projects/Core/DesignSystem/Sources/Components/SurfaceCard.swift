import SwiftUI

public struct SurfaceCard<Content: View>: View {
    let content: Content

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        // 콘텐츠 카드는 글래스가 아닌 불투명 미니멀 서피스 (글래스는 크롬·인터랙티브 전용).
        // 그림자 대신 서피스 대비(light)와 헤어라인(dark)으로 구분 — GlassMinimal 시안.
        content
            .background(MomentColor.surfaceSoft)
            .clipShape(RoundedRectangle(cornerRadius: 22))
            .overlay(
                RoundedRectangle(cornerRadius: 22)
                    .stroke(MomentColor.surfaceStroke, lineWidth: 1)
            )
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
