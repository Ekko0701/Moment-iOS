import Foundation
import Domain

public final class AuthRepositoryImpl: AuthRepositoryProtocol {
    private let apiClient: APIClientProtocol
    private let tokenStore: TokenStoreProtocol

    public init(apiClient: APIClientProtocol, tokenStore: TokenStoreProtocol) {
        self.apiClient = apiClient
        self.tokenStore = tokenStore
    }

    public func loginWithApple(identityToken: String, nickname: String) async throws -> (tokenPair: TokenPair, isNewUser: Bool) {
        let endpoint = AuthEndpoints.loginWithApple(identityToken: identityToken, nickname: nickname)
        let response: LoginAppleResponse = try await apiClient.request(endpoint)
        let pair = TokenPair(accessToken: response.accessToken, refreshToken: response.refreshToken)
        try await persist(pair)
        return (pair, response.isNewUser)
    }

    public func signUpWithEmail(email: String, password: String, nickname: String) async throws -> (tokenPair: TokenPair, isNewUser: Bool) {
        let endpoint = AuthEndpoints.emailSignup(email: email, password: password, nickname: nickname)
        let response: LoginAppleResponse = try await apiClient.request(endpoint)
        let pair = TokenPair(accessToken: response.accessToken, refreshToken: response.refreshToken)
        try await persist(pair)
        return (pair, response.isNewUser)
    }

    public func loginWithEmail(email: String, password: String) async throws -> TokenPair {
        let endpoint = AuthEndpoints.emailLogin(email: email, password: password)
        let response: RefreshResponse = try await apiClient.request(endpoint)
        let pair = TokenPair(accessToken: response.accessToken, refreshToken: response.refreshToken)
        try await persist(pair)
        return pair
    }

    public func refresh(refreshToken: String) async throws -> TokenPair {
        let endpoint = AuthEndpoints.refresh(refreshToken: refreshToken)
        let response: RefreshResponse = try await apiClient.request(endpoint)
        let pair = TokenPair(accessToken: response.accessToken, refreshToken: response.refreshToken)
        try await persist(pair)
        return pair
    }

    public func logout() async throws {
        try await tokenStore.deleteTokens()
    }

    /// 발급받은 토큰 쌍을 Keychain에 저장한다.
    /// 인증 성공의 책임(저장 포함)을 리포지토리 한 곳으로 모아 인터셉터가 항상 최신 토큰을 읽게 한다.
    private func persist(_ pair: TokenPair) async throws {
        try await tokenStore.setAccessToken(pair.accessToken)
        try await tokenStore.setRefreshToken(pair.refreshToken)
    }
}

struct LoginAppleResponse: Decodable {
    let accessToken: String
    let refreshToken: String
    let isNewUser: Bool
}

struct RefreshResponse: Decodable {
    let accessToken: String
    let refreshToken: String
}
