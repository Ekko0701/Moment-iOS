import Foundation
import Testing
@testable import Domain

@Test("스페이스는 멤버와 생성일을 보존한다")
func spaceKeepsMembersAndCreatedAt() {
    let me = UserProfile(id: UUID(), handle: "moment_1", nickname: "동주")
    let partner = UserProfile(id: UUID(), handle: "moment_2", nickname: "지은")
    let createdAt = Date(timeIntervalSince1970: 1_700_000_000)

    let space = Space(id: UUID(), type: .oneToOne, maxMembers: 2,
                      status: "ACTIVE", members: [me, partner], createdAt: createdAt)

    #expect(space.members.count == 2)
    #expect(space.type == .oneToOne)
    #expect(space.createdAt == createdAt)
}

@Test("초대 상태는 서버 계약의 소문자 rawValue를 사용한다")
func invitationStatusRawValues() {
    #expect(InvitationStatus.pending.rawValue == "pending")
    #expect(InvitationStatus.accepted.rawValue == "accepted")
    #expect(InvitationVia.code.rawValue == "CODE")
}

@Test("모먼트는 텍스트만으로 생성할 수 있다")
func momentWithTextOnly() {
    let author = UserProfile(id: UUID(), handle: "moment_1", nickname: "지은")
    let moment = Moment(id: UUID(), spaceId: UUID(), author: author,
                        text: "안녕", createdAt: Date())
    #expect(moment.imageURL == nil)
    #expect(moment.text == "안녕")
    #expect(moment.reactions.isEmpty)
}
