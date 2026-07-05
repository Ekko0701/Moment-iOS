import Foundation
import Domain

struct UserProfileDTO: Decodable {
    let id: String
    let nickname: String
    let handle: String
    let profileImageURL: String?

    enum CodingKeys: String, CodingKey {
        case id
        case nickname
        case handle
        case profileImageURL
    }

    func toDomainModel() -> UserProfile {
        UserProfile(
            id: UUID(uuidString: id) ?? UUID(),
            nickname: nickname,
            handle: handle,
            profileImageURL: profileImageURL.flatMap { URL(string: $0) }
        )
    }
}
