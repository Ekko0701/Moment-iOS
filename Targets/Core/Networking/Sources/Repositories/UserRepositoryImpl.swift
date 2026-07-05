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
        // Stub - will implement when available
    }
}

struct UserProfileResponseDTO: Decodable {
    let id: String
    let handle: String
    let nickname: String
    let profileImageURL: String?
    let isSearchable: Bool?

    func toDomainModel() -> UserProfile {
        UserProfile(
            id: UUID(uuidString: id) ?? UUID(),
            handle: handle,
            nickname: nickname,
            profileImageURL: profileImageURL.flatMap { URL(string: $0) },
            isSearchable: isSearchable ?? true
        )
    }
}
