import Foundation
import Domain

public final class SpaceRepositoryImpl: SpaceRepositoryProtocol {
    private let apiClient: APIClientProtocol

    public init(apiClient: APIClientProtocol) {
        self.apiClient = apiClient
    }

    public func mySpaces() async throws -> [Space] {
        let endpoint = SpaceEndpoints.getActiveSpace()
        if let space: SpaceResponseDTO = try? await apiClient.request(endpoint) {
            return [space.toDomainModel()]
        }
        return []
    }

    public func leave(spaceId: UUID) async throws {}
    public func issueInviteCode(for spaceId: UUID) async throws -> String { "" }
    public func sendInvitation(toUserId: UUID) async throws -> Invitation { throw DomainError.notFound }
    public func sendInvitationByCode(code: String) async throws -> Invitation { throw DomainError.notFound }

    public func invitations(direction: InvitationDirection) async throws -> [Invitation] {
        let endpoint = InvitationEndpoints.listInvitations()
        let dtos: [InvitationResponseDTO] = try await apiClient.request(endpoint)
        return dtos.map { $0.toDomainModel() }
    }

    public func respond(to invitationId: UUID, action: InvitationAction) async throws {
        let status = action == .accept ? "ACCEPTED" : "DECLINED"
        let endpoint = InvitationEndpoints.updateInvitation(invitationId: invitationId.uuidString, status: status)
        try await apiClient.requestVoid(endpoint)
    }
}

struct SpaceResponseDTO: Decodable {
    let id: String
    let type: String
    let maxMembers: Int
    let status: String
    let members: [SpaceMemberDTO]?
    let createdAt: Date

    func toDomainModel() -> Space {
        Space(
            id: UUID(uuidString: id) ?? UUID(),
            type: .oneToOne,
            maxMembers: maxMembers,
            status: status,
            members: (members ?? []).map { $0.toDomainModel() },
            createdAt: createdAt
        )
    }
}

struct SpaceMemberDTO: Decodable {
    let id: String
    let handle: String
    let nickname: String
    let profileImageURL: String?

    func toDomainModel() -> UserProfile {
        UserProfile(
            id: UUID(uuidString: id) ?? UUID(),
            handle: handle,
            nickname: nickname,
            profileImageURL: profileImageURL.flatMap { URL(string: $0) }
        )
    }
}

struct InvitationResponseDTO: Decodable {
    let id: String
    let via: String
    let status: String
    let counterpart: InvitationCounterpartDTO
    let createdAt: Date

    func toDomainModel() -> Invitation {
        Invitation(
            id: UUID(uuidString: id) ?? UUID(),
            via: InvitationVia(rawValue: via) ?? .code,
            status: InvitationStatus(rawValue: status) ?? .pending,
            counterpart: counterpart.toDomainModel(),
            createdAt: createdAt
        )
    }
}

struct InvitationCounterpartDTO: Decodable {
    let id: String
    let handle: String
    let nickname: String
    let profileImageURL: String?

    func toDomainModel() -> UserProfile {
        UserProfile(
            id: UUID(uuidString: id) ?? UUID(),
            handle: handle,
            nickname: nickname,
            profileImageURL: profileImageURL.flatMap { URL(string: $0) }
        )
    }
}
