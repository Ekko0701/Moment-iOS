import Foundation
import Testing
import Domain
import GroupFeature
@testable import MomentApp

private let me = UserProfile(id: UUID(), handle: "m_1", nickname: "동주")
private let partner = UserProfile(id: UUID(), handle: "m_2", nickname: "지은")

private func oneToOne() -> Space {
    Space(id: UUID(), type: .oneToOne, maxMembers: 2, status: "ACTIVE", members: [me, partner], createdAt: Date())
}

private func group(_ name: String) -> Space {
    Space(id: UUID(), type: .group, name: name, maxMembers: 6, status: "ACTIVE", members: [me, partner],
          createdAt: Date(), myRole: .member)
}

private func mainState(_ spaces: [Space]) -> AppFeature.MainTabState {
    var state = AppFeature.MainTabState()
    state.currentUser = me
    state.apply(spaces: spaces)
    return state
}

// MARK: - 스페이스 열기

@Test("그룹 A의 설정이 열린 채로 그룹 B를 열면 A의 설정은 닫히고 B 상세와 B 피드만 남는다")
func openingAnotherGroupClosesPreviousSettings() {
    let groupA = group("A")
    let groupB = group("B")
    var state = mainState([groupA, groupB])
    state.open(groupA)
    state.groupSettings = GroupSettingsFeature.State(space: groupA, currentUserId: me.id)

    state.open(groupB)

    #expect(state.groupDetail?.space.id == groupB.id)
    #expect(state.groupSettings == nil)
    #expect(state.isHistoryPresented == false)
    #expect(state.feedState.selectedSpaceId == groupB.id)
    #expect(state.selectedSpaceId == groupB.id)
    #expect(state.composeState.selectedSpaceId == groupB.id)
}

@Test("그룹 상세가 열린 채로 1:1을 열면 그룹 상세를 닫고 1:1 히스토리만 연다")
func openingOneToOneClosesGroupDetail() {
    let pair = oneToOne()
    let groupA = group("A")
    var state = mainState([pair, groupA])
    state.open(groupA)
    state.isConnectPresented = true
    state.selectedTab = .compose

    state.open(pair)

    #expect(state.groupDetail == nil)
    #expect(state.isHistoryPresented)
    #expect(state.isConnectPresented == false)
    #expect(state.selectedTab == .home)
    #expect(state.feedState.selectedSpaceId == pair.id)
}

@Test("같은 그룹을 다시 열면 이미 불러온 멤버를 유지하고 피드는 새로 불러온다")
func reopeningSameGroupKeepsMembers() {
    let groupA = group("A")
    var state = mainState([groupA])
    state.open(groupA)
    state.groupDetail?.members = [SpaceMember(user: partner, role: .owner, joinedAt: Date(), latestMoment: nil)]
    state.feedState.moments = [Moment(id: UUID(), spaceId: groupA.id, author: partner, text: "글", createdAt: Date())]

    state.open(groupA)

    #expect(state.groupDetail?.members.count == 1)
    #expect(state.feedState.moments.isEmpty)
    #expect(state.feedState.selectedSpaceId == groupA.id)
}

// MARK: - 작성 후

@Test("그룹 A 상세에서 작성 탭으로 가 그룹 B로 보내면 A 상세와 설정을 닫는다")
func sharingToAnotherSpaceClosesDetail() {
    let groupA = group("A")
    let groupB = group("B")
    var state = mainState([groupA, groupB])
    state.open(groupA)
    state.groupSettings = GroupSettingsFeature.State(space: groupA, currentUserId: me.id)

    state.closeScreens(notShowing: groupB.id)

    #expect(state.groupDetail == nil)
    #expect(state.groupSettings == nil)
}

@Test("열려 있는 그룹 상세와 같은 그룹으로 보내면 상세와 설정을 그대로 둔다")
func sharingToSameGroupKeepsDetail() {
    let groupA = group("A")
    var state = mainState([groupA])
    state.open(groupA)
    state.groupSettings = GroupSettingsFeature.State(space: groupA, currentUserId: me.id)

    state.closeScreens(notShowing: groupA.id)

    #expect(state.groupDetail?.space.id == groupA.id)
    #expect(state.groupSettings != nil)
}

@Test("1:1 히스토리가 열린 채로 그룹에 보내면 히스토리를 닫는다")
func sharingToGroupClosesOneToOneHistory() {
    let pair = oneToOne()
    let groupA = group("A")
    var state = mainState([pair, groupA])
    state.open(pair)

    state.closeScreens(notShowing: groupA.id)
    #expect(state.isHistoryPresented == false)

    state.open(pair)
    state.closeScreens(notShowing: pair.id)
    #expect(state.isHistoryPresented)
}

@Test("상대가 1:1 연결을 끊어 목록에서 사라지면 열려 있던 지난 순간 화면을 닫는다")
func historyClosesWhenOneToOneDisappears() {
    let pair = oneToOne()
    let groupA = group("A")
    var state = mainState([pair, groupA])
    state.open(pair)
    #expect(state.isHistoryPresented)

    state.apply(spaces: [groupA])

    #expect(state.isHistoryPresented == false)
    #expect(state.feedState.selectedSpaceId == nil)
}
