import Foundation
import Testing
import Domain
@testable import GroupFeature

private func space(role: MemberRole = .owner, notifications: Bool = true) -> Space {
    Space(id: UUID(), type: .group, name: "주말 산책", maxMembers: 6, status: "ACTIVE", members: [],
          createdAt: Date(), myRole: role, notificationsEnabled: notifications)
}

private func member(_ name: String, role: MemberRole = .member, momentAt: Date? = nil) -> SpaceMember {
    let user = UserProfile(id: UUID(), handle: name, nickname: name)
    let moment = momentAt.map { Moment(id: UUID(), spaceId: UUID(), author: user, text: "글", createdAt: $0) }
    return SpaceMember(user: user, role: role, joinedAt: Date(), latestMoment: moment)
}

// MARK: - 만들기

@Test("그룹 이름은 10자에서 잘리고, 공백뿐이면 만들 수 없다")
func createNameRules() {
    var state = GroupCreateFeature.State()
    _ = GroupCreateFeature().reduce(into: &state, action: .nameChanged("열한글자가넘는그룹이름입니다"))
    #expect(state.name.count == 10)

    _ = GroupCreateFeature().reduce(into: &state, action: .nameChanged("   "))
    #expect(state.canSubmit == false)
}

@Test("생성 성공 후에는 코드 공유 단계가 되고 다시 제출할 수 없다")
func createSuccessShowsCode() {
    var state = GroupCreateFeature.State()
    state.name = "가족"
    state.isSubmitting = true
    let created = CreatedGroup(space: space(), inviteCode: GroupInviteCode(code: "ABC123", expiresAt: Date()))

    _ = GroupCreateFeature().reduce(into: &state, action: .createResponse(.success(created)))

    #expect(state.created == created)
    #expect(state.isSubmitting == false)
    #expect(state.canSubmit == false)
}

// MARK: - 참여

@Test("코드 입력은 영문·숫자만 남겨 대문자 6자리로 맞춘다")
func joinCodeNormalization() {
    var state = GroupJoinFeature.State()
    _ = GroupJoinFeature().reduce(into: &state, action: .codeChanged("ab c-12"))
    #expect(state.code == "ABC12")
    #expect(state.canSubmit == false)

    _ = GroupJoinFeature().reduce(into: &state, action: .codeChanged("abc1234xyz"))
    #expect(state.code == "ABC123")
    #expect(state.canSubmit)
}

@Test("참여 실패는 서버 메시지를 그대로 보여준다")
func joinFailureShowsError() {
    var state = GroupJoinFeature.State()
    state.isSubmitting = true
    _ = GroupJoinFeature().reduce(into: &state, action: .joinResponse(.failure(.conflict(message: "정원이 찼어요."))))
    #expect(state.error == .conflict(message: "정원이 찼어요."))
    #expect(state.isSubmitting == false)
}

// MARK: - 상세

@Test("멤버 스트립은 최신 모먼트가 있는 멤버를 최신순으로 앞에, 없는 멤버를 뒤에 둔다")
func detailOrdersMembers() {
    let older = member("older", momentAt: Date().addingTimeInterval(-3600))
    let newer = member("newer", momentAt: Date())
    let quiet = member("quiet", role: .owner)
    var state = GroupDetailFeature.State(space: space())
    state.members = [quiet, older, newer]

    #expect(state.orderedMembers.map(\.user.nickname) == ["newer", "older", "quiet"])
}

// MARK: - 설정

@Test("방장이 아니면 내보내기·종료 요청을 무시한다")
func settingsOwnerGating() {
    var state = GroupSettingsFeature.State(space: space(role: .member), currentUserId: UUID())
    _ = GroupSettingsFeature().reduce(into: &state, action: .removeMemberTapped(member("x")))
    _ = GroupSettingsFeature().reduce(into: &state, action: .deleteTapped)
    #expect(state.memberToRemove == nil)
    #expect(state.showDeleteConfirm == false)
}

@Test("방장이라도 자기 자신은 내보낼 수 없다")
func settingsCannotRemoveSelf() {
    let me = member("me", role: .owner)
    var state = GroupSettingsFeature.State(space: space(), currentUserId: me.user.id)
    _ = GroupSettingsFeature().reduce(into: &state, action: .removeMemberTapped(me))
    #expect(state.memberToRemove == nil)
}

@Test("알림 토글이 서버에서 실패하면 저장된 값으로 되돌린다")
func settingsNotificationRollback() {
    var state = GroupSettingsFeature.State(space: space(notifications: true), currentUserId: UUID())
    _ = GroupSettingsFeature().reduce(into: &state, action: .notificationsToggled(false))
    #expect(state.notificationsEnabled == false)

    _ = GroupSettingsFeature().reduce(into: &state, action: .notificationsResponse(.failure(.unknown(code: "E", message: "실패"))))
    #expect(state.notificationsEnabled == true)
}

@Test("이름 저장은 방장이 바뀐 이름을 입력했을 때만 가능하다")
func settingsRenameRules() {
    var owner = GroupSettingsFeature.State(space: space(), currentUserId: UUID())
    #expect(owner.canRename == false)
    owner.nameInput = "새 이름"
    #expect(owner.canRename)

    var member = GroupSettingsFeature.State(space: space(role: .member), currentUserId: UUID())
    member.nameInput = "새 이름"
    #expect(member.canRename == false)
}

// MARK: - 상세

@Test("다른 그룹으로 바뀐 뒤 도착한 이전 그룹의 멤버 응답은 버린다")
func detailDropsStaleMembers() {
    var state = GroupDetailFeature.State(space: space())
    state.isLoading = true

    _ = GroupDetailFeature().reduce(
        into: &state, action: .membersLoaded(spaceId: UUID(), .success([member("지은")])))
    #expect(state.members.isEmpty)
    #expect(state.isLoading)

    _ = GroupDetailFeature().reduce(
        into: &state, action: .membersLoaded(spaceId: state.space.id, .success([member("지은")])))
    #expect(state.members.count == 1)
    #expect(state.isLoading == false)
}
