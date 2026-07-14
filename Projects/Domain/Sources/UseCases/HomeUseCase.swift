import Dependencies
import Foundation

/// 홈 유스케이스 — 스페이스 카드에 보여줄 상대방의 최신 모먼트.
public struct HomeUseCase: Sendable {
    @Dependency(\.momentRepository) private var momentRepository

    public init() {}

    public func latestPartnerMoment(spaceId: UUID) async throws -> Moment? {
        try await momentRepository.latestExcludingMine(spaceId: spaceId)
    }
}

public extension DependencyValues {
    var homeUseCase: HomeUseCase {
        get { self[HomeUseCaseKey.self] }
        set { self[HomeUseCaseKey.self] = newValue }
    }
}

private enum HomeUseCaseKey: DependencyKey {
    static let liveValue = HomeUseCase()
}
