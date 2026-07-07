import Foundation
import Domain

public final class UserRepositoryImpl: UserRepositoryProtocol {
    private let apiClient: APIClientProtocol

    public init(apiClient: APIClientProtocol) {
        self.apiClient = apiClient
    }

    public func me() async throws -> UserProfile {
        let endpoint = UserEndpoints.getProfile()
        let dto: UserProfileResponseDTO = try await apiClient.request(endpoint)
        return dto.toDomainModel()
    }

    public func updateMe(nickname: String?, profileImageKey: String?) async throws -> UserProfile {
        let endpoint = UserEndpoints.updateProfile(nickname: nickname, profileImageUrl: profileImageKey)
        let dto: UserProfileResponseDTO = try await apiClient.request(endpoint)
        return dto.toDomainModel()
    }

    public func search(handle: String) async throws -> UserProfile {
        let endpoint = UserEndpoints.search(handle: handle)
        let dto: UserProfileResponseDTO = try await apiClient.request(endpoint)
        return dto.toDomainModel()
    }

    public func deleteMe() async throws {
        // 서버 계약: DELETE /v1/users/me
        let endpoint = UserEndpoints.deleteMe()
        try await apiClient.requestVoid(endpoint)
    }
}

/// 서버 사용자 응답 매핑 — /users/me는 `id`, /users/search는 `userId` 키를 쓰므로 둘 다 수용.
/// 이미지 키는 서버 표기 그대로 `profileImageUrl`.
struct UserProfileResponseDTO: Decodable {
    let id: String?
    let userId: String?
    let handle: String
    let nickname: String
    let profileImageUrl: String?
    let isSearchable: Bool?

    func toDomainModel() -> UserProfile {
        UserProfile(
            id: UUID(uuidString: userId ?? id ?? "") ?? UUID(),
            handle: handle,
            nickname: nickname,
            profileImageURL: profileImageUrl.flatMap { URL(string: $0) },
            isSearchable: isSearchable ?? true
        )
    }
}
