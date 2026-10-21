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

// MARK: - 참여 요청

private func joinRequest(spaceName: String = "주말 산책") -> GroupJoinRequest {
    GroupJoinRequest(id: UUID(), spaceId: UUID(), spaceName: spaceName, status: .pending, createdAt: Date())
}

@Test("참여 요청을 보내면 대기 안내로 바뀌고, 다시 제출할 수 없으며 확인을 누르면 요청을 넘긴다")
func joinRequestSentShowsWaiting() {
    var state = GroupJoinFeature.State()
    state.code = "ABC123"
    state.isSubmitting = true
    let request = joinRequest()

    _ = GroupJoinFeature().reduce(into: &state, action: .joinResponse(.success(request)))

    #expect(state.sentRequest == request)
    #expect(state.isSubmitting == false)
    #expect(state.canSubmit == false)
}

@Test("요청을 보내는 중에는 취소로 시트를 닫지 않는다")
func joinCancelIgnoredWhileSubmitting() {
    var state = GroupJoinFeature.State()
    state.isSubmitting = true
    _ = GroupJoinFeature().reduce(into: &state, action: .cancelTapped)
    #expect(state.isSubmitting)

    var creating = GroupCreateFeature.State()
    creating.isSubmitting = true
    _ = GroupCreateFeature().reduce(into: &creating, action: .cancelTapped)
    #expect(creating.isSubmitting)
}

// MARK: - 설정: 알림·코드·참여 요청

@Test("알림 저장이 끝나기 전의 토글은 무시해 요청 순서가 뒤집히지 않게 한다")
func notificationToggleSerialized() {
    var state = GroupSettingsFeature.State(space: space(notifications: true), currentUserId: UUID())

    _ = GroupSettingsFeature().reduce(into: &state, action: .notificationsToggled(false))
    #expect(state.isUpdatingNotifications)
    #expect(state.notificationsEnabled == false)

    _ = GroupSettingsFeature().reduce(into: &state, action: .notificationsToggled(true))
    #expect(state.notificationsEnabled == false)

    _ = GroupSettingsFeature().reduce(into: &state, action: .notificationsResponse(.success(false)))
    #expect(state.isUpdatingNotifications == false)
    #expect(state.space.notificationsEnabled == false)
}

@Test("코드가 없으면(notFound) 조용히 넘어가고, 그 밖의 조회 실패는 알린다")
func codeLoadFailureDistinguishesMissingCode() {
    var state = GroupSettingsFeature.State(space: space(role: .member), currentUserId: UUID())

    _ = GroupSettingsFeature().reduce(into: &state, action: .codeLoaded(.failure(.notFound(message: "코드 없음"))))
    #expect(state.error == nil)

    _ = GroupSettingsFeature().reduce(into: &state, action: .codeLoaded(.failure(.unknown(code: "E", message: "서버 오류"))))
    #expect(state.error != nil)
}

@Test("방장이 요청을 수락하면 목록과 대기 수에서 빠지고, 같은 요청을 처리 중에는 다시 누를 수 없다")
func decideJoinRequestUpdatesList() {
    var state = GroupSettingsFeature.State(space: space(role: .owner), currentUserId: UUID())
    let request = PendingJoinRequest(id: UUID(), user: UserProfile(id: UUID(), handle: "c", nickname: "씨씨"),
                                     createdAt: Date())
    state.joinRequests = [request]

    _ = GroupSettingsFeature().reduce(into: &state, action: .decideJoinRequestTapped(request, approve: true))
    #expect(state.decidingRequestIds.contains(request.id))
    _ = GroupSettingsFeature().reduce(into: &state, action: .decideJoinRequestTapped(request, approve: true))
    #expect(state.decidingRequestIds.count == 1)

    _ = GroupSettingsFeature().reduce(
        into: &state, action: .decideJoinRequestResponse(requestId: request.id, approve: true, .success(())))
    #expect(state.joinRequests.isEmpty)
    #expect(state.decidingRequestIds.isEmpty)
    #expect(state.space.pendingJoinRequestCount == 0)
}

@Test("방장이 아니면 참여 요청을 처리하지 않는다")
func memberCannotDecideJoinRequest() {
    var state = GroupSettingsFeature.State(space: space(role: .member), currentUserId: UUID())
    let request = PendingJoinRequest(id: UUID(), user: UserProfile(id: UUID(), handle: "c", nickname: "씨씨"),
                                     createdAt: Date())
    _ = GroupSettingsFeature().reduce(into: &state, action: .decideJoinRequestTapped(request, approve: true))
    #expect(state.decidingRequestIds.isEmpty)
}
