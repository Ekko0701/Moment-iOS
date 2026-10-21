import Foundation

/// 그룹 멤버 목록의 한 줄. 멤버의 최신 모먼트를 함께 담는다.
public struct SpaceMember: Sendable, Equatable, Identifiable {
    public let user: UserProfile
    public let role: MemberRole
    public let joinedAt: Date
    /// 이 멤버의 최신 모먼트. 없거나 나와 차단 관계면 nil
    public let latestMoment: Moment?

    public var id: UUID { user.id }

    public init(user: UserProfile, role: MemberRole, joinedAt: Date, latestMoment: Moment? = nil) {
        self.user = user
        self.role = role
        self.joinedAt = joinedAt
        self.latestMoment = latestMoment
    }
}
