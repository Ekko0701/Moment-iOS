import SwiftUI

public struct MomentColor {
    // MARK: - Core Monochrome (Light mode only per spec)
    // Note: Dark mode is not documented in the design spec.
    // Light mode is the canonical implementation.
    public static let ink = Color(red: 0.0, green: 0.0, blue: 0.0) // #000000
    public static let canvas = Color(red: 1.0, green: 1.0, blue: 1.0) // #ffffff
    public static let inverseCanvas = Color(red: 0.0, green: 0.0, blue: 0.0) // #000000
    public static let inverseInk = Color(red: 1.0, green: 1.0, blue: 1.0) // #ffffff

    // MARK: - Hairline & Surface Soft
    public static let hairline = Color(red: 0.9, green: 0.9, blue: 0.9) // #e6e6e6
    public static let hairlineSoft = Color(red: 0.945, green: 0.945, blue: 0.945) // #f1f1f1
    public static let surfaceSoft = Color(red: 0.969, green: 0.969, blue: 0.961) // #f7f7f5

    // MARK: - Pastel Color Blocks
    public static let blockLime = Color(red: 0.863, green: 0.933, blue: 0.694) // #dceeb1
    public static let blockLilac = Color(red: 0.773, green: 0.690, blue: 0.957) // #c5b0f4
    public static let blockCream = Color(red: 0.957, green: 0.933, blue: 0.839) // #f4ecd6
    public static let blockPink = Color(red: 0.937, green: 0.835, blue: 0.835) // #efd4d4
    public static let blockMint = Color(red: 0.784, green: 0.902, blue: 0.804) // #c8e6cd
    public static let blockCoral = Color(red: 0.953, green: 0.788, blue: 0.714) // #f3c9b6
    public static let blockNavy = Color(red: 0.122, green: 0.114, blue: 0.239) // #1f1d3d

    // MARK: - Semantic & Accent
    public static let accentMagenta = Color(red: 1.0, green: 0.239, blue: 0.545) // #ff3d8b
    public static let success = Color(red: 0.120, green: 0.651, blue: 0.290) // #1ea64a

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
