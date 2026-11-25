import SwiftUI
import UIKit

/// 앱과 위젯이 함께 쓰는 Pretendard 글꼴.
/// 글꼴 파일은 앱·위젯 번들에 담겨 Info.plist의 UIAppFonts로 등록된다.
/// 파일이 없는 환경(Xcode 미리보기, 모듈 단위 테스트)에서는 시스템 글꼴로 대신 그려진다.
public enum Pretendard {
    /// 굵기에 맞는 정적 글꼴의 PostScript 이름. 담지 않은 굵기는 가장 가까운 것으로 맞춘다
    public static func fontName(for weight: Font.Weight) -> String {
        switch weight {
        case .medium: return "Pretendard-Medium"
        case .semibold: return "Pretendard-SemiBold"
        case .bold, .heavy, .black: return "Pretendard-Bold"
        default: return "Pretendard-Regular"
        }
    }

    public static func fontName(for weight: UIFont.Weight) -> String {
        switch weight {
        case .medium: return "Pretendard-Medium"
        case .semibold: return "Pretendard-SemiBold"
        case .bold, .heavy, .black: return "Pretendard-Bold"
        default: return "Pretendard-Regular"
        }
    }

    /// 텍스트 스타일의 기본 크기(Large 설정 기준). Dynamic Type은 이 크기에서 비례해 커진다
    static func baseSize(for style: Font.TextStyle) -> CGFloat {
        switch style {
        case .largeTitle: return 34
        case .title: return 28
        case .title2: return 22
        case .title3: return 20
        case .headline: return 17
        case .body: return 17
        case .callout: return 16
        case .subheadline: return 15
        case .footnote: return 13
        case .caption: return 12
        case .caption2: return 11
        @unknown default: return 17
        }
    }
}

public extension Font {
    /// 크기가 고정된 Pretendard. `Font.system(size:weight:)` 자리에 쓴다
    static func pretendard(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .custom(Pretendard.fontName(for: weight), fixedSize: size)
    }

    /// 텍스트 스타일을 따르는 Pretendard. 사용자의 글자 크기 설정에 맞춰 커진다
    static func pretendard(_ style: Font.TextStyle, weight: Font.Weight = .regular) -> Font {
        .custom(Pretendard.fontName(for: weight), size: Pretendard.baseSize(for: style), relativeTo: style)
    }
}

public extension UIFont {
    /// UIKit 외형(내비게이션 바, 탭 바)에 쓰는 Pretendard. 글꼴이 등록돼 있지 않으면 시스템 글꼴
    static func pretendard(size: CGFloat, weight: UIFont.Weight = .regular) -> UIFont {
        UIFont(name: Pretendard.fontName(for: weight), size: size) ?? .systemFont(ofSize: size, weight: weight)
    }
}
