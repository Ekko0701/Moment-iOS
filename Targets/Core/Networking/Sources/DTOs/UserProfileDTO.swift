import Foundation
import Domain

/// 서버 사용자 요약 DTO.
/// `/v1/users/me`는 `id`, 검색·counterpart·member는 `userId` 키를 사용하므로 둘 다 수용한다.
struct UserProfileDTO: Decodable {
    let id: String?
    let userId: String?
    let handle: String
    let nickname: String
    let profileImageUrl: String?

    func toDomainModel() -> UserProfile {
        UserProfile(
            id: UUID(uuidString: userId ?? id ?? "") ?? UUID(),
            handle: handle,
            nickname: nickname,
            profileImageURL: profileImageUrl.flatMap { URL(string: $0) }
        )
    }
}
