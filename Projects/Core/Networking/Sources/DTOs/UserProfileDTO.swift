import Foundation
import Domain

/// 서버 사용자 요약 DTO.
/// `/v1/users/me`는 `id`, 검색·counterpart·member는 `userId` 키를 사용하므로 둘 다 수용한다.
struct UserProfileDTO: Decodable {
    let id: UUID
    let handle: String
    let nickname: String
    let profileImageUrl: String?

    private enum CodingKeys: String, CodingKey {
        case id, userId, handle, nickname, profileImageUrl
    }

    // 엔드포인트마다 id 또는 userId 키를 쓴다. 둘 다 없거나 UUID 형식이 아니면 디코딩 오류로 드러낸다
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let userId = try container.decodeIfPresent(UUID.self, forKey: .userId) {
            id = userId
        } else {
            id = try container.decode(UUID.self, forKey: .id)
        }
        handle = try container.decode(String.self, forKey: .handle)
        nickname = try container.decode(String.self, forKey: .nickname)
        profileImageUrl = try container.decodeIfPresent(String.self, forKey: .profileImageUrl)
    }

    func toDomainModel() -> UserProfile {
        UserProfile(
            id: id,
            handle: handle,
            nickname: nickname,
            profileImageURL: profileImageUrl.flatMap { URL(string: $0) }
        )
    }
}
