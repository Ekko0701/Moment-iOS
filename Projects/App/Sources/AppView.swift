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
import Networking

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
            #if DEBUG
            // 로컬↔운영 혼동 방지용 서버 배지 — DEBUG 빌드에서만 컴파일된다
            .overlay(alignment: .topTrailing) {
                DebugServerBadge()
            }
            #endif
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
        // GlassMinimal 시안: 탭 틴트는 잉크(Instagram식 블랙/화이트) — 코럴은 콘텐츠 포인트 전용.
        // 심볼은 아웃라인으로 지정하면 선택 시 시스템이 자동으로 filled 변형을 적용한다.
        .tint(MomentColor.ink)
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
                    .navigationTitle("지난 순간") // 시안: 히스토리 타이틀 고정, 공간 정보는 홈 서브타이틀 담당
            }
        }
        .tabItem {
            Label("홈", systemImage: "house")
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
            Label("보내기", systemImage: "plus.circle")
        }
        .tag(AppFeature.MainTabState.Tab.compose)
    }

    // 스페이스 미연결 상태에서 작성 탭에 표시하는 안내
    private func connectRequiredView(_ viewStore: ViewStoreOf<AppFeature>) -> some View {
        ZStack {
            MomentColor.canvas.ignoresSafeArea()

            // 시안 02c: 연결 전 안내도 홈 히어로 자리와 같은 정사각형 서피스 카드로
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
            .padding(Spacing.lg)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .aspectRatio(1, contentMode: .fit)
            .background(MomentColor.surfaceSoft)
            .clipShape(RoundedRectangle(cornerRadius: 26))
            .overlay(
                RoundedRectangle(cornerRadius: 26)
                    .stroke(MomentColor.surfaceStroke, lineWidth: 1)
            )
            .padding(.horizontal, Spacing.lg)
        }
    }

    // MARK: - Debug Server Badge

    #if DEBUG
    /// 현재 API 호스트를 우상단에 작게 표시 — 로컬(localhost/.local)인지 운영인지 즉시 구분.
    /// 릴리즈 빌드에는 포함되지 않는다.
    private struct DebugServerBadge: View {
        var body: some View {
            Text(NetworkingLive.debugServerLabel)
                .font(.system(size: 9, weight: .medium))
                .foregroundColor(MomentColor.ink.opacity(0.5))
                .padding(.horizontal, 7)
                .padding(.vertical, 3)
                .background(MomentColor.glassFill)
                .clipShape(Capsule())
                .padding(.trailing, 6)
                .allowsHitTesting(false)
        }
    }
    #endif

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
            Label("설정", systemImage: "gearshape")
        }
        .tag(AppFeature.MainTabState.Tab.settings)
    }
}
