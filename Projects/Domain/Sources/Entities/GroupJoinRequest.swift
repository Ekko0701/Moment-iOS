import Foundation

public enum JoinRequestStatus: String, Sendable, Equatable {
    case pending = "PENDING"
    case approved = "APPROVED"
    case rejected = "REJECTED"
    case canceled = "CANCELED"
}

/// 내가 보낸 그룹 참여 요청. 방장이 수락하면 그룹이 내 스페이스 목록에 들어온다.
public struct GroupJoinRequest: Sendable, Equatable, Identifiable {
    public let id: UUID
    public let spaceId: UUID
    public let spaceName: String
    public let status: JoinRequestStatus
    public let createdAt: Date

    public init(id: UUID, spaceId: UUID, spaceName: String, status: JoinRequestStatus, createdAt: Date) {
        self.id = id
        self.spaceId = spaceId
        self.spaceName = spaceName
        self.status = status
        self.createdAt = createdAt
    }
}

/// 방장에게 보이는 대기 중 참여 요청
public struct PendingJoinRequest: Sendable, Equatable, Identifiable {
    public let id: UUID
    public let user: UserProfile
    public let createdAt: Date

    public init(id: UUID, user: UserProfile, createdAt: Date) {
        self.id = id
        self.user = user
        self.createdAt = createdAt
    }
}
