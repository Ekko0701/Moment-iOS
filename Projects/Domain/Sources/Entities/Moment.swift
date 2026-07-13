import Foundation

public struct Moment: Sendable, Equatable, Identifiable {
    public let id: UUID
    public let spaceId: UUID
    public let author: UserProfile
    public let imageURL: URL?
    public let text: String?
    public let createdAt: Date
    public let myReaction: String?
    public let reactions: [ReactionCount]

    public init(
        id: UUID,
        spaceId: UUID,
        author: UserProfile,
        imageURL: URL? = nil,
        text: String? = nil,
        createdAt: Date,
        myReaction: String? = nil,
        reactions: [ReactionCount] = []
    ) {
        self.id = id
        self.spaceId = spaceId
        self.author = author
        self.imageURL = imageURL
        self.text = text
        self.createdAt = createdAt
        self.myReaction = myReaction
        self.reactions = reactions
    }
}

public struct ReactionCount: Sendable, Equatable {
    public let emoji: String
    public let count: Int

    public init(emoji: String, count: Int) {
        self.emoji = emoji
        self.count = count
    }
}
