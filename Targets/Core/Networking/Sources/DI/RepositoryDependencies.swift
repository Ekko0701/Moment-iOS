import Dependencies
import Domain
import Foundation

/// 리포지토리 의존성의 단일 등록 지점.
/// 모든 Feature는 이 keypath(@Dependency(\.xxxRepository))로 도메인 프로토콜만 바라보고,
/// 라이브 구현(Alamofire 기반)은 Networking 모듈이 제공한다 (POP + 단일 세션 공유).
public enum NetworkingLive {
    public static let tokenStore = KeychainTokenStore()
    public static let apiClient = MomentAPIClient(tokenStore: tokenStore)
}

public extension DependencyValues {
    var authRepository: AuthRepositoryProtocol {
        get { self[AuthRepositoryKey.self] }
        set { self[AuthRepositoryKey.self] = newValue }
    }

    var userRepository: UserRepositoryProtocol {
        get { self[UserRepositoryKey.self] }
        set { self[UserRepositoryKey.self] = newValue }
    }

    var spaceRepository: SpaceRepositoryProtocol {
        get { self[SpaceRepositoryKey.self] }
        set { self[SpaceRepositoryKey.self] = newValue }
    }

    var momentRepository: MomentRepositoryProtocol {
        get { self[MomentRepositoryKey.self] }
        set { self[MomentRepositoryKey.self] = newValue }
    }
}

private enum AuthRepositoryKey: DependencyKey {
    static let liveValue: AuthRepositoryProtocol = AuthRepositoryImpl(
        apiClient: NetworkingLive.apiClient,
        tokenStore: NetworkingLive.tokenStore)
}

private enum UserRepositoryKey: DependencyKey {
    static let liveValue: UserRepositoryProtocol = UserRepositoryImpl(apiClient: NetworkingLive.apiClient)
}

private enum SpaceRepositoryKey: DependencyKey {
    static let liveValue: SpaceRepositoryProtocol = SpaceRepositoryImpl(apiClient: NetworkingLive.apiClient)
}

private enum MomentRepositoryKey: DependencyKey {
    static let liveValue: MomentRepositoryProtocol = MomentRepositoryImpl(apiClient: NetworkingLive.apiClient)
}
