import SwiftUI
import ComposableArchitecture
import Domain
import AuthFeature
import ConnectFeature
import FeedFeature
import ComposeFeature
import SettingsFeature

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

                case .auth:
                    authView(viewStore)

                case .connect:
                    connectView(viewStore)

                case .main(let mainTabState):
                    mainTabView(viewStore, mainTabState)
                }
            }
        }
    }

    private func authView(_ viewStore: ViewStoreOf<AppFeature>) -> some View {
        VStack(spacing: 24) {
            Text("Moment")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.blue)

            Text("로그인이 필요해요")
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(.gray)

            Button(action: {
                viewStore.send(.auth(.appleSignInCompleted(identityToken: "dev-user-1")))
            }) {
                Text("Sign in with Apple (Dev)")
                    .frame(maxWidth: .infinity)
                    .padding(12)
                    .background(Color.black)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .padding(.horizontal, 16)

            Spacer()
        }
        .padding(.vertical, 48)
    }

    private func connectView(_ viewStore: ViewStoreOf<AppFeature>) -> some View {
        VStack(spacing: 24) {
            Text("상대방을 초대해 보세요")
                .font(.system(size: 18, weight: .semibold))

            Text("코드를 생성하거나 입력해주세요")
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(.gray)

            Button(action: {
                viewStore.send(.connect(.issueCodeTapped))
            }) {
                Text("코드 생성")
                    .frame(maxWidth: .infinity)
                    .padding(12)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .padding(.horizontal, 16)

            Spacer()
        }
        .padding(.vertical, 48)
        .onAppear {
            viewStore.send(.connect(.onAppear))
        }
    }

    private func mainTabView(_ viewStore: ViewStoreOf<AppFeature>, _ mainTabState: AppFeature.MainTabState) -> some View {
        TabView(selection: Binding(
            get: { mainTabState.selectedTab },
            set: { viewStore.send(.selectTab($0)) }
        )) {
            feedView(viewStore, mainTabState)
            composeView(viewStore, mainTabState)
            settingsView(viewStore, mainTabState)
        }
    }

    private func feedView(_ viewStore: ViewStoreOf<AppFeature>, _ mainTabState: AppFeature.MainTabState) -> some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text("홈 (피드)")
                    .font(.system(size: 24, weight: .bold))

                if mainTabState.feedState.moments.isEmpty {
                    Text("첫 모먼트를 기다리는 중...")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.gray)
                } else {
                    ScrollView {
                        VStack(spacing: 12) {
                            feedMomentsList(mainTabState.feedState.moments)
                        }
                        .padding(12)
                    }
                }

                if mainTabState.feedState.isLoading {
                    ProgressView()
                }

                Spacer()
            }
        }
        .onAppear {
            viewStore.send(.feed(.onAppear))
        }
        .tabItem {
            Label("Feed", systemImage: "house")
        }
        .tag(AppFeature.MainTabState.Tab.feed)
    }

    private func feedMomentsList(_ moments: [Moment]) -> some View {
        VStack(spacing: 12) {
            ForEach(moments, id: \.id) { moment in
                feedMomentCard(moment)
            }
        }
    }

    private func feedMomentCard(_ moment: Moment) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(moment.text ?? "(이미지만 공유)")
                .font(.system(size: 14))
            Text("by \(moment.author.nickname)")
                .font(.system(size: 12, weight: .light))
                .foregroundColor(.gray)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }

    private func composeView(_ viewStore: ViewStoreOf<AppFeature>, _ mainTabState: AppFeature.MainTabState) -> some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text("새 모먼트 작성")
                    .font(.system(size: 18, weight: .semibold))

                TextEditor(text: Binding(
                    get: { mainTabState.composeState.text },
                    set: { viewStore.send(.compose(.textChanged($0))) }
                ))
                .border(Color.gray.opacity(0.5))
                .frame(height: 100)

                Text("\(mainTabState.composeState.characterCount)/\(mainTabState.composeState.maxCharacters)")
                    .font(.system(size: 12, weight: .light))
                    .foregroundColor(.gray)

                Button(action: {
                    viewStore.send(.compose(.submitTapped))
                }) {
                    Text("공유하기")
                        .frame(maxWidth: .infinity)
                        .padding(12)
                        .background(mainTabState.composeState.canSubmit ? Color.blue : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .disabled(!mainTabState.composeState.canSubmit)

                if mainTabState.composeState.isUploading {
                    ProgressView()
                }

                Spacer()
            }
            .padding(16)
        }
        .tabItem {
            Label("Compose", systemImage: "plus")
        }
        .tag(AppFeature.MainTabState.Tab.compose)
    }

    private func settingsView(_ viewStore: ViewStoreOf<AppFeature>, _ mainTabState: AppFeature.MainTabState) -> some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text("설정")
                    .font(.system(size: 24, weight: .bold))

                if let profile = mainTabState.settingsState.userProfile {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("닉네임: \(profile.nickname)")
                        Text("핸들: @\(profile.handle)")
                    }
                    .font(.system(size: 14))
                    .padding(16)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                }

                Button(action: {
                    viewStore.send(.settings(.logoutTapped))
                }) {
                    Text("로그아웃")
                        .frame(maxWidth: .infinity)
                        .padding(12)
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }

                if mainTabState.settingsState.isLoading {
                    ProgressView()
                }

                Spacer()
            }
            .padding(16)
        }
        .onAppear {
            viewStore.send(.settings(.onAppear))
        }
        .tabItem {
            Label("Settings", systemImage: "gear")
        }
        .tag(AppFeature.MainTabState.Tab.settings)
    }
}
