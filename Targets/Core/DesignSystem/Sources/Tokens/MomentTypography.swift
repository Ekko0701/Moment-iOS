import SwiftUI

public struct MomentTypography {
    // MARK: - Display / Hero Sizes
    // displayXL: 40pt .light tracking -1.6 (hero wordmark/onboarding)
    public static let displayXL = Font.system(size: 40, weight: .thin, design: .default)

    // displayLG: 30pt .light tracking -0.9
    public static let displayLG = Font.system(size: 30, weight: .thin, design: .default)

    // MARK: - Headlines
    // headline: 20pt .semibold tracking -0.26
    public static let headline = Font.system(size: 20, weight: .semibold, design: .default)

    // subhead: 20pt .light tracking -0.26
    public static let subhead = Font.system(size: 20, weight: .light, design: .default)

    // MARK: - Card & Body Hierarchy
    // cardTitle: 17pt .bold (pricing/card titles)
    public static let cardTitle = Font.system(size: 17, weight: .bold, design: .default)

    // bodyLG: 17pt .regular tracking -0.14 (lead body/labels)
    public static let bodyLG = Font.system(size: 17, weight: .regular, design: .default)

    // body: 15pt .regular tracking -0.2 (default body)
    public static let body = Font.system(size: 15, weight: .regular, design: .default)

    // bodySM: 13pt .regular (card body, list items)
    public static let bodySM = Font.system(size: 13, weight: .regular, design: .default)

    // MARK: - Button/Link
    // button: 17pt .medium tracking -0.1 (pill buttons)
    public static let button = Font.system(size: 17, weight: .medium, design: .default)

    // link: 17pt .medium tracking -0.1 (inline link emphasis)
    public static let link = Font.system(size: 17, weight: .medium, design: .default)

    // MARK: - Monospace (Eyebrow & Caption)
    // eyebrow: 13pt monospaced .regular tracking +1.2 (always UPPERCASE)
    public static let eyebrow = Font.system(size: 13, weight: .regular, design: .monospaced)

    // caption: 11pt monospaced .regular tracking +0.8 (always UPPERCASE)
    public static let caption = Font.system(size: 11, weight: .regular, design: .monospaced)

    // MARK: - View Extension Helper
    // Use: .momentType(.body), .momentType(.headline), etc.
}

// MARK: - View Extension for easy application
extension View {
    public func momentType(_ style: MomentTypographyStyle) -> some View {
        self.font(style.font)
            .tracking(style.letterSpacing)
    }
}

public enum MomentTypographyStyle {
    case displayXL
    case displayLG
    case headline
    case subhead
    case cardTitle
    case bodyLG
    case body
    case bodySM
    case button
    case link
    case eyebrow
    case caption

    var font: Font {
        switch self {
        case .displayXL: return MomentTypography.displayXL
        case .displayLG: return MomentTypography.displayLG
        case .headline: return MomentTypography.headline
        case .subhead: return MomentTypography.subhead
        case .cardTitle: return MomentTypography.cardTitle
        case .bodyLG: return MomentTypography.bodyLG
        case .body: return MomentTypography.body
        case .bodySM: return MomentTypography.bodySM
        case .button: return MomentTypography.button
        case .link: return MomentTypography.link
        case .eyebrow: return MomentTypography.eyebrow
        case .caption: return MomentTypography.caption
        }
    }

    var letterSpacing: CGFloat {
        switch self {
        case .displayXL: return -1.6
        case .displayLG: return -0.9
        case .headline, .subhead: return -0.26
        case .bodyLG: return -0.14
        case .body: return -0.2
        case .bodySM: return 0
        case .button, .link: return -0.1
        case .eyebrow: return 1.2
        case .caption: return 0.8
        case .cardTitle: return 0
        }
    }
}
