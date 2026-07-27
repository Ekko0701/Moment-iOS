import SwiftUI

// MARK: - Liquid Glass Surface (iOS 26 네이티브 + 하위 폴백)

/// Lux 글래스 서피스 스타일.
/// iOS 26+에서는 시스템 Liquid Glass(`.glassEffect`)를 사용해 주변 콘텐츠의
/// 빛·색을 실시간 반사하고, 그 이하에서는 ultraThinMaterial + 토큰 조합으로 근사한다.
public struct GlassSurfaceModifier: ViewModifier {
    let cornerRadius: CGFloat
    let isInteractive: Bool

    public func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content
                .glassEffect(
                    isInteractive ? .regular.interactive() : .regular,
                    in: .rect(cornerRadius: cornerRadius)
                )
        } else {
            content
                .background(.ultraThinMaterial)
                .background(MomentColor.glassFill)
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(MomentColor.glassStroke, lineWidth: 1)
                )
        }
    }
}

/// 캡슐형 글래스 (필 버튼, SpacePill 등)
public struct GlassCapsuleModifier: ViewModifier {
    let isInteractive: Bool

    public func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content
                .glassEffect(isInteractive ? .regular.interactive() : .regular, in: .capsule)
        } else {
            content
                .background(.ultraThinMaterial)
                .background(MomentColor.glassFill)
                .clipShape(Capsule())
                .overlay(Capsule().stroke(MomentColor.glassStroke, lineWidth: 1))
        }
    }
}

extension View {
    /// 라운드 사각 Liquid Glass 서피스. 카드·입력 필드 등 정적 서피스에 사용.
    /// `isInteractive`는 터치에 반응해야 하는 요소(버튼)에만 켠다.
    public func glassSurface(cornerRadius: CGFloat = 24, isInteractive: Bool = false) -> some View {
        modifier(GlassSurfaceModifier(cornerRadius: cornerRadius, isInteractive: isInteractive))
    }

    /// 캡슐 Liquid Glass 서피스. 필 버튼·칩에 사용.
    public func glassCapsule(isInteractive: Bool = false) -> some View {
        modifier(GlassCapsuleModifier(isInteractive: isInteractive))
    }
}

// MARK: - Xcode Previews

#Preview("글래스 서피스") {
    ZStack {
        MomentColor.canvas.ignoresSafeArea()
        OrbBackground.home().ignoresSafeArea()
        VStack(spacing: 24) {
            Text("글래스 카드")
                .foregroundColor(MomentColor.ink)
                .padding(24)
                .glassSurface()

            Text("글래스 캡슐")
                .foregroundColor(MomentColor.ink)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .glassCapsule(isInteractive: true)
        }
    }
}
