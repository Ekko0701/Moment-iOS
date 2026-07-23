import Foundation

public struct TokenPair: Sendable, Equatable {
    public let accessToken: String
    public let refreshToken: String

    public init(accessToken: String, refreshToken: String) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
    }
}

public struct AppleLoginCredential: Sendable, Equatable {
    public let identityToken: String
    public let authorizationCode: String
    public let nonce: String

    public init(identityToken: String, authorizationCode: String, nonce: String) {
        self.identityToken = identityToken
        self.authorizationCode = authorizationCode
        self.nonce = nonce
    }
}

public protocol AuthRepositoryProtocol: Sendable {
    func loginWithApple(credential: AppleLoginCredential, nickname: String) async throws -> (tokenPair: TokenPair, isNewUser: Bool)
    func signUpWithEmail(email: String, password: String, nickname: String) async throws -> (tokenPair: TokenPair, isNewUser: Bool)
    func loginWithEmail(email: String, password: String) async throws -> TokenPair
    func refresh(refreshToken: String) async throws -> TokenPair
    func logout() async throws
}
