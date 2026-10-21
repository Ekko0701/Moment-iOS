import Foundation
import Domain

/// 서버 SpaceResponse 매핑:
/// { id, name, type, status, connectedAt(epoch ms), members: [{userId, handle, nickname, profileImageUrl, joinedAt}],
///   myRole, maxMembers, memberCount, notificationsEnabled, latestMoment, pendingJoinRequestCount }
/// myRole 이후 필드는 없을 수 있으며, 없으면 1:1 기준 기본값으로 읽는다.
struct SpaceDTO: Decodable {
    let id: UUID
    /// 사용자가 붙인 공간 이름. 1:1에서 미지정이면 null — 화면은 "OO님과의 스페이스"로 폴백한다
    let name: String?
    let type: String
    let status: String
    let connectedAt: Int64
    let members: [MemberDTO]
    let myRole: String?
    let maxMembers: Int?
    let notificationsEnabled: Bool?
    let latestMoment: MomentDTO?
    let pendingJoinRequestCount: Int?

    struct MemberDTO: Decodable {
        let userId: UUID
        let handle: String
        let nickname: String
        let profileImageUrl: String?

        func toDomainModel() -> UserProfile {
            UserProfile(
                id: userId,
                handle: handle,
                nickname: nickname,
                profileImageURL: profileImageUrl.flatMap { URL(string: $0) }
            )
        }
    }

    /// 앱이 다루는 유형(1:1·그룹)이 아니면 nil. 모르는 유형을 1:1로 오인하지 않게 목록에서 뺀다
    func toDomainModel() -> Space? {
        guard let spaceType = SpaceType(rawValue: type.uppercased()),
              spaceType == .oneToOne || spaceType == .group else { return nil }
        return Space(
            id: id,
            type: spaceType,
            name: name,
            maxMembers: maxMembers ?? (spaceType == .oneToOne ? 2 : members.count),
            status: status,
            members: members.map { $0.toDomainModel() },
            createdAt: Date(timeIntervalSince1970: TimeInterval(connectedAt) / 1000),
            myRole: myRole.flatMap { MemberRole(rawValue: $0) } ?? .member,
            notificationsEnabled: notificationsEnabled ?? true,
            latestMoment: latestMoment?.toDomainModel(),
            pendingJoinRequestCount: pendingJoinRequestCount ?? 0
        )
    }
}

/// 서버 JoinRequestResponse 매핑: { id, spaceId, spaceName, status, createdAt(epoch ms) }
struct JoinRequestDTO: Decodable {
    let id: UUID
    let spaceId: UUID
    let spaceName: String
    let status: String
    let createdAt: Int64

    func toDomainModel() -> GroupJoinRequest {
        GroupJoinRequest(
            id: id,
            spaceId: spaceId,
            spaceName: spaceName,
            status: JoinRequestStatus(rawValue: status) ?? .pending,
            createdAt: Date(timeIntervalSince1970: TimeInterval(createdAt) / 1000)
        )
    }
}

/// 서버 PendingJoinRequestResponse 매핑: { id, userId, handle, nickname, profileImageUrl, createdAt(epoch ms) }
struct PendingJoinRequestDTO: Decodable {
    let id: UUID
    let userId: UUID
    let handle: String
    let nickname: String
    let profileImageUrl: String?
    let createdAt: Int64

    func toDomainModel() -> PendingJoinRequest {
        PendingJoinRequest(
            id: id,
            user: UserProfile(
                id: userId,
                handle: handle,
                nickname: nickname,
                profileImageURL: profileImageUrl.flatMap { URL(string: $0) }
            ),
            createdAt: Date(timeIntervalSince1970: TimeInterval(createdAt) / 1000)
        )
    }
}

/// 서버 GroupMemberResponse 매핑: { userId, handle, nickname, profileImageUrl, role, joinedAt(epoch ms), latestMoment }
struct SpaceMemberDTO: Decodable {
    let userId: UUID
    let handle: String
    let nickname: String
    let profileImageUrl: String?
    let role: String
    let joinedAt: Int64
    let latestMoment: MomentDTO?

    func toDomainModel() -> SpaceMember {
        SpaceMember(
            user: UserProfile(
                id: userId,
                handle: handle,
                nickname: nickname,
                profileImageURL: profileImageUrl.flatMap { URL(string: $0) }
            ),
            role: MemberRole(rawValue: role) ?? .member,
            joinedAt: Date(timeIntervalSince1970: TimeInterval(joinedAt) / 1000),
            latestMoment: latestMoment?.toDomainModel()
        )
    }
}

/// 서버 IssueCodeResponse 매핑: { code, expiresAt(ISO-8601) }
struct GroupInviteCodeDTO: Decodable {
    let code: String
    let expiresAt: Date

    func toDomainModel() -> GroupInviteCode {
        GroupInviteCode(code: code, expiresAt: expiresAt)
    }
}

/// 서버 CreateGroupResponse 매핑: { space, inviteCode, expiresAt }
struct CreateGroupDTO: Decodable {
    let space: SpaceDTO
    let inviteCode: String
    let expiresAt: Date

    func toDomainModel() throws -> CreatedGroup {
        guard let group = space.toDomainModel() else {
            throw DomainError.unknown(code: "INVALID_RESPONSE", message: "서버 응답을 읽을 수 없어요.")
        }
        return CreatedGroup(space: group, inviteCode: GroupInviteCode(code: inviteCode, expiresAt: expiresAt))
    }
}
