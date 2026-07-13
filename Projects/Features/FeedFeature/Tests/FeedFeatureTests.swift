import Foundation
import Testing
@testable import FeedFeature

@Test("초기 피드는 비어 있고 로딩 중이 아니다")
func initialState() {
    let state = FeedFeature.State()
    #expect(state.moments.isEmpty)
    #expect(state.isLoading == false)
    #expect(state.nextCursor == nil)
}
