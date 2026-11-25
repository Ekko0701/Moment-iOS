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

private func spaceCreated(at date: Date) -> Space {
    Space(id: UUID(), type: .oneToOne, maxMembers: 2, status: "ACTIVE", members: [], createdAt: date)
}

private let seoul: Calendar = {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "Asia/Seoul")!
    return calendar
}()

private func seoulDate(_ y: Int, _ m: Int, _ d: Int, _ h: Int, _ min: Int) -> Date {
    seoul.date(from: DateComponents(year: y, month: m, day: d, hour: h, minute: min))!
}

@Test("함께한 날: 연결한 날은 1일차")
func daysTogetherStartsAtOne() {
    let created = seoulDate(2026, 11, 14, 9, 0)
    #expect(spaceCreated(at: created).daysTogether(now: seoulDate(2026, 11, 14, 22, 0), calendar: seoul) == 1)
}

@Test("함께한 날: 24시간이 안 돼도 날짜가 바뀌면 하루 늘어난다")
func daysTogetherCountsCalendarDays() {
    let created = seoulDate(2026, 11, 14, 23, 50)
    #expect(spaceCreated(at: created).daysTogether(now: seoulDate(2026, 11, 15, 0, 10), calendar: seoul) == 2)
    #expect(spaceCreated(at: created).daysTogether(now: seoulDate(2026, 11, 24, 8, 0), calendar: seoul) == 11)
}

@Test("스페이스 표시 이름: 붙인 이름 → 1:1 상대 닉네임 → 기본 이름")
func spaceDisplayName() {
    let me = UserProfile(id: UUID(), handle: "m_me", nickname: "동주")
    let partner = UserProfile(id: UUID(), handle: "m_p", nickname: "지은")
    let named = Space(id: UUID(), type: .oneToOne, name: "우리집", maxMembers: 2, status: "ACTIVE",
                      members: [me, partner], createdAt: Date())
    #expect(named.displayName(myUserId: me.id) == "우리집")

    let unnamed = Space(id: UUID(), type: .oneToOne, name: "  ", maxMembers: 2, status: "ACTIVE",
                        members: [me, partner], createdAt: Date())
    #expect(unnamed.displayName(myUserId: me.id) == "지은님과의 스페이스")

    let alone = Space(id: UUID(), type: .oneToOne, maxMembers: 2, status: "ACTIVE", members: [], createdAt: Date())
    #expect(alone.displayName(myUserId: me.id) == "우리 둘의 스페이스")

    let group = Space(id: UUID(), type: .group, maxMembers: 6, status: "ACTIVE", members: [me, partner],
                      createdAt: Date())
    #expect(group.displayName(myUserId: me.id) == "그룹")
}

@Test("사진 위 글씨: 사진과 글이 함께 있을 때만 있고, 스타일이 없으면 왼쪽 위·흰색")
func momentPhotoText() {
    let author = UserProfile(id: UUID(), handle: "m_a", nickname: "지은")
    let url = URL(string: "https://example.com/a.jpg")

    let styled = Moment(id: UUID(), spaceId: UUID(), author: author, imageURL: url, text: "노을",
                        textStyle: MomentTextStyle(position: .bottom, color: .butter), createdAt: Date())
    #expect(styled.photoText == "노을")
    #expect(styled.photoTextStyle == MomentTextStyle(position: .bottom, color: .butter))

    let legacy = Moment(id: UUID(), spaceId: UUID(), author: author, imageURL: url, text: "노을", createdAt: Date())
    #expect(legacy.photoText == "노을")
    #expect(legacy.photoTextStyle == .standard)

    let textOnly = Moment(id: UUID(), spaceId: UUID(), author: author, text: "글만", createdAt: Date())
    #expect(textOnly.photoText == nil)

    let photoOnly = Moment(id: UUID(), spaceId: UUID(), author: author, imageURL: url, text: "", createdAt: Date())
    #expect(photoOnly.photoText == nil)
}

@Test("내 반응을 바꿔도 사진 위 글씨 스타일은 그대로다")
func reactionKeepsTextStyle() {
    let author = UserProfile(id: UUID(), handle: "m_a", nickname: "지은")
    let style = MomentTextStyle(position: .bottom, color: .lilac)
    let moment = Moment(id: UUID(), spaceId: UUID(), author: author,
                        imageURL: URL(string: "https://example.com/a.jpg"), text: "노을",
                        textStyle: style, createdAt: Date())
    #expect(moment.withMyReaction("❤️").textStyle == style)
}
