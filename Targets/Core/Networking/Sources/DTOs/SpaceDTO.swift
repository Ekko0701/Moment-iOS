import Foundation
import Domain

/// 서버 SpaceResponse 매핑: { id, type, status, connectedAt(epoch ms), members: [{userId, handle, nickname, profileImageUrl, joinedAt}] }
struct SpaceDTO: Decodable {
    let id: String
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
            maxMembers: spaceType == .oneToOne ? 2 : members.count,
            status: status,
            members: members.map { $0.toDomainModel() },
            createdAt: Date(timeIntervalSince1970: TimeInterval(connectedAt) / 1000)
        )
    }
}
