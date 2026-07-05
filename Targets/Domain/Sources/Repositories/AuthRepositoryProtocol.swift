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
    func refresh(refreshToken: String) async throws -> TokenPair
    func logout() async throws
}
