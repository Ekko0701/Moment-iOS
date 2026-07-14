import Dependencies
import Foundation

/// 앱 진입 세션 유스케이스 — 프로필과 스페이스를 한 번에 확인한다.
public struct SessionUseCase: Sendable {
    @Dependency(\.userRepository) private var userRepository
    @Dependency(\.spaceRepository) private var spaceRepository

    public init() {}

    /// 앱 시작/로그인 직후의 부트스트랩: 내 프로필 + 참여 스페이스.
    public func bootstrap() async throws -> (user: UserProfile, spaces: [Space]) {
        let user = try await userRepository.me()
        let spaces = try await spaceRepository.mySpaces()
        return (user, spaces)
    }

    public func myProfile() async throws -> UserProfile {
        try await userRepository.me()
    }

    public func mySpaces() async throws -> [Space] {
        try await spaceRepository.mySpaces()
    }
}

public extension DependencyValues {
    var sessionUseCase: SessionUseCase {
        get { self[SessionUseCaseKey.self] }
        set { self[SessionUseCaseKey.self] = newValue }
    }
}

private enum SessionUseCaseKey: DependencyKey {
    static let liveValue = SessionUseCase()
}
