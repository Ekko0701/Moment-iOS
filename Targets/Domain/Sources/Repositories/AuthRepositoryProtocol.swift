import Foundation

public struct TokenPair: Sendable, Equatable {
    public let accessToken: String
    public let refreshToken: String

    public init(accessToken: String, refreshToken: String) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
    }
}

public protocol AuthRepositoryProtocol: Sendable {
    func loginWithApple(identityToken: String, nickname: String) async throws -> (tokenPair: TokenPair, isNewUser: Bool)
    func signUpWithEmail(email: String, password: String, nickname: String) async throws -> (tokenPair: TokenPair, isNewUser: Bool)
    func loginWithEmail(email: String, password: String) async throws -> TokenPair
    func refresh(refreshToken: String) async throws -> TokenPair
    func logout() async throws
}
