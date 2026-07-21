import SwiftUI

public struct MomentColor {
    // MARK: - Core Monochrome (Warm Paper Theme - Design F)
    public static let ink = Color(red: 0.17, green: 0.155, blue: 0.13) // #2B2721 (warm ink)
    public static let canvas = Color(red: 0.965, green: 0.945, blue: 0.905) // #F6F1E7 (warm paper)
    public static let inverseCanvas = Color(red: 0.17, green: 0.155, blue: 0.13) // #2B2721
    public static let inverseInk = Color(red: 1.0, green: 1.0, blue: 1.0) // #ffffff

    // MARK: - Hairline & Surface Soft
    public static let hairline = Color(red: 0.90, green: 0.88, blue: 0.84) // #E5E1D7 (warm gray)
    public static let hairlineSoft = Color(red: 0.93, green: 0.915, blue: 0.88) // #EDEBE0 (warm gray soft)
    public static let surfaceSoft = Color(red: 0.93, green: 0.905, blue: 0.855) // #EDEA7A (warm paper darker)

    // MARK: - Pastel Color Blocks (warm palette)
    public static let blockLime = Color(red: 0.93, green: 0.905, blue: 0.855) // #EDEA5A (warm paper darker)
    public static let blockLilac = Color(red: 0.93, green: 0.905, blue: 0.855) // #EDEA5A (warm paper darker)
    public static let blockCream = Color(red: 0.93, green: 0.905, blue: 0.855) // #EDEA5A (warm paper darker)
    public static let blockPink = Color(red: 0.93, green: 0.905, blue: 0.855) // #EDEA5A (warm paper darker)
    public static let blockMint = Color(red: 0.93, green: 0.905, blue: 0.855) // #EDEA5A (warm paper darker)
    public static let blockCoral = Color(red: 0.95, green: 0.78, blue: 0.72) // #F2C7B8 (warm coral - error banner)
    public static let blockNavy = Color(red: 0.17, green: 0.155, blue: 0.13) // #2B2721 (warm ink)

    // MARK: - Semantic & Accent
    public static let accentMagenta = Color(red: 0.17, green: 0.155, blue: 0.13) // #2B2721 (warm ink as accent)
    public static let success = Color(red: 0.120, green: 0.651, blue: 0.290) // #1ea64a
    public static let destructive = Color(red: 0.78, green: 0.29, blue: 0.24) // #C74A3D (warm red — 연결 해제/계정 삭제)

    // MARK: - New Design Tokens
    public static let accent = Color(red: 0.17, green: 0.155, blue: 0.13) // #2B2721 (warm ink as accent)
    public static let muted = Color(red: 0.54, green: 0.52, blue: 0.47) // #8A8579 (warm gray muted)
    public static let surface = Color(red: 1.0, green: 1.0, blue: 1.0) // #FFFFFF (white card surface)

    // MARK: - Ambient Orb Colors (Design F)
    public static let orbCoral = Color(red: 0.95, green: 0.48, blue: 0.32)      // coral orb
    public static let orbBlue = Color(red: 0.36, green: 0.60, blue: 0.94)       // blue orb
    public static let orbLavender = Color(red: 0.63, green: 0.58, blue: 0.92)   // lavender orb
    public static let orbYellow = Color(red: 0.98, green: 0.78, blue: 0.28)     // yellow orb

    // MARK: - Composite aliases for readability
    public static let primary = ink
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

    // MARK: - Color Block rotation for feed (lime → cream → mint → pink → lilac)
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
            // Navy block uses inverse ink (white text)
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
