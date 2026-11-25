import Foundation

public struct Moment: Sendable, Equatable, Identifiable {
    public let id: UUID
    public let spaceId: UUID
    public let author: UserProfile
    public let imageURL: URL?
    public let text: String?
    /// 사진 위 글씨의 위치와 색. 서버가 값을 주지 않은 모먼트는 nil이다
    public let textStyle: MomentTextStyle?
    public let createdAt: Date
    public let myReaction: String?
    public let reactions: [ReactionCount]

    public init(
        id: UUID,
        spaceId: UUID,
        author: UserProfile,
        imageURL: URL? = nil,
        text: String? = nil,
        textStyle: MomentTextStyle? = nil,
        createdAt: Date,
        myReaction: String? = nil,
        reactions: [ReactionCount] = []
    ) {
        self.id = id
        self.spaceId = spaceId
        self.author = author
        self.imageURL = imageURL
        self.text = text
        self.textStyle = textStyle
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
    /// 사진 위에 올릴 글. 사진이 없거나 글이 비어 있으면 nil
    var photoText: String? {
        guard imageURL != nil, let text, !text.isEmpty else { return nil }
        return text
    }

    /// 사진 위 글씨를 그릴 방식. 값이 없는 모먼트는 왼쪽 위·흰색으로 그린다
    var photoTextStyle: MomentTextStyle { textStyle ?? .standard }

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
            textStyle: textStyle,
            createdAt: createdAt,
            myReaction: emoji,
            reactions: counts.filter { $0.1 > 0 }.map { ReactionCount(emoji: $0.0, count: $0.1) }
        )
    }
}
