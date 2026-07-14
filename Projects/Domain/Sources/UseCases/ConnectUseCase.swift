import Dependencies
import Foundation

/// 연결(초대) 유스케이스.
public struct ConnectUseCase: Sendable {
    @Dependency(\.spaceRepository) private var spaceRepository
    @Dependency(\.userRepository) private var userRepository

    public init() {}

    public func issueCode() async throws -> String {
        try await spaceRepository.issueInviteCode()
    }

    public func requestJoin(code: String) async throws -> Invitation {
        try await spaceRepository.sendInvitationByCode(code: code)
    }

    public func sendInvitation(toUserId: UUID) async throws -> Invitation {
        try await spaceRepository.sendInvitation(toUserId: toUserId)
    }

    public func invitations(direction: InvitationDirection) async throws -> [Invitation] {
        try await spaceRepository.invitations(direction: direction)
    }

    public func respond(to invitationId: UUID, action: InvitationAction) async throws {
        try await spaceRepository.respond(to: invitationId, action: action)
    }

    public func searchUser(handle: String) async throws -> UserProfile {
        try await userRepository.search(handle: handle)
    }
}

public extension DependencyValues {
    var connectUseCase: ConnectUseCase {
        get { self[ConnectUseCaseKey.self] }
        set { self[ConnectUseCaseKey.self] = newValue }
    }
}

private enum ConnectUseCaseKey: DependencyKey {
    static let liveValue = ConnectUseCase()
}
