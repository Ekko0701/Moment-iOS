import SwiftUI

public struct MomentColor {
    // MARK: - Brand Colors (Warm Coral/Peach)
    public static let primary = Color(red: 0.98, green: 0.48, blue: 0.40) // Coral
    public static let primaryLight = Color(red: 1.0, green: 0.64, blue: 0.56) // Light Coral
    public static let primaryDark = Color(red: 0.85, green: 0.30, blue: 0.15) // Dark Coral

    // MARK: - Semantic Colors
    public static let background = Color(UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark
            ? UIColor(red: 0.11, green: 0.11, blue: 0.12, alpha: 1.0)
            : UIColor(red: 0.98, green: 0.98, blue: 0.99, alpha: 1.0)
    })

    public static let surface = Color(UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark
            ? UIColor(red: 0.17, green: 0.17, blue: 0.18, alpha: 1.0)
            : UIColor.white
    })

    public static let text = Color(UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark
            ? UIColor(red: 0.95, green: 0.95, blue: 0.96, alpha: 1.0)
            : UIColor(red: 0.11, green: 0.11, blue: 0.12, alpha: 1.0)
    })

    public static let textSecondary = Color(UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark
            ? UIColor(red: 0.70, green: 0.70, blue: 0.72, alpha: 1.0)
            : UIColor(red: 0.45, green: 0.45, blue: 0.47, alpha: 1.0)
    })

    public static let border = Color(UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark
            ? UIColor(red: 0.25, green: 0.25, blue: 0.27, alpha: 1.0)
            : UIColor(red: 0.85, green: 0.85, blue: 0.87, alpha: 1.0)
    })

    public static let success = Color(red: 0.34, green: 0.78, blue: 0.50)
    public static let error = Color(red: 0.95, green: 0.26, blue: 0.21)
    public static let warning = Color(red: 1.0, green: 0.68, blue: 0.28)
}
