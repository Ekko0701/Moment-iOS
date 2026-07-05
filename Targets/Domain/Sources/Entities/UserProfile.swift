import Foundation

public struct UserProfile: Sendable, Equatable, Identifiable {
    public let id: UUID
    public let handle: String
    public let nickname: String
    public let profileImageURL: URL?
    public let isSearchable: Bool

    public init(
        id: UUID,
        handle: String,
        nickname: String,
        profileImageURL: URL? = nil,
        isSearchable: Bool = true
    ) {
        self.id = id
        self.handle = handle
        self.nickname = nickname
        self.profileImageURL = profileImageURL
        self.isSearchable = isSearchable
    }
}
