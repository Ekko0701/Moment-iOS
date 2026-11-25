import SwiftUI
import UIKit
import CoreKit
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

    init() {
        Self.applyPretendardToSystemBars()
    }

    var body: some Scene {
        WindowGroup {
            AppView(store: Self.store)
                // 글꼴을 따로 지정하지 않은 글자도 Pretendard로 그린다
                .environment(\.font, .pretendard(.body))
        }
    }

    /// 내비게이션 바 제목, 바 버튼, 탭 바 라벨은 UIKit이 그리므로 외형 프록시로 글꼴을 맞춘다
    private static func applyPretendardToSystemBars() {
        let navigationBar = UINavigationBar.appearance()
        navigationBar.titleTextAttributes = [.font: UIFont.pretendard(size: 17, weight: .semibold)]
        navigationBar.largeTitleTextAttributes = [.font: UIFont.pretendard(size: 34, weight: .bold)]

        let barButtonFont: [NSAttributedString.Key: Any] = [.font: UIFont.pretendard(size: 17, weight: .regular)]
        UIBarButtonItem.appearance().setTitleTextAttributes(barButtonFont, for: .normal)
        UIBarButtonItem.appearance().setTitleTextAttributes(barButtonFont, for: .highlighted)

        let tabFont: [NSAttributedString.Key: Any] = [.font: UIFont.pretendard(size: 10, weight: .medium)]
        UITabBarItem.appearance().setTitleTextAttributes(tabFont, for: .normal)
        UITabBarItem.appearance().setTitleTextAttributes(tabFont, for: .selected)
    }
}
