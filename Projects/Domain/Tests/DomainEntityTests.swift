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
