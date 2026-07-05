import Foundation

public struct PaginatedMoments: Sendable, Equatable {
    public let moments: [Moment]
    public let nextCursor: String?

    public init(moments: [Moment], nextCursor: String?) {
        self.moments = moments
        self.nextCursor = nextCursor
    }
}

public protocol MomentRepositoryProtocol: Sendable {
    func timeline(spaceId: UUID, cursor: String?, limit: Int) async throws -> PaginatedMoments
    func latestExcludingMine(spaceId: UUID) async throws -> Moment?
    func create(spaceId: UUID, imageKey: String?, text: String?) async throws -> Moment
    func delete(momentId: UUID) async throws
    func react(to momentId: UUID, emoji: String) async throws
    func removeReaction(from momentId: UUID) async throws
}
