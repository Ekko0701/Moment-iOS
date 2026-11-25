import Foundation

/// 사진 위 글씨가 시작하는 모서리. 둘 다 왼쪽 정렬이다
public enum MomentTextPosition: String, Sendable, Equatable, CaseIterable {
    /// 왼쪽 위에서 시작해 아래로 이어진다
    case top = "TOP"
    /// 왼쪽 아래에서 시작해 위로 쌓인다
    case bottom = "BOTTOM"
}

/// 사진 위 글씨 색. 값은 서버와 주고받는 이름이고, 실제 색은 화면이 정한다
public enum MomentTextColor: String, Sendable, Equatable, CaseIterable {
    case white = "WHITE"
    case ink = "INK"
    case peach = "PEACH"
    case butter = "BUTTER"
    case lilac = "LILAC"
}

/// 사진 위에 글씨를 올리는 방식
public struct MomentTextStyle: Sendable, Equatable {
    public var position: MomentTextPosition
    public var color: MomentTextColor

    public init(position: MomentTextPosition = .top, color: MomentTextColor = .white) {
        self.position = position
        self.color = color
    }

    /// 위치·색을 고르지 않았을 때의 모습: 왼쪽 위, 흰색
    public static let standard = MomentTextStyle()
}
