import Foundation

public protocol TokenStoreProtocol: Sendable {
    func getAccessToken() async -> String?
    func setAccessToken(_ token: String) async throws
    func getRefreshToken() async -> String?
    func setRefreshToken(_ token: String) async throws
    func deleteTokens() async throws
}
