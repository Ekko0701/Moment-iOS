import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Adaptive Color Helper

extension Color {
    /// 라이트/다크 모드에 따라 다른 색을 반환하는 적응형 컬러.
    /// LightLux/DarkLux 시안의 테마 토큰 전환에 사용한다.
    init(light: Color, dark: Color) {
        #if canImport(UIKit)
        self.init(uiColor: UIColor { trait in
            trait.userInterfaceStyle == .dark ? UIColor(dark) : UIColor(light)
        })
        #else
        self = light
        #endif
    }
}

public struct MomentColor {
    // MARK: - Core (LightLux 크림/잉크 ↔ DarkLux 니어블랙/오프화이트)

    /// 화면 바탕 — light: 웜 크림, dark: 니어블랙
    public static let canvas = Color(
        light: Color(red: 0.972, green: 0.952, blue: 0.925),
        dark: Color(red: 0.055, green: 0.05, blue: 0.055)
    )

    /// 본문 텍스트/프라이머리 — light: 웜 잉크, dark: 오프화이트
    public static let ink = Color(
        light: Color(red: 0.16, green: 0.14, blue: 0.12),
        dark: Color(red: 0.97, green: 0.96, blue: 0.95)
    )

    /// canvas의 반전 (프라이머리 버튼 배경 등)
    public static let inverseCanvas = Color(
        light: Color(red: 0.11, green: 0.10, blue: 0.09),
        dark: Color(red: 0.97, green: 0.96, blue: 0.95)
    )

    /// ink의 반전 (프라이머리 버튼 텍스트 등)
    public static let inverseInk = Color(
        light: Color(red: 0.98, green: 0.97, blue: 0.96),
        dark: Color(red: 0.08, green: 0.07, blue: 0.08)
    )

    // MARK: - Hairline & Surface

    public static let hairline = Color(
        light: Color(red: 0.90, green: 0.88, blue: 0.84),
        dark: Color(red: 0.22, green: 0.21, blue: 0.21)
    )
    public static let hairlineSoft = Color(
        light: Color(red: 0.93, green: 0.915, blue: 0.88),
        dark: Color(red: 0.17, green: 0.16, blue: 0.16)
    )
    public static let surfaceSoft = Color(
        light: Color(red: 0.93, green: 0.905, blue: 0.855),
        dark: Color(red: 0.14, green: 0.13, blue: 0.13)
    )
    public static let surface = Color(
        light: .white,
        dark: Color(red: 0.13, green: 0.12, blue: 0.125)
    )
    public static let muted = Color(
        light: Color(red: 0.54, green: 0.52, blue: 0.47),
        dark: Color(red: 0.62, green: 0.60, blue: 0.58)
    )

    // MARK: - Glass Tokens (LightLux 화이트 프로스티드 ↔ DarkLux 다크 글래스)

    /// 글래스 서피스 필 — light: white 72%, dark: white 8%
    public static let glassFill = Color(
        light: Color.white.opacity(0.72),
        dark: Color.white.opacity(0.08)
    )
    /// 글래스 보더 — light: 잉크 8%, dark: white 14%
    public static let glassStroke = Color(
        light: Color(red: 0.16, green: 0.14, blue: 0.12).opacity(0.08),
        dark: Color.white.opacity(0.14)
    )
    /// 사진(석양 카드) 위 오버레이 칩 — light: 화이트 프로스티드, dark: 다크 글래스
    public static let overlayGlassFill = Color(
        light: Color.white.opacity(0.84),
        dark: Color(red: 0.08, green: 0.06, blue: 0.08).opacity(0.32)
    )
    public static let overlayGlassStroke = Color(
        light: Color.white.opacity(0.6),
        dark: Color.white.opacity(0.16)
    )
    /// 그림자 틴트 — light: 웜 브라운, dark: 블랙 (ink 기반이면 다크에서 흰 그림자가 되므로 분리)
    public static let shadowTint = Color(
        light: Color(red: 0.35, green: 0.22, blue: 0.12),
        dark: Color.black
    )

