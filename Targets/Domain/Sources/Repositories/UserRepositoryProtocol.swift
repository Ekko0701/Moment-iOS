import Foundation

public protocol UserRepositoryProtocol: Sendable {
    func me() async throws -> UserProfile
    func updateMe(nickname: String?, profileImageKey: String?) async throws -> UserProfile
    func search(handle: String) async throws -> UserProfile
    func deleteMe() async throws
}
