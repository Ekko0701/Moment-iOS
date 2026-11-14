import Foundation
import Testing
import Domain
@testable import FeedFeature

private let author = UserProfile(id: UUID(), handle: "m_1", nickname: "지은")

private func moments(_ count: Int, in spaceId: UUID) -> [Moment] {
    (0..<count).map { _ in Moment(id: UUID(), spaceId: spaceId, author: author, text: "글", createdAt: Date()) }
}

@Test("초기 피드는 비어 있고 로딩 중이 아니다")
func initialState() {
    let state = FeedFeature.State()
    #expect(state.moments.isEmpty)
    #expect(state.isLoading == false)
    #expect(state.nextCursor == nil)
}

@Test("다른 스페이스로 바뀐 뒤 도착한 이전 스페이스의 응답은 버린다")
func staleSpaceResponseIsDropped() {
    let previous = UUID()
    let current = UUID()
    var state = FeedFeature.State()
    state.selectedSpaceId = current
    state.isLoading = true

    _ = FeedFeature().reduce(
        into: &state,
        action: .timelineResponse(spaceId: previous, page: .first,
                                  .success(PaginatedMoments(moments: moments(3, in: previous), nextCursor: "c"))))

    #expect(state.moments.isEmpty)
    #expect(state.nextCursor == nil)
    #expect(state.isLoading)
}

@Test("첫 페이지는 목록을 교체하고 다음 페이지는 이어 붙인다")
func firstPageReplacesNextPageAppends() {
    let spaceId = UUID()
    var state = FeedFeature.State()
    state.selectedSpaceId = spaceId
    state.moments = moments(1, in: spaceId)

    _ = FeedFeature().reduce(
        into: &state,
        action: .timelineResponse(spaceId: spaceId, page: .first,
                                  .success(PaginatedMoments(moments: moments(2, in: spaceId), nextCursor: "c1"))))
    #expect(state.moments.count == 2)

    state.isLoadingMore = true
    _ = FeedFeature().reduce(
        into: &state,
        action: .timelineResponse(spaceId: spaceId, page: .next,
                                  .success(PaginatedMoments(moments: moments(3, in: spaceId), nextCursor: nil))))
    #expect(state.moments.count == 5)
    #expect(state.isLoadingMore == false)
    #expect(state.nextCursor == nil)
}

@Test("첫 페이지를 불러오는 중에는 다음 페이지를 요청하지 않는다")
func loadMoreWaitsForFirstPage() {
    var state = FeedFeature.State()
    state.selectedSpaceId = UUID()
    state.nextCursor = "c"
    state.isLoading = true

    _ = FeedFeature().reduce(into: &state, action: .loadMore)

    #expect(state.isLoadingMore == false)
}

private func reacted(my: String?, counts: [(String, Int)]) -> Moment {
    Moment(id: UUID(), spaceId: UUID(), author: author, text: "글", createdAt: Date(),
           myReaction: my, reactions: counts.map { ReactionCount(emoji: $0.0, count: $0.1) })
}

@Test("내 반응과 같은 이모지를 누르면 서버에서 받은 내 반응도 해제된다")
func tappingMyReactionRemovesIt() {
    var state = FeedFeature.State()
    state.moments = [reacted(my: "❤️", counts: [("❤️", 2)])]
    _ = FeedFeature().reduce(into: &state, action: .reactionTapped(momentId: state.moments[0].id, emoji: "❤️"))
    #expect(state.moments[0].myReaction == nil)
    #expect(state.moments[0].reactions == [ReactionCount(emoji: "❤️", count: 1)])
}

@Test("다른 이모지를 누르면 개수가 옮겨 가고, 처음 남기는 반응도 개수가 생긴다")
func tappingOtherReactionMovesCount() {
    var state = FeedFeature.State()
    state.moments = [reacted(my: "❤️", counts: [("❤️", 1)]), reacted(my: nil, counts: [])]
    _ = FeedFeature().reduce(into: &state, action: .reactionTapped(momentId: state.moments[0].id, emoji: "😂"))
    #expect(state.moments[0].myReaction == "😂")
    #expect(state.moments[0].reactions == [ReactionCount(emoji: "😂", count: 1)])
    _ = FeedFeature().reduce(into: &state, action: .reactionTapped(momentId: state.moments[1].id, emoji: "👍"))
    #expect(state.moments[1].reactions == [ReactionCount(emoji: "👍", count: 1)])
}

@Test("요청이 실패하면 반응을 누르기 전으로 되돌린다")
func failedReactionRollsBack() {
    var state = FeedFeature.State()
    let original = reacted(my: nil, counts: [("😊", 1)])
    state.moments = [original]
    _ = FeedFeature().reduce(into: &state, action: .reactionTapped(momentId: original.id, emoji: "😊"))
    _ = FeedFeature().reduce(into: &state, action: .reactionResponse(
        momentId: original.id, applied: "😊", previous: original, .failure(.unknown(code: "E", message: "실패"))))
    #expect(state.moments[0] == original)
    #expect(state.error != nil)
}
