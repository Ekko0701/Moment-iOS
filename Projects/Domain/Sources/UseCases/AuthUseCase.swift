import Dependencies
import Foundation

/// 인증 유스케이스 — 로그인/가입의 비즈니스 규칙(기본 닉네임 등)을 소유한다.
public struct AuthUseCase: Sendable {
    @Dependency(\.authRepository) private var authRepository

    public init() {}

    /// Apple 로그인. 신규 가입 시 임시 기본 닉네임을 부여한다(온보딩에서 변경 가능).
    public func loginWithApple(identityToken: String) async throws -> Bool {
        let defaultNickname = "User\(Int.random(in: 1000...9999))"
        let result = try await authRepository.loginWithApple(
            identityToken: identityToken, nickname: defaultNickname)
        return result.isNewUser
    }

    public func signUpWithEmail(email: String, password: String, nickname: String) async throws -> Bool {
        let result = try await authRepository.signUpWithEmail(
            email: email, password: password, nickname: nickname)
        return result.isNewUser
    }

    public func loginWithEmail(email: String, password: String) async throws {
        _ = try await authRepository.loginWithEmail(email: email, password: password)
    }

    public func logout() async throws {
        try await authRepository.logout()
    }
}

public extension DependencyValues {
    var authUseCase: AuthUseCase {
        get { self[AuthUseCaseKey.self] }
        set { self[AuthUseCaseKey.self] = newValue }
    }
}

private enum AuthUseCaseKey: DependencyKey {
    static let liveValue = AuthUseCase()
}
