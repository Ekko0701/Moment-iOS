import Dependencies
import Foundation

/// 설정 유스케이스 — 프로필 수정·연결 해제·계정 삭제.
public struct SettingsUseCase: Sendable {
    @Dependency(\.userRepository) private var userRepository
    @Dependency(\.spaceRepository) private var spaceRepository
    @Dependency(\.authRepository) private var authRepository

    public init() {}

    public func myProfile() async throws -> UserProfile {
        try await userRepository.me()
    }

    public func updateNickname(_ nickname: String) async throws -> UserProfile {
        try await userRepository.updateMe(nickname: nickname, profileImageKey: nil)
    }

    public func leaveSpace(spaceId: UUID) async throws {
        try await spaceRepository.leave(spaceId: spaceId)
    }

    public func deleteAccount() async throws {
        try await userRepository.deleteMe()
        try await authRepository.logout()
    }

    public func logout() async throws {
        try await authRepository.logout()
    }
}

public extension DependencyValues {
    var settingsUseCase: SettingsUseCase {
        get { self[SettingsUseCaseKey.self] }
        set { self[SettingsUseCaseKey.self] = newValue }
    }
}

private enum SettingsUseCaseKey: DependencyKey {
    static let liveValue = SettingsUseCase()
}
