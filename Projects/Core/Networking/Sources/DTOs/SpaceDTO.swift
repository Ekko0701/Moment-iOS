import Foundation
import Domain

/// 서버 SpaceResponse 매핑: { id, name, type, status, connectedAt(epoch ms), members: [{userId, handle, nickname, profileImageUrl, joinedAt}] }
struct SpaceDTO: Decodable {
    let id: String
    /// 사용자가 붙인 공간 이름. 미지정이면 null — 화면은 "OO님과의 스페이스"로 폴백한다
    let name: String?
    let type: String
    let status: String
    let connectedAt: Int64
    let members: [MemberDTO]

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
            maxMembers: spaceType == .oneToOne ? 2 : members.count,
            status: status,
            members: members.map { $0.toDomainModel() },
            createdAt: Date(timeIntervalSince1970: TimeInterval(connectedAt) / 1000)
        )
    }
}
