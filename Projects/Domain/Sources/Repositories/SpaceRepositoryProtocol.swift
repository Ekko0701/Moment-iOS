import Foundation

public protocol SpaceRepositoryProtocol: Sendable {
    func mySpaces() async throws -> [Space]
    /// 공간 이름 변경. nil/공백을 넘기면 이름 없음 상태로 되돌아간다
    func rename(spaceId: UUID, name: String?) async throws
    func leave(spaceId: UUID) async throws
    func issueInviteCode() async throws -> String
    func sendInvitation(toUserId: UUID) async throws -> Invitation
    func sendInvitationByCode(code: String) async throws -> Invitation
    func invitations(direction: InvitationDirection) async throws -> [Invitation]
    func respond(to invitationId: UUID, action: InvitationAction) async throws
}

public enum InvitationDirection: Sendable {
    case received
    case sent
}

public enum InvitationAction: Sendable {
    case accept
    case decline
    case cancel
}
