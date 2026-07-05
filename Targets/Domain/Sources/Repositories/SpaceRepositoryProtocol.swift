import Foundation

public protocol SpaceRepositoryProtocol: Sendable {
    func mySpaces() async throws -> [Space]
    func leave(spaceId: UUID) async throws
    func issueInviteCode(for spaceId: UUID) async throws -> String
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
