import SwiftUI
import CoreKit

public struct MomentTypography {
    // MARK: - Display / Hero Sizes
    // displayXL: 40pt .light tracking -1.6 (hero wordmark/onboarding)
    public static let displayXL = Font.pretendard(size: 40, weight: .thin)

    // displayLG: 30pt .light tracking -0.9
    public static let displayLG = Font.pretendard(size: 30, weight: .thin)

    // MARK: - Headlines
    // headline: 20pt .semibold tracking -0.26
    public static let headline = Font.pretendard(size: 20, weight: .semibold)

    // subhead: 20pt .light tracking -0.26
    public static let subhead = Font.pretendard(size: 20, weight: .light)

    // MARK: - Card & Body Hierarchy
    // cardTitle: 17pt .bold (pricing/card titles)
    public static let cardTitle = Font.pretendard(size: 17, weight: .bold)

    // bodyLG: 17pt .regular tracking -0.14 (lead body/labels)
    public static let bodyLG = Font.pretendard(size: 17, weight: .regular)

    // body: 15pt .regular tracking -0.2 (default body)
    public static let body = Font.pretendard(size: 15, weight: .regular)

    // bodySM: 13pt .regular (card body, list items)
    public static let bodySM = Font.pretendard(size: 13, weight: .regular)

    // MARK: - Button/Link
    // button: 17pt .medium tracking -0.1 (pill buttons)
    public static let button = Font.pretendard(size: 17, weight: .medium)

    // link: 17pt .medium tracking -0.1 (inline link emphasis)
    public static let link = Font.pretendard(size: 17, weight: .medium)

    // MARK: - Eyebrow & Caption (small labels)
    // eyebrow: 13pt .regular tracking +1.2 (always UPPERCASE, 기본 폰트)
    public static let eyebrow = Font.pretendard(size: 13, weight: .regular)

    // caption: 11pt .regular tracking +0.8 (always UPPERCASE, 기본 폰트)
    public static let caption = Font.pretendard(size: 11, weight: .regular)

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
