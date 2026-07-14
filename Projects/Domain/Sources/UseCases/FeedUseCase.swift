import Dependencies
import Foundation

/// 피드(타임라인·감정표현) 유스케이스.
public struct FeedUseCase: Sendable {
    @Dependency(\.momentRepository) private var momentRepository

    public init() {}

    public func timeline(spaceId: UUID, cursor: String?, limit: Int) async throws -> PaginatedMoments {
        try await momentRepository.timeline(spaceId: spaceId, cursor: cursor, limit: limit)
    }

    public func react(to momentId: UUID, emoji: String) async throws {
        try await momentRepository.react(to: momentId, emoji: emoji)
    }

    public func removeReaction(from momentId: UUID) async throws {
        try await momentRepository.removeReaction(from: momentId)
    }

    public func delete(momentId: UUID) async throws {
        try await momentRepository.delete(momentId: momentId)
    }
}

public extension DependencyValues {
    var feedUseCase: FeedUseCase {
        get { self[FeedUseCaseKey.self] }
        set { self[FeedUseCaseKey.self] = newValue }
    }
}

private enum FeedUseCaseKey: DependencyKey {
    static let liveValue = FeedUseCase()
}
