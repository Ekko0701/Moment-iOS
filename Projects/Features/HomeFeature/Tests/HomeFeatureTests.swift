import Foundation
import Testing
import Domain
@testable import HomeFeature

private let me = UserProfile(id: UUID(), handle: "m_1", nickname: "동주")
private let partner = UserProfile(id: UUID(), handle: "m_2", nickname: "지은")

private func oneToOne(createdAt: Date = Date()) -> Space {
    Space(id: UUID(), type: .oneToOne, maxMembers: 2, status: "ACTIVE", members: [me, partner], createdAt: createdAt)
}

private func group() -> Space {
    Space(id: UUID(), type: .group, name: "가족", maxMembers: 6, status: "ACTIVE", members: [me, partner],
          createdAt: Date())
}

@Test("1:1의 상대는 멤버 중 나를 제외한 사람이고, 그룹에는 상대가 없다")
func partnerExcludesMe() {
    var state = HomeFeature.State()
    state.currentUser = me
    #expect(state.partner(in: oneToOne())?.id == partner.id)
    #expect(state.partner(in: group()) == nil)
}

@Test("연결 당일은 D+1로 계산한다")
func daysTogetherStartsAtOne() {
    let state = HomeFeature.State()
    #expect(state.daysTogether(in: oneToOne()) == 1)
}

@Test("1:1 스페이스가 없으면 홈은 1:1 연결 진입을 노출한다")
func connectEntryWhenNoOneToOne() {
    var state = HomeFeature.State()
    state.spaces = [group()]
    #expect(state.oneToOneSpace == nil)
    state.spaces = [oneToOne(), group()]
    #expect(state.oneToOneSpace != nil)
}

@Test("홈 진입은 새로고침 중 상태가 된다")
func onAppearStartsRefreshing() {
    var state = HomeFeature.State()
    _ = HomeFeature().reduce(into: &state, action: .onAppear)
    #expect(state.isRefreshing)
}

@Test("참여 요청을 취소하면 화면 목록에서 바로 빠진다")
func cancelJoinRequestRemovesFromList() {
    var state = HomeFeature.State()
    let keep = GroupJoinRequest(id: UUID(), spaceId: UUID(), spaceName: "가족", status: .pending, createdAt: Date())
    let cancel = GroupJoinRequest(id: UUID(), spaceId: UUID(), spaceName: "동호회", status: .pending, createdAt: Date())
    state.pendingJoinRequests = [keep, cancel]

    _ = HomeFeature().reduce(into: &state, action: .cancelJoinRequestTapped(cancel))

    #expect(state.pendingJoinRequests == [keep])
}
