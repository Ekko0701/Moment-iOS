import SwiftUI

public struct MomentColor {
    // MARK: - Core Monochrome (Light mode only per spec)
    // Note: Dark mode is not documented in the design spec.
    // Light mode is the canonical implementation.
    public static let ink = Color(red: 0.067, green: 0.176, blue: 0.306) // #112D4E (deep navy)
    public static let canvas = Color(red: 0.976, green: 0.968, blue: 0.968) // #F9F7F7 (cream background)
    public static let inverseCanvas = Color(red: 0.067, green: 0.176, blue: 0.306) // #112D4E
    public static let inverseInk = Color(red: 1.0, green: 1.0, blue: 1.0) // #ffffff

    // MARK: - Hairline & Surface Soft
    public static let hairline = Color(red: 0.859, green: 0.886, blue: 0.937) // #DBE2EF (soft blue)
    public static let hairlineSoft = Color(red: 0.910, green: 0.929, blue: 0.965) // #E8EDF6
    public static let surfaceSoft = Color(red: 0.859, green: 0.886, blue: 0.937) // #DBE2EF (soft blue)

    // MARK: - Pastel Color Blocks (unified to soft blue)
    public static let blockLime = Color(red: 0.859, green: 0.886, blue: 0.937) // #DBE2EF (soft blue)
    public static let blockLilac = Color(red: 0.859, green: 0.886, blue: 0.937) // #DBE2EF (soft blue)
    public static let blockCream = Color(red: 0.859, green: 0.886, blue: 0.937) // #DBE2EF (soft blue)
    public static let blockPink = Color(red: 0.859, green: 0.886, blue: 0.937) // #DBE2EF (soft blue)
    public static let blockMint = Color(red: 0.859, green: 0.886, blue: 0.937) // #DBE2EF (soft blue)
    public static let blockCoral = Color(red: 0.949, green: 0.780, blue: 0.737) // #F2C7BC (soft coral - error banner)
    public static let blockNavy = Color(red: 0.067, green: 0.176, blue: 0.306) // #112D4E

    // MARK: - Semantic & Accent
    public static let accentMagenta = Color(red: 0.247, green: 0.447, blue: 0.686) // #3F72AF (blue accent)
    public static let success = Color(red: 0.120, green: 0.651, blue: 0.290) // #1ea64a

    // MARK: - New Design Tokens
    public static let accent = Color(red: 0.247, green: 0.447, blue: 0.686) // #3F72AF (blue accent)
    public static let muted = Color(red: 0.486, green: 0.545, blue: 0.647) // #7C8BA5 (muted text)
    public static let surface = Color(red: 1.0, green: 1.0, blue: 1.0) // #FFFFFF (white card surface)

    // MARK: - Ambient Orb Colors
    public static let orbCoral = Color(red: 0.95, green: 0.62, blue: 0.50)      // soft coral orb
    public static let orbBlue = Color(red: 0.55, green: 0.68, blue: 0.88)       // blue orb
    public static let orbLavender = Color(red: 0.68, green: 0.65, blue: 0.90)   // lavender orb
    public static let orbYellow = Color(red: 0.97, green: 0.84, blue: 0.50)     // yellow orb

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
