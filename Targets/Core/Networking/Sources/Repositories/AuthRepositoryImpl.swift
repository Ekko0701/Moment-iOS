import Foundation
import Domain

public final class AuthRepositoryImpl: AuthRepositoryProtocol {
    private let apiClient: APIClientProtocol

    public init(apiClient: APIClientProtocol) {
        self.apiClient = apiClient
    }

    public func loginWithApple(identityToken: String, nickname: String) async throws -> (tokenPair: TokenPair, isNewUser: Bool) {
        let endpoint = AuthEndpoints.loginWithApple(identityToken: identityToken, nickname: nickname)
        let response: LoginAppleResponse = try await apiClient.request(endpoint)
        return (TokenPair(accessToken: response.accessToken, refreshToken: response.refreshToken), response.isNewUser)
    }

    public func refresh(refreshToken: String) async throws -> TokenPair {
        let endpoint = AuthEndpoints.refresh(refreshToken: refreshToken)
        let response: RefreshResponse = try await apiClient.request(endpoint)
        return TokenPair(accessToken: response.accessToken, refreshToken: response.refreshToken)
    }

    public func logout() async throws {
        // Tokens deleted locally by app
    }
}

struct LoginAppleResponse: Decodable {
    let accessToken: String
    let refreshToken: String
    let isNewUser: Bool

    enum CodingKeys: String, CodingKey {
        case accessToken
        case refreshToken
        case isNewUser
    }
}

struct RefreshResponse: Decodable {
    let accessToken: String
    let refreshToken: String

    enum CodingKeys: String, CodingKey {
        case accessToken
        case refreshToken
    }
}
