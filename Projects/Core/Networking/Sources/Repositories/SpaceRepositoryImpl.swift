import Foundation
import Domain

public final class SpaceRepositoryImpl: SpaceRepositoryProtocol {
    private let apiClient: APIClientProtocol

    public init(apiClient: APIClientProtocol) {
        self.apiClient = apiClient
    }

    public func mySpaces() async throws -> [Space] {
        let endpoint = SpaceEndpoints.getActiveSpace()
        let spaces: [SpaceDTO] = try await apiClient.request(endpoint)
        return spaces.map { $0.toDomainModel() }
    }

    public func rename(spaceId: UUID, name: String?) async throws {
        let endpoint = SpaceEndpoints.rename(spaceId: spaceId, name: name)
        try await apiClient.requestVoid(endpoint)
    }

    public func leave(spaceId: UUID) async throws {
        let endpoint = SpaceEndpoints.leave(spaceId: spaceId)
        try await apiClient.requestVoid(endpoint)
    }

    public func issueInviteCode() async throws -> String {
        let endpoint = InvitationEndpoints.issueInviteCode()
        struct InviteCodeResponse: Decodable {
            let code: String
            let expiresAt: String
        }
        let dto: InviteCodeResponse = try await apiClient.request(endpoint)
        return dto.code
    }

    public func sendInvitation(toUserId: UUID) async throws -> Invitation {
        let body = SendInvitationRequest(toUserId: toUserId, code: nil)
        let endpoint = InvitationEndpoints.sendInvitation(body: body)
        let dto: InvitationDTO = try await apiClient.request(endpoint)
        return dto.toDomainModel()
    }

    public func sendInvitationByCode(code: String) async throws -> Invitation {
        let body = SendInvitationRequest(toUserId: nil, code: code)
        let endpoint = InvitationEndpoints.sendInvitation(body: body)
        let dto: InvitationDTO = try await apiClient.request(endpoint)
        return dto.toDomainModel()
    }

    public func invitations(direction: InvitationDirection) async throws -> [Invitation] {
        let received = direction == .received
        let endpoint = InvitationEndpoints.listInvitations(received: received)
        let dtos: [InvitationDTO] = try await apiClient.request(endpoint)
        return dtos.map { $0.toDomainModel() }
    }

    public func respond(to invitationId: UUID, action: InvitationAction) async throws {
        let actionString = action == .accept ? "accept" : (action == .decline ? "decline" : "cancel")
        let body = RespondInvitationRequest(action: actionString)
        let endpoint = InvitationEndpoints.respondInvitation(invitationId: invitationId, body: body)
        try await apiClient.requestVoid(endpoint)
    }

    // MARK: - 그룹 스페이스

    public func createGroup(name: String) async throws -> CreatedGroup {
        let dto: CreateGroupDTO = try await apiClient.request(GroupEndpoints.create(name: name))
        return dto.toDomainModel()
    }

    public func joinGroup(code: String) async throws -> Space {
        let dto: SpaceDTO = try await apiClient.request(GroupEndpoints.join(code: code))
        return dto.toDomainModel()
    }

    public func groupInviteCode(spaceId: UUID) async throws -> GroupInviteCode {
        let dto: GroupInviteCodeDTO = try await apiClient.request(GroupEndpoints.inviteCode(spaceId: spaceId))
        return dto.toDomainModel()
    }

    public func reissueGroupInviteCode(spaceId: UUID) async throws -> GroupInviteCode {
        let dto: GroupInviteCodeDTO = try await apiClient.request(GroupEndpoints.reissueInviteCode(spaceId: spaceId))
        return dto.toDomainModel()
    }

    public func members(spaceId: UUID) async throws -> [SpaceMember] {
        let dtos: [SpaceMemberDTO] = try await apiClient.request(SpaceMemberEndpoints.list(spaceId: spaceId))
        return dtos.map { $0.toDomainModel() }
    }

    public func removeMember(spaceId: UUID, userId: UUID) async throws {
        try await apiClient.requestVoid(SpaceMemberEndpoints.remove(spaceId: spaceId, userId: userId))
    }

    public func setNotifications(spaceId: UUID, enabled: Bool) async throws {
        try await apiClient.requestVoid(
            SpaceMemberEndpoints.updateMine(spaceId: spaceId, notificationsEnabled: enabled))
    }

    public func deleteGroup(spaceId: UUID) async throws {
        try await apiClient.requestVoid(GroupEndpoints.delete(spaceId: spaceId))
    }
}
