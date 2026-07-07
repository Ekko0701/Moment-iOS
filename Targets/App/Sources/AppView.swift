import SwiftUI
import ComposableArchitecture
import Domain
import AuthFeature
import ConnectFeature
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
               let momentId = UUID(uuidString: momentIdString) {
                viewStore.send(.selectTab(.feed))
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
            feedTabView(viewStore, mainTabState)
            composeTabView(viewStore, mainTabState)
            settingsTabView(viewStore, mainTabState)
        }
        .tint(MomentColor.ink)
    }

    // MARK: - Feed Tab
    private func feedTabView(_ viewStore: ViewStoreOf<AppFeature>, _ mainTabState: AppFeature.MainTabState) -> some View {
        NavigationStack {
            FeedView(state: mainTabState.feedState, send: { viewStore.send(.feed($0)) })
        }
        .onAppear {
            viewStore.send(.feed(.onAppear))
        }
        .tabItem {
            Label("Feed", systemImage: "house")
        }
        .tag(AppFeature.MainTabState.Tab.feed)
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