    // MARK: - Semantic & Accent (코럴 — Lux 시안 액센트)

    /// 코럴 액센트 (D+n, 활성 탭, 닉네임 변경 등) — light: 딥 코럴, dark: 라이트 코럴
    public static let accent = Color(
        light: Color(red: 0.93, green: 0.45, blue: 0.30),
        dark: Color(red: 0.99, green: 0.58, blue: 0.44)
    )
    public static let accentMagenta = accent
    public static let success = Color(red: 0.120, green: 0.651, blue: 0.290)
    /// 파괴적 액션 (연결 해제/계정 삭제)
    public static let destructive = Color(
        light: Color(red: 0.78, green: 0.29, blue: 0.24),
        dark: Color(red: 0.96, green: 0.45, blue: 0.42)
    )

    // MARK: - Pastel Color Blocks (텍스트 모먼트 배경 등 — 양 테마 서피스 톤)

    public static let blockLime = surfaceSoft
    public static let blockLilac = surfaceSoft
    public static let blockCream = surfaceSoft
    public static let blockPink = surfaceSoft
    public static let blockMint = surfaceSoft
    public static let blockCoral = Color(
        light: Color(red: 0.95, green: 0.78, blue: 0.72),
        dark: Color(red: 0.45, green: 0.24, blue: 0.20)
    )
    public static let blockNavy = Color(
        light: Color(red: 0.17, green: 0.155, blue: 0.13),
        dark: Color(red: 0.13, green: 0.12, blue: 0.125)
    )

    // MARK: - Ambient Orb Colors (LightLux 피치/앰버/라벤더 ↔ DarkLux 코럴/앰버/라벤더)

    public static let orbCoral = Color(
        light: Color(red: 0.99, green: 0.70, blue: 0.53),
        dark: Color(red: 0.97, green: 0.40, blue: 0.30)
    )
    public static let orbYellow = Color(
        light: Color(red: 0.99, green: 0.84, blue: 0.55),
        dark: Color(red: 0.99, green: 0.66, blue: 0.32)
    )
    public static let orbLavender = Color(
        light: Color(red: 0.80, green: 0.76, blue: 0.97),
        dark: Color(red: 0.63, green: 0.58, blue: 0.92)
    )
    public static let orbBlue = Color(
        light: Color(red: 0.36, green: 0.60, blue: 0.94),
        dark: Color(red: 0.30, green: 0.48, blue: 0.80)
    )

    // MARK: - Composite aliases

    public static let primary = inverseCanvas
    public static let onPrimary = inverseInk

    // MARK: - Utility: Hex initializer

    public static func hex(_ hex: String) -> Color {
        let hex = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        guard hex.count == 6,
              let rgbValue = UInt32(hex, radix: 16) else {
            return .clear
        }
        let red = Double((rgbValue >> 16) & 0xFF) / 255.0
        let green = Double((rgbValue >> 8) & 0xFF) / 255.0
        let blue = Double(rgbValue & 0xFF) / 255.0
        return Color(red: red, green: green, blue: blue)
    }

    // MARK: - Color Block rotation for feed

    public enum BlockColor {
        case lime, lilac, cream, pink, mint, coral, navy

        public var color: Color {
            switch self {
            case .lime: return blockLime
            case .lilac: return blockLilac
            case .cream: return blockCream
            case .pink: return blockPink
            case .mint: return blockMint
            case .coral: return blockCoral
            case .navy: return blockNavy
            }
        }

        public var textColor: Color {
            switch self {
            case .navy: return inverseInk
            default: return ink
            }
        }

        /// Returns block color for a given feed index (rotates through palette)
        public static func forFeedIndex(_ index: Int) -> BlockColor {
            let palette: [BlockColor] = [.lime, .cream, .mint, .pink, .lilac]
            return palette[index % palette.count]
        }
    }
}
