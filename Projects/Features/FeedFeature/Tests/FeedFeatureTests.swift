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
