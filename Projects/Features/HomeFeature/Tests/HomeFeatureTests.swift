import Foundation
import Testing
import Domain
@testable import HomeFeature

@Test("상대방은 스페이스 멤버 중 나를 제외한 사람이다")
func partnerExcludesMe() {
    let me = UserProfile(id: UUID(), handle: "m_1", nickname: "동주")
    let partner = UserProfile(id: UUID(), handle: "m_2", nickname: "지은")
    var state = HomeFeature.State()
    state.currentUser = me
    state.space = Space(id: UUID(), type: .oneToOne, maxMembers: 2,
                        status: "ACTIVE", members: [me, partner], createdAt: Date())
    #expect(state.partner?.id == partner.id)
}

@Test("연결 당일은 D+1로 계산한다")
func daysTogetherStartsAtOne() {
    var state = HomeFeature.State()
    state.space = Space(id: UUID(), type: .oneToOne, maxMembers: 2,
                        status: "ACTIVE", members: [], createdAt: Date())
    #expect(state.daysTogether == 1)
}
