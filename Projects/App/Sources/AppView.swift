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
            // 연결 화면은 홈 탭의 빈 상태이므로 홈 탭으로 이동
            if case .main(let mainTabState) = viewStore.state, mainTabState.currentSpace == nil {
                viewStore.send(.selectTab(.home))
            }
        } else if url.host == "moment" {
            let pathComponents = url.pathComponents.filter { $0 != "/" }
            if let momentIdString = pathComponents.last,
               UUID(uuidString: momentIdString) != nil {
                viewStore.send(.selectTab(.home))
                // setHistoryPresented(true)가 타임라인 로드까지 트리거한다
                viewStore.send(.setHistoryPresented(true))
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
    // 스페이스가 없으면 홈 탭이 연결 화면을 보여준다 (연결 성립 시 자연스럽게 스페이스 홈으로 전환)
    private func homeTabView(_ viewStore: ViewStoreOf<AppFeature>, _ mainTabState: AppFeature.MainTabState) -> some View {
        NavigationStack {
            Group {
                if mainTabState.currentSpace == nil {
                    ConnectView(
                        state: mainTabState.connectState,
                        send: { viewStore.send(.connect($0)) },
                        onRefresh: { viewStore.send(.refreshConnection) }
                    )
                } else {
                    HomeView(state: mainTabState.homeState, send: { viewStore.send(.home($0)) })
                }
            }
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
            if mainTabState.currentSpace == nil {
                connectRequiredView(viewStore)
            } else {
                ComposeView(state: mainTabState.composeState, send: { viewStore.send(.compose($0)) })
            }
        }
        .tabItem {
            Label("Compose", systemImage: "plus")
        }
        .tag(AppFeature.MainTabState.Tab.compose)
    }

    // 스페이스 미연결 상태에서 작성 탭에 표시하는 안내
    private func connectRequiredView(_ viewStore: ViewStoreOf<AppFeature>) -> some View {
        ZStack {
            MomentColor.canvas.ignoresSafeArea()
            OrbBackground.compose().ignoresSafeArea()

            VStack(spacing: Spacing.md) {
                Image(systemName: "person.2")
                    .font(.system(size: 32, weight: .semibold))
                    .foregroundColor(MomentColor.ink.opacity(0.7))

                Text("먼저 상대방과 연결해 주세요")
                    .font(MomentTypography.body)
                    .foregroundColor(MomentColor.ink)

                MomentPillButton("연결하러 가기", style: .primary) {
                    viewStore.send(.selectTab(.home))
                }
                .padding(.horizontal, Spacing.xxl)
                .padding(.top, Spacing.sm)
            }
            .padding(.horizontal, Spacing.lg)
        }
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
