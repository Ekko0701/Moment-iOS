import Foundation
import Testing
import Domain
@testable import Networking

@Test("그룹 엔드포인트는 서버 계약 경로·메서드를 쓴다")
func groupEndpoints() {
    let spaceId = UUID()
    let userId = UUID()
    #expect(GroupEndpoints.create(name: "가족").path == "/v1/groups")
    #expect(GroupEndpoints.create(name: "가족").method == .post)
    #expect(GroupEndpoints.join(code: "ABC123").path == "/v1/groups/join")
    #expect(GroupEndpoints.inviteCode(spaceId: spaceId).method == .get)
    #expect(GroupEndpoints.reissueInviteCode(spaceId: spaceId).method == .post)
    #expect(GroupEndpoints.reissueInviteCode(spaceId: spaceId).path == "/v1/groups/\(spaceId.uuidString)/invite-code")
    #expect(GroupEndpoints.delete(spaceId: spaceId).method == .delete)
    #expect(SpaceMemberEndpoints.list(spaceId: spaceId).path == "/v1/spaces/\(spaceId.uuidString)/members")
    #expect(SpaceMemberEndpoints.remove(spaceId: spaceId, userId: userId).path
            == "/v1/spaces/\(spaceId.uuidString)/members/\(userId.uuidString)")
    #expect(SpaceMemberEndpoints.updateMine(spaceId: spaceId, notificationsEnabled: false).method == .patch)
}

@Test("그룹 필드가 없는 이전 형식의 스페이스 응답도 1:1 기본값으로 읽는다")
func spaceDTODecodesLegacyPayload() throws {
    let json = """
    {"id":"\(UUID().uuidString)","name":null,"type":"ONE_TO_ONE","status":"ACTIVE","connectedAt":1700000000000,
     "members":[{"userId":"\(UUID().uuidString)","handle":"a","nickname":"에이","profileImageUrl":null,"joinedAt":1}]}
    """
    let space = try JSONDecoder().decode(SpaceDTO.self, from: Data(json.utf8)).toDomainModel()
    #expect(space.type == .oneToOne)
    #expect(space.maxMembers == 2)
    #expect(space.myRole == .member)
    #expect(space.notificationsEnabled)
    #expect(space.latestMoment == nil)
}

@Test("그룹 스페이스 응답은 역할·정원·알림·최신 모먼트를 매핑한다")
func spaceDTODecodesGroupPayload() throws {
    let spaceId = UUID()
    let authorId = UUID()
    let json = """
    {"id":"\(spaceId.uuidString)","name":"주말 산책","type":"GROUP","status":"ACTIVE","connectedAt":1700000000000,
     "members":[],"myRole":"OWNER","maxMembers":6,"memberCount":0,"notificationsEnabled":false,
     "latestMoment":{"id":"\(UUID().uuidString)","spaceId":"\(spaceId.uuidString)",
       "author":{"userId":"\(authorId.uuidString)","handle":"b","nickname":"비비","profileImageUrl":null},
       "imageUrl":null,"text":"산책 시작","createdAtMs":1700000000000,"reactions":[],"myReaction":null}}
    """
    let space = try JSONDecoder().decode(SpaceDTO.self, from: Data(json.utf8)).toDomainModel()
    #expect(space.isGroup)
    #expect(space.isOwner)
    #expect(space.maxMembers == 6)
    #expect(space.notificationsEnabled == false)
    #expect(space.latestMoment?.author.id == authorId)
    #expect(space.latestMoment?.text == "산책 시작")
}

@Test("그룹 멤버 응답은 역할과 멤버별 최신 모먼트 유무를 매핑한다")
func spaceMemberDTODecodes() throws {
    let json = """
    [{"userId":"\(UUID().uuidString)","handle":"a","nickname":"방장","profileImageUrl":null,"role":"OWNER",
      "joinedAt":1700000000000,"latestMoment":null}]
    """
    let members = try JSONDecoder().decode([SpaceMemberDTO].self, from: Data(json.utf8)).map { $0.toDomainModel() }
    #expect(members.count == 1)
    #expect(members[0].role == .owner)
    #expect(members[0].latestMoment == nil)
}

@Test("참여 요청 엔드포인트는 서버 계약 경로·메서드·action 값을 쓴다")
func joinRequestEndpoints() throws {
    let spaceId = UUID()
    let requestId = UUID()
    #expect(GroupEndpoints.myJoinRequests().path == "/v1/groups/join-requests/me")
    #expect(GroupEndpoints.joinRequests(spaceId: spaceId).path == "/v1/groups/\(spaceId.uuidString)/join-requests")
    let approve = GroupEndpoints.decideJoinRequest(spaceId: spaceId, requestId: requestId, approve: true)
    #expect(approve.method == .patch)
    #expect(approve.path == "/v1/groups/\(spaceId.uuidString)/join-requests/\(requestId.uuidString)")
    let body = try #require(approve.body as? DecideJoinRequestBody)
    #expect(body.action == "approve")
    let reject = try #require(
        GroupEndpoints.decideJoinRequest(spaceId: spaceId, requestId: requestId, approve: false).body
            as? DecideJoinRequestBody)
    #expect(reject.action == "reject")
    #expect(GroupEndpoints.cancelJoinRequest(spaceId: spaceId, requestId: requestId).method == .delete)
}

@Test("참여 요청 응답과 방장용 대기 요청 응답을 매핑한다")
func joinRequestDTOsDecode() throws {
    let spaceId = UUID()
    let request = try JSONDecoder().decode(JoinRequestDTO.self, from: Data("""
    {"id":"\(UUID().uuidString)","spaceId":"\(spaceId.uuidString)","spaceName":"주말 산책","status":"PENDING",
     "createdAt":1700000000000}
    """.utf8)).toDomainModel()
    #expect(request.spaceId == spaceId)
    #expect(request.status == .pending)

    let pending = try JSONDecoder().decode(PendingJoinRequestDTO.self, from: Data("""
    {"id":"\(UUID().uuidString)","userId":"\(UUID().uuidString)","handle":"c","nickname":"씨씨",
     "profileImageUrl":null,"createdAt":1700000000000}
    """.utf8)).toDomainModel()
    #expect(pending.user.nickname == "씨씨")
}
