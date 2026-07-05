import Foundation
import Domain

public final class MomentRepositoryImpl: MomentRepositoryProtocol {
    private let apiClient: APIClientProtocol

    public init(apiClient: APIClientProtocol) {
        self.apiClient = apiClient
    }

    public func timeline(spaceId: UUID, cursor: String?, limit: Int) async throws -> PaginatedMoments {
        let endpoint = MomentEndpoints.listMoments(spaceId: spaceId.uuidString, limit: limit, cursor: cursor)
        let response: PaginatedMomentsResponse = try await apiClient.request(endpoint)
        let moments = response.items.map { $0.toDomainModel() }
        return PaginatedMoments(moments: moments, nextCursor: response.nextCursor)
    }

    public func latestExcludingMine(spaceId: UUID) async throws -> Moment? {
        let endpoint = MomentEndpoints.listMoments(spaceId: spaceId.uuidString, limit: 1, cursor: nil)
        do {
            let response: PaginatedMomentsResponse = try await apiClient.request(endpoint)
            return response.items.first?.toDomainModel()
        } catch {
            return nil
        }
    }

    public func create(spaceId: UUID, imageKey: String?, text: String?) async throws -> Moment {
        let endpoint = MomentEndpoints.createMoment(spaceId: spaceId.uuidString, imageUrl: imageKey, text: text)
        let response: MomentDTO = try await apiClient.request(endpoint)
        return response.toDomainModel()
    }

    public func delete(momentId: UUID) async throws {
        let endpoint = MomentEndpoints.deleteMoment(momentId: momentId.uuidString)
        try await apiClient.requestVoid(endpoint)
    }

    public func presign() async throws -> PresignResponse {
        let endpoint = PresignEndpoints.presign()
        let response: PresignResponseDTO = try await apiClient.request(endpoint)
        return PresignResponse(uploadUrl: response.uploadUrl, imageKey: response.imageKey)
    }

    public func react(to momentId: UUID, emoji: String) async throws {
        let endpoint = ReactionEndpoints.addReaction(momentId: momentId.uuidString, emoji: emoji)
        try await apiClient.requestVoid(endpoint)
    }

    public func removeReaction(from momentId: UUID) async throws {
        let endpoint = ReactionEndpoints.removeReaction(momentId: momentId.uuidString)
        try await apiClient.requestVoid(endpoint)
    }
}

struct PaginatedMomentsResponse: Decodable {
    let items: [MomentDTO]
    let nextCursor: String?
}

struct MomentDTO: Decodable {
    let id: String
    let spaceId: String
    let author: MomentAuthorDTO
    let imageURL: String?
    let text: String?
    let createdAt: Date
    let myReaction: String?
    let reactions: [ReactionCountDTO]?

    enum CodingKeys: String, CodingKey {
        case id, spaceId, author, imageURL, text, createdAt, myReaction, reactions
    }

    func toDomainModel() -> Moment {
        Moment(
            id: UUID(uuidString: id) ?? UUID(),
            spaceId: UUID(uuidString: spaceId) ?? UUID(),
            author: author.toDomainModel(),
            imageURL: imageURL.flatMap { URL(string: $0) },
            text: text,
            createdAt: createdAt,
            myReaction: myReaction,
            reactions: (reactions ?? []).map { ReactionCount(emoji: $0.emoji, count: $0.count) }
        )
    }
}

struct MomentAuthorDTO: Decodable {
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

struct ReactionCountDTO: Decodable {
    let emoji: String
    let count: Int
}

struct PresignResponseDTO: Decodable {
    let uploadUrl: String
    let imageKey: String

    enum CodingKeys: String, CodingKey {
        case uploadUrl
        case imageKey
    }
}
