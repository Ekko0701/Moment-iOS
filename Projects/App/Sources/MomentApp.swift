import SwiftUI
import ComposableArchitecture
import Dependencies
import Domain
import Networking

@main
struct MomentApp: App {
    // TCA Store는 앱 수명 동안 단일 인스턴스여야 하므로 static으로 보관한다.
    static let store: StoreOf<AppFeature> = {
        // 의존성 주입: Feature와 UseCase가 접근할 Repository들
        let apiClient = NetworkingLive.apiClient
        let tokenStore = NetworkingLive.tokenStore

        var dependencies = DependencyValues()
        dependencies.authRepository = AuthRepositoryImpl(apiClient: apiClient, tokenStore: tokenStore)
        dependencies.userRepository = UserRepositoryImpl(apiClient: apiClient)
        dependencies.spaceRepository = SpaceRepositoryImpl(apiClient: apiClient)
        dependencies.momentRepository = MomentRepositoryImpl(apiClient: apiClient)

        return Store(initialState: .launching) {
            AppFeature()
        } withDependencies: {
            $0 = dependencies
        }
    }()

    var body: some Scene {
        WindowGroup {
            AppView(store: Self.store)
        }
    }
}
