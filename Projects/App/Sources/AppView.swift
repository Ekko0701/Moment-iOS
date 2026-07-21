import SwiftUI
import ComposableArchitecture
import Domain
import AuthFeature
import ConnectFeature
import HomeFeature
import FeedFeature
import ComposeFeature
import SettingsFeature
import MomentUIKit

struct AppView: View {
    let store: StoreOf<AppFeature>

    var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            ZStack {
                switch viewStore.state {
                case .launching:
                    ProgressView()
                        .onAppear {
                            viewStore.send(.onAppear)
                        }

                case .auth(let authState):
                    AuthView(state: authState, send: { viewStore.send(.auth($0)) })

                case .connect(let connectState):
                    ConnectView(
                        state: connectState,
                        send: { viewStore.send(.connect($0)) },
                        onRefresh: { viewStore.send(.refreshConnection) }
                    )

                case .main(let mainTabState):
                    mainTabView(viewStore, mainTabState)
                }
            }
            .onOpenURL { url in
                handleDeepLink(url, viewStore: viewStore)
            }
        }
    }

    private func handleDeepLink(_ url: URL, viewStore: ViewStoreOf<AppFeature>) {
        guard url.scheme == "moment" else { return }

        if url.host == "login" {
            if case .auth = viewStore.state {
                return
            }
        } else if url.host == "connect" {
            if case .connect = viewStore.state {
                return
            }
        } else if url.host == "moment" {
            let pathComponents = url.pathComponents.filter { $0 != "/" }
            if let momentIdString = pathComponents.last,
               UUID(uuidString: momentIdString) != nil {
                viewStore.send(.selectTab(.home))
                viewStore.send(.setHistoryPresented(true))
                viewStore.send(.feed(.refresh))
            }
        }
    }

    // MARK: - Main Tab View
    private func mainTabView(_ viewStore: ViewStoreOf<AppFeature>, _ mainTabState: AppFeature.MainTabState) -> some View {
        TabView(selection: Binding(
            get: { mainTabState.selectedTab },
            set: { viewStore.send(.selectTab($0)) }
        )) {
            homeTabView(viewStore, mainTabState)
            composeTabView(viewStore, mainTabState)
            settingsTabView(viewStore, mainTabState)
        }
        .tint(MomentColor.accent)
    }

    // MARK: - Home Tab
    private func homeTabView(_ viewStore: ViewStoreOf<AppFeature>, _ mainTabState: AppFeature.MainTabState) -> some View {
        NavigationStack {
            HomeView(state: mainTabState.homeState, send: { viewStore.send(.home($0)) })
                .navigationDestination(
                    isPresented: Binding(
                        get: { mainTabState.isHistoryPresented },
                        set: { viewStore.send(.setHistoryPresented($0)) }
                    )
                ) {
                    FeedView(
                        state: mainTabState.feedState,
                        send: { viewStore.send(.feed($0)) },
                        currentUserId: mainTabState.currentUser?.id
                    )
                        .navigationTitle(
                            "\(mainTabState.homeState.partner?.nickname ?? "우리")님과의 스페이스"
                        )
                }
        }
        .tabItem {
            Label("Home", systemImage: "house")
        }
        .tag(AppFeature.MainTabState.Tab.home)
    }

    // MARK: - Compose Tab
    private func composeTabView(_ viewStore: ViewStoreOf<AppFeature>, _ mainTabState: AppFeature.MainTabState) -> some View {
        NavigationStack {
            ComposeView(state: mainTabState.composeState, send: { viewStore.send(.compose($0)) })
        }
        .tabItem {
            Label("Compose", systemImage: "plus")
        }
        .tag(AppFeature.MainTabState.Tab.compose)
    }

    // MARK: - Settings Tab
    private func settingsTabView(_ viewStore: ViewStoreOf<AppFeature>, _ mainTabState: AppFeature.MainTabState) -> some View {
        NavigationStack {
            SettingsView(
                state: mainTabState.settingsState,
                send: { viewStore.send(.settings($0)) },
                currentUser: mainTabState.currentUser,
                currentSpace: mainTabState.currentSpace
            )
        }
        .tabItem {
            Label("Settings", systemImage: "gear")
        }
        .tag(AppFeature.MainTabState.Tab.settings)
    }
}
