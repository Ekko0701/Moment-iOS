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

public extension Moment {
    /// 서버가 허용하는 감정표현 6종. 이 순서로 선택지를 보여준다
    static let allowedReactions = ["❤️", "😊", "😂", "😢", "😮", "👍"]

    /// 내 반응을 바꾼 모먼트. nil이면 내 반응을 지운다. 개수는 이전 반응을 빼고 새 반응을 더해 다시 센다
    func withMyReaction(_ emoji: String?) -> Moment {
        var counts = reactions.map { ($0.emoji, $0.count) }
        if let previous = myReaction, let index = counts.firstIndex(where: { $0.0 == previous }) {
            counts[index].1 -= 1
        }
        if let emoji {
            if let index = counts.firstIndex(where: { $0.0 == emoji }) {
                counts[index].1 += 1
            } else {
                counts.append((emoji, 1))
            }
        }
        return Moment(
            id: id,
            spaceId: spaceId,
            author: author,
            imageURL: imageURL,
            text: text,
            createdAt: createdAt,
            myReaction: emoji,
            reactions: counts.filter { $0.1 > 0 }.map { ReactionCount(emoji: $0.0, count: $0.1) }
        )
    }
}
