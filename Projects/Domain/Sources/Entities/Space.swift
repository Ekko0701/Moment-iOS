import Foundation

public struct Space: Sendable, Equatable, Identifiable {
    public let id: UUID
    public let type: SpaceType
    public let name: String?
    public let maxMembers: Int
    public let status: String
    public let members: [UserProfile]
    public let createdAt: Date
    /// 이 스페이스에서 나의 역할
    public let myRole: MemberRole
    /// 이 스페이스의 새 모먼트 알림을 받는지 여부
    public let notificationsEnabled: Bool
    /// 나와 차단 관계를 제외한 다른 멤버의 최신 모먼트. 홈 카드에 쓴다
    public let latestMoment: Moment?

    public init(
        id: UUID,
        type: SpaceType,
        name: String? = nil,
        maxMembers: Int,
        status: String,
        members: [UserProfile],
        createdAt: Date,
        myRole: MemberRole = .member,
        notificationsEnabled: Bool = true,
        latestMoment: Moment? = nil
    ) {
        self.id = id
        self.type = type
        self.name = name
        self.maxMembers = maxMembers
        self.status = status
        self.members = members
        self.createdAt = createdAt
        self.myRole = myRole
        self.notificationsEnabled = notificationsEnabled
        self.latestMoment = latestMoment
    }

    public var isGroup: Bool { type == .group }
    public var isOwner: Bool { myRole == .owner }
    public var memberCount: Int { members.count }
    public var isFull: Bool { memberCount >= maxMembers }

    /// 1:1에서 나를 제외한 상대. 그룹이면 nil
    public func partner(excluding myId: UUID?) -> UserProfile? {
        guard type == .oneToOne else { return nil }
        return members.first { $0.id != myId }
    }
}
