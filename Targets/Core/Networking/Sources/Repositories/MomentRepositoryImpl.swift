import Foundation
import Domain

public final class MomentRepositoryImpl: MomentRepositoryProtocol {
    private let apiClient: APIClientProtocol

    public init(apiClient: APIClientProtocol) {
        self.apiClient = apiClient
    }

    public func timeline(spaceId: UUID, cursor: String?, limit: Int) async throws -> PaginatedMoments {
        // 서버 계약: data = [MomentResponse], meta = { nextCursor, hasNext }
        let endpoint = MomentEndpoints.listMoments(spaceId: spaceId.uuidString, limit: limit, cursor: cursor)
        let result: (data: [MomentDTO], meta: ApiMeta?) = try await apiClient.requestWithMeta(endpoint)
        let moments = result.data.map { $0.toDomainModel() }
        let hasNext = result.meta?.hasNext ?? false
        return PaginatedMoments(moments: moments, nextCursor: hasNext ? result.meta?.nextCursor : nil)
    }

    public func latestExcludingMine(spaceId: UUID) async throws -> Moment? {
        // 서버 계약: GET /v1/spaces/{id}/moments/latest?excludeMine=true — 없으면 data: null
        let endpoint = MomentEndpoints.latestMoment(spaceId: spaceId.uuidString, excludeMine: true)
        let dto: MomentDTO? = try await apiClient.requestOptional(endpoint)
        return dto?.toDomainModel()
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
        return PresignResponse(uploadUrl: response.uploadUrl, imageKey: response.imageUrl)
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

/// 서버 MomentResponse 매핑:
/// { id, spaceId, author:{userId,handle,nickname,profileImageUrl}, imageUrl, text,
///   createdAtMs(epoch millis), reactions:[{emoji,count}], myReaction }
struct MomentDTO: Decodable {
    let id: String
    let spaceId: String
    let author: MomentAuthorDTO
    let imageUrl: String?
    let text: String?
    let createdAtMs: Int64
    let myReaction: String?
    let reactions: [ReactionCountDTO]?

    func toDomainModel() -> Moment {
        Moment(
            id: UUID(uuidString: id) ?? UUID(),
            spaceId: UUID(uuidString: spaceId) ?? UUID(),
            author: author.toDomainModel(),
            imageURL: imageUrl.flatMap { URL(string: $0) },
            text: text,
            createdAt: Date(timeIntervalSince1970: TimeInterval(createdAtMs) / 1000),
            myReaction: myReaction,
            reactions: (reactions ?? []).map { ReactionCount(emoji: $0.emoji, count: $0.count) }
        )
    }
}

struct MomentAuthorDTO: Decodable {
    let userId: String
    let handle: String
    let nickname: String
    let profileImageUrl: String?

    func toDomainModel() -> UserProfile {
        UserProfile(
            id: UUID(uuidString: userId) ?? UUID(),
            handle: handle,
            nickname: nickname,
            profileImageURL: profileImageUrl.flatMap { URL(string: $0) }
        )
    }
}

struct ReactionCountDTO: Decodable {
    let emoji: String
    let count: Int
}

/// 서버 PresignResponse 매핑: { uploadUrl, imageUrl }
struct PresignResponseDTO: Decodable {
    let uploadUrl: String
    let imageUrl: String
}
