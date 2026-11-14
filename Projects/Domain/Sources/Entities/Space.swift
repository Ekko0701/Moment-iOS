import Foundation

public struct Space: Sendable, Equatable, Identifiable {
    public var id: UUID
    public var type: SpaceType
    public var name: String?
    public var maxMembers: Int
    public var status: String
    public var members: [UserProfile]
    public var createdAt: Date
    /// 이 스페이스에서 나의 역할
    public var myRole: MemberRole
    /// 이 스페이스의 새 모먼트 알림을 받는지 여부
    public var notificationsEnabled: Bool
    /// 나와 차단 관계를 제외한 다른 멤버의 최신 모먼트. 홈 카드에 쓴다
    public var latestMoment: Moment?
    /// 내가 방장인 그룹에 들어온 대기 중 참여 요청 수. 그 밖에는 0
    public var pendingJoinRequestCount: Int

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
        latestMoment: Moment? = nil,
        pendingJoinRequestCount: Int = 0
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
        self.pendingJoinRequestCount = pendingJoinRequestCount
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

public extension Space {
    /// 연결 후 함께한 일수. 연결한 날이 1일차이고, 달력 날짜가 바뀔 때마다 하나씩 늘어난다
    func daysTogether(now: Date = Date(), calendar: Calendar = .current) -> Int {
        let start = calendar.startOfDay(for: createdAt)
        let today = calendar.startOfDay(for: now)
        return (calendar.dateComponents([.day], from: start, to: today).day ?? 0) + 1
    }
}

public extension Space {
    /// 화면에 보일 이름. 붙인 이름이 우선이고, 없으면 1:1은 상대 닉네임, 그룹은 "그룹"으로 대신한다.
    func displayName(myUserId: UUID?) -> String {
        if let name = name?.trimmingCharacters(in: .whitespaces), !name.isEmpty { return name }
        if isGroup { return "그룹" }
        if let partner = partner(excluding: myUserId) { return "\(partner.nickname)님과의 스페이스" }
        return "우리 둘의 스페이스"
    }
}
