import Foundation

public struct Spacing {
    // MARK: - Base Units (per spec)
    public static let hair: CGFloat = 1 // 1px borders
    public static let xxs: CGFloat = 4
    public static let xs: CGFloat = 8
    public static let sm: CGFloat = 12
    public static let md: CGFloat = 16
    public static let lg: CGFloat = 24
    public static let xl: CGFloat = 32
    public static let xxl: CGFloat = 48

    // MARK: - Section Spacing (mobile adapted from 96px spec)
    // Desktop: 96px, Mobile: 64px for tight viewport breathing room
    public static let section: CGFloat = 64

    // MARK: - Radius System
    public enum Radius {
        public static let xs: CGFloat = 2 // Anchor decoration corners
        public static let sm: CGFloat = 6 // Small chips, sub-nav tabs
        public static let md: CGFloat = 8 // Form inputs, list items, image frames
        public static let lg: CGFloat = 24 // Pricing cards, color-block sections
        public static let xl: CGFloat = 32 // Hero feature panels
        public static let pill: CGFloat = 50 // Text CTAs
        public static let full: CGFloat = 9999 // Circular icon buttons
    }
}
