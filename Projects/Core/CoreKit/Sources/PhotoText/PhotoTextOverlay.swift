import SwiftUI

/// 사진 위 글씨가 시작하는 모서리. 값은 서버·위젯 저장소와 주고받는 이름이다
public enum PhotoTextPosition: String, Sendable, Codable, CaseIterable {
    case top = "TOP"
    case bottom = "BOTTOM"

    /// 이름이 없거나 모르는 값이면 왼쪽 위
    public init(name: String?) {
        self = name.flatMap(Self.init(rawValue:)) ?? .top
    }

    /// 보낸 사람·시간 표시는 글씨와 겹치지 않게 반대쪽 모서리에 둔다
    public var opposite: PhotoTextPosition { self == .top ? .bottom : .top }

    public var alignment: Alignment { self == .top ? .topLeading : .bottomLeading }
}

/// 사진 위 글씨 색
public enum PhotoTextColor: String, Sendable, Codable, CaseIterable {
    case white = "WHITE"
    case ink = "INK"
    case peach = "PEACH"
    case butter = "BUTTER"
    case lilac = "LILAC"

    /// 이름이 없거나 모르는 값이면 흰색
    public init(name: String?) {
        self = name.flatMap(Self.init(rawValue:)) ?? .white
    }

    public var color: Color {
        switch self {
        case .white: return .white
        case .ink: return Color(red: 0.110, green: 0.110, blue: 0.118)
        case .peach: return Color(red: 0.988, green: 0.702, blue: 0.529)
        case .butter: return Color(red: 1.0, green: 0.839, blue: 0.420)
        case .lilac: return Color(red: 0.800, green: 0.761, blue: 0.969)
        }
    }

    /// 색 고르기 버튼을 VoiceOver가 읽는 이름
    public var label: String {
        switch self {
        case .white: return "흰색"
        case .ink: return "검정"
        case .peach: return "살구"
        case .butter: return "노랑"
        case .lilac: return "라일락"
        }
    }

    /// 어두운 글씨는 밝은 그림자를 쓰고 사진을 어둡게 깔지 않는다
    var isDark: Bool { self == .ink }
}

/// 사진 위에 올리는 글씨. 배경 없이 그림자만 넣고, 글씨 쪽 사진 가장자리를 옅게 어둡게 해 밝은 사진에서도 읽히게 한다.
/// 사진과 같은 크기로 겹쳐 쓴다: `photo.overlay { PhotoTextOverlay(...) }`
public struct PhotoTextOverlay: View {
    let text: String
    let position: PhotoTextPosition
    let color: PhotoTextColor
    let fontSize: CGFloat?
    let lineLimit: Int

    /// fontSize를 비우면 사진 폭에 비례한 크기로 그린다
    public init(
        text: String,
        position: PhotoTextPosition,
        color: PhotoTextColor,
        fontSize: CGFloat? = nil,
        lineLimit: Int = 6
    ) {
        self.text = text
        self.position = position
        self.color = color
        self.fontSize = fontSize
        self.lineLimit = lineLimit
    }

    /// 서버·위젯 저장소의 이름 값으로 만든다. 이름이 없으면 왼쪽 위·흰색
    public init(
        text: String,
        positionName: String?,
        colorName: String?,
        fontSize: CGFloat? = nil,
        lineLimit: Int = 6
    ) {
        self.init(
            text: text,
            position: PhotoTextPosition(name: positionName),
            color: PhotoTextColor(name: colorName),
            fontSize: fontSize,
            lineLimit: lineLimit
        )
    }

    public var body: some View {
        GeometryReader { proxy in
            let metrics = PhotoTextMetrics(photoWidth: proxy.size.width, fontSize: fontSize)
            ZStack(alignment: position.alignment) {
                PhotoTextScrim(position: position, color: color)

                Text(text)
                    .photoTextStyle(color: color, fontSize: metrics.fontSize)
                    .lineLimit(lineLimit)
                    .padding(.leading, metrics.inset)
                    .padding(.vertical, metrics.inset)
                    .padding(.trailing, metrics.trailingInset)
            }
            .frame(width: proxy.size.width, height: proxy.size.height, alignment: position.alignment)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(text)
    }
}

/// 글씨 쪽 가장자리에 까는 옅은 어둠. 어두운 글씨에는 깔지 않는다
public struct PhotoTextScrim: View {
    let position: PhotoTextPosition
    let color: PhotoTextColor

    public init(position: PhotoTextPosition, color: PhotoTextColor) {
        self.position = position
        self.color = color
    }

    public var body: some View {
        if color.isDark {
            Color.clear
        } else {
            LinearGradient(
                stops: [
                    .init(color: .black.opacity(0.42), location: 0),
                    .init(color: .clear, location: 0.45),
                ],
                startPoint: position == .top ? .top : .bottom,
                endPoint: position == .top ? .bottom : .top
            )
            .allowsHitTesting(false)
        }
    }
}

/// 사진 폭에 맞춘 글씨 크기와 여백
public struct PhotoTextMetrics: Sendable, Equatable {
    public let fontSize: CGFloat
    public let inset: CGFloat
    public let trailingInset: CGFloat

    /// 편집 화면(폭 370pt)에서 26pt가 되는 비율
    static let fontScale: CGFloat = 0.07

    public init(photoWidth: CGFloat, fontSize: CGFloat? = nil) {
        let size = fontSize ?? min(max(photoWidth * Self.fontScale, 12), 30)
        self.fontSize = size
        self.inset = max(photoWidth * 0.045, 10)
        self.trailingInset = max(photoWidth * 0.11, 16)
    }
}

public extension View {
    /// 사진 위 글씨의 글꼴·색·그림자. 편집 화면의 입력 칸도 같은 모습으로 보이게 함께 쓴다
    func photoTextStyle(color: PhotoTextColor, fontSize: CGFloat) -> some View {
        self
            .font(.pretendard(size: fontSize, weight: .bold))
            .tracking(-0.3)
            .foregroundStyle(color.color)
            .multilineTextAlignment(.leading)
            .shadow(
                color: color.isDark ? .white.opacity(0.55) : .black.opacity(0.45),
                radius: color.isDark ? 1.5 : 2,
                x: 0,
                y: 1
            )
    }
}
