import Dependencies
import Foundation

/// 그룹 스페이스 유스케이스 — 생성·코드 참여·멤버 관리·알림 설정.
public struct GroupUseCase: Sendable {
    @Dependency(\.spaceRepository) private var spaceRepository

    public init() {}

    public func create(name: String) async throws -> CreatedGroup {
        try await spaceRepository.createGroup(name: name.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    /// 공백을 지우고 대문자로 맞춘 코드로 참여한다
    public func join(code: String) async throws -> Space {
        let normalized = code.filter { !$0.isWhitespace }.uppercased()
        return try await spaceRepository.joinGroup(code: normalized)
    }

    public func inviteCode(spaceId: UUID) async throws -> GroupInviteCode {
        try await spaceRepository.groupInviteCode(spaceId: spaceId)
    }

    public func reissueInviteCode(spaceId: UUID) async throws -> GroupInviteCode {
        try await spaceRepository.reissueGroupInviteCode(spaceId: spaceId)
    }

    public func members(spaceId: UUID) async throws -> [SpaceMember] {
        try await spaceRepository.members(spaceId: spaceId)
    }

    public func removeMember(spaceId: UUID, userId: UUID) async throws {
        try await spaceRepository.removeMember(spaceId: spaceId, userId: userId)
    }

    public func setNotifications(spaceId: UUID, enabled: Bool) async throws {
        try await spaceRepository.setNotifications(spaceId: spaceId, enabled: enabled)
    }

    public func rename(spaceId: UUID, name: String) async throws {
        try await spaceRepository.rename(spaceId: spaceId, name: name)
    }

    public func leave(spaceId: UUID) async throws {
        try await spaceRepository.leave(spaceId: spaceId)
    }

    public func delete(spaceId: UUID) async throws {
        try await spaceRepository.deleteGroup(spaceId: spaceId)
    }
}

public extension DependencyValues {
    var groupUseCase: GroupUseCase {
        get { self[GroupUseCaseKey.self] }
        set { self[GroupUseCaseKey.self] = newValue }
    }
}

private enum GroupUseCaseKey: DependencyKey {
    static let liveValue = GroupUseCase()
}
