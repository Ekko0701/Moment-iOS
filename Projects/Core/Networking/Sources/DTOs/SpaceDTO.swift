import Foundation
import Domain

/// 서버 SpaceResponse 매핑:
/// { id, name, type, status, connectedAt(epoch ms), members: [{userId, handle, nickname, profileImageUrl, joinedAt}],
///   myRole, maxMembers, memberCount, notificationsEnabled, latestMoment }
/// 뒤의 다섯 필드는 그룹 스페이스와 함께 추가됐다. 없으면 1:1 기준 기본값으로 읽는다.
struct SpaceDTO: Decodable {
    let id: String
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

    struct MemberDTO: Decodable {
        let userId: String
        let handle: String
        let nickname: String
        let profileImageUrl: String?

        func toDomainModel() -> UserProfile {
            UserProfile(
                id: UUID(uuidString: userId) ?? UUID(),
                handle: handle,
                nickname: nickname,
                profileImageURL: profileImageUrl.flatMap { URL(string: $0) }
            )
        }
    }

    func toDomainModel() -> Space {
        let spaceType = SpaceType(rawValue: type.uppercased()) ?? .oneToOne
        return Space(
            id: UUID(uuidString: id) ?? UUID(),
            type: spaceType,
            name: name,
            maxMembers: maxMembers ?? (spaceType == .oneToOne ? 2 : members.count),
            status: status,
            members: members.map { $0.toDomainModel() },
            createdAt: Date(timeIntervalSince1970: TimeInterval(connectedAt) / 1000),
            myRole: myRole.flatMap { MemberRole(rawValue: $0) } ?? .member,
            notificationsEnabled: notificationsEnabled ?? true,
            latestMoment: latestMoment?.toDomainModel()
        )
    }
}

/// 서버 GroupMemberResponse 매핑: { userId, handle, nickname, profileImageUrl, role, joinedAt(epoch ms), latestMoment }
struct SpaceMemberDTO: Decodable {
    let userId: String
    let handle: String
    let nickname: String
    let profileImageUrl: String?
    let role: String
    let joinedAt: Int64
    let latestMoment: MomentDTO?

    func toDomainModel() -> SpaceMember {
        SpaceMember(
            user: UserProfile(
                id: UUID(uuidString: userId) ?? UUID(),
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

    func toDomainModel() -> CreatedGroup {
        CreatedGroup(space: space.toDomainModel(),
                     inviteCode: GroupInviteCode(code: inviteCode, expiresAt: expiresAt))
    }
}
