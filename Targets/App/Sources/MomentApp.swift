import SwiftUI
import ComposableArchitecture
import Domain
import Networking

@main
struct MomentApp: App {
    // TCA Store는 앱 수명 동안 단일 인스턴스여야 하므로 static으로 보관한다.
    static let store: StoreOf<AppFeature> = {
        let apiClient = NetworkingLive.apiClient
        return Store(initialState: .launching) {
            AppFeature(
                userRepository: UserRepositoryImpl(apiClient: apiClient),
                spaceRepository: SpaceRepositoryImpl(apiClient: apiClient),
                momentRepository: MomentRepositoryImpl(apiClient: apiClient)
            )
        }
    }()

    var body: some Scene {
        WindowGroup {
            AppView(store: Self.store)
        }
    }
}
