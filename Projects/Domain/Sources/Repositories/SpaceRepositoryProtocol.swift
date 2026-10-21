import Foundation

public protocol SpaceRepositoryProtocol: Sendable {
    func mySpaces() async throws -> [Space]
    /// 공간 이름 변경. nil/공백을 넘기면 이름 없음 상태로 되돌아간다
    func rename(spaceId: UUID, name: String?) async throws
    func leave(spaceId: UUID) async throws
    func issueInviteCode() async throws -> String
    func sendInvitation(toUserId: UUID) async throws -> Invitation
    func sendInvitationByCode(code: String) async throws -> Invitation
    func invitations(direction: InvitationDirection) async throws -> [Invitation]
    func respond(to invitationId: UUID, action: InvitationAction) async throws

    // MARK: 그룹 스페이스
    func createGroup(name: String) async throws -> CreatedGroup
    /// 코드로 참여를 요청한다. 같은 그룹에 대기 중 요청이 있으면 그 요청이 돌아온다
    func requestJoinGroup(code: String) async throws -> GroupJoinRequest
    /// 내가 보낸 대기 중 요청
    func myJoinRequests() async throws -> [GroupJoinRequest]
    func cancelJoinRequest(spaceId: UUID, requestId: UUID) async throws
    /// 방장 전용. 그룹에 들어온 대기 중 요청
    func joinRequests(spaceId: UUID) async throws -> [PendingJoinRequest]
    /// 방장 전용. 수락하면 요청자가 멤버가 된다
    func decideJoinRequest(spaceId: UUID, requestId: UUID, approve: Bool) async throws
    func groupInviteCode(spaceId: UUID) async throws -> GroupInviteCode
    /// 방장 전용. 이전 코드는 즉시 무효가 된다
    func reissueGroupInviteCode(spaceId: UUID) async throws -> GroupInviteCode
    /// 활성 멤버와 멤버별 최신 모먼트. 방장이 먼저 온다
    func members(spaceId: UUID) async throws -> [SpaceMember]
    /// 방장 전용
    func removeMember(spaceId: UUID, userId: UUID) async throws
    func setNotifications(spaceId: UUID, enabled: Bool) async throws
    /// 방장 전용. 모든 멤버가 나가고 그룹이 종료된다
    func deleteGroup(spaceId: UUID) async throws
}

public enum InvitationDirection: Sendable {
    case received
    case sent
}

public enum InvitationAction: Sendable {
    case accept
    case decline
    case cancel
}
