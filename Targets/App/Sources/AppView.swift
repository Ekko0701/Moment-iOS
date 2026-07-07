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

                case .auth:
                    authView(viewStore)

                case .connect:
                    connectView(viewStore)

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

    // MARK: - Auth View
    private func authView(_ viewStore: ViewStoreOf<AppFeature>) -> some View {
        let authState: AuthFeatureReducer.State? = {
            if case .auth(let s) = viewStore.state { return s }
            return nil
        }()
        let isLoading = authState?.isLoading ?? false

        return ZStack {
            MomentColor.canvas.ignoresSafeArea()

            VStack(spacing: Spacing.lg) {
                EyebrowText("MOMENT — 우리 둘의 순간")
                    .padding(.top, Spacing.xxl)

                Text("Moment")
                    .font(MomentTypography.displayXL)
                    .tracking(-1.6)
                    .foregroundColor(MomentColor.ink)

                Text("두 사람만의 소중한 순간을 함께 기록해보세요")
                    .font(MomentTypography.subhead)
                    .foregroundColor(MomentColor.ink)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.xl)

                // 에러 배너 (연결 화면과 동일 패턴)
                if let error = authState?.error {
                    HStack {
                        Text(error.errorDescription ?? "로그인에 실패했어요")
                            .font(MomentTypography.body)
                            .foregroundColor(MomentColor.ink)
                        Spacer()
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(MomentColor.ink)
                            .onTapGesture { viewStore.send(.auth(.dismissError)) }
                    }
                    .padding(Spacing.md)
                    .background(MomentColor.blockCoral.opacity(0.4))
                    .cornerRadius(Spacing.Radius.sm)
                    .padding(.horizontal, Spacing.lg)
                }

                Spacer()

                if authState?.mode == .apple || authState == nil {
                    appleAuthSection(viewStore, isLoading: isLoading)
                } else {
                    emailAuthSection(viewStore, authState: authState, isLoading: isLoading)
                }

                Spacer()
                    .frame(height: Spacing.lg)
            }
            .padding(.vertical, Spacing.lg)
        }
    }

    @ViewBuilder
    private func appleAuthSection(_ viewStore: ViewStoreOf<AppFeature>, isLoading: Bool) -> some View {
        // 포스터 카피 — CTA와 중복되지 않는 서비스 서사 (여백 넉넉히, 문서의 poster 원칙)
        ColorBlock(color: .lilac) {
            VStack(alignment: .center, spacing: Spacing.sm) {
                Text("사진 한 장, 짧은 글 하나로")
                    .font(MomentTypography.subhead)
                    .foregroundColor(MomentColor.ink)
                    .multilineTextAlignment(.center)
                Text("서로의 홈 화면에 스며들어요")
                    .font(MomentTypography.headline)
                    .foregroundColor(MomentColor.ink)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.xl)
        }
        .padding(.horizontal, Spacing.lg)

        Spacer()

        MomentPillButton(isLoading ? "로그인 중…" : "Apple로 시작하기", style: .primary) {
            guard !isLoading else { return }
            let deviceId = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
            viewStore.send(.auth(.appleSignInCompleted(identityToken: "dev-\(deviceId)")))
        }
        .disabled(isLoading)
        .opacity(isLoading ? 0.6 : 1.0)
        .padding(.horizontal, Spacing.lg)

        Button("이메일로 계속하기") {
            viewStore.send(.auth(.modeChanged(.emailLogin)))
        }
        .font(MomentTypography.bodySM)
        .foregroundColor(MomentColor.ink)
        .padding(.top, Spacing.xs)
    }

    @ViewBuilder
    private func emailAuthSection(_ viewStore: ViewStoreOf<AppFeature>,
                                  authState: AuthFeatureReducer.State?,
                                  isLoading: Bool) -> some View {
        let isSignup = authState?.mode == .emailSignup
        let canSubmit = authState?.canSubmitEmail ?? false

        VStack(spacing: Spacing.md) {
            EyebrowText(isSignup ? "이메일로 가입" : "이메일로 로그인")
                .frame(maxWidth: .infinity, alignment: .leading)

            MomentTextField("이메일", text: Binding(
                get: { authState?.email ?? "" },
                set: { viewStore.send(.auth(.emailChanged($0))) }
            ), disablesAutocapitalization: true)

            MomentTextField("비밀번호 (8자 이상)", text: Binding(
                get: { authState?.password ?? "" },
                set: { viewStore.send(.auth(.passwordChanged($0))) }
            ), isSecure: true, disablesAutocapitalization: true)

            if isSignup {
                MomentTextField("닉네임 (2~12자)", text: Binding(
                    get: { authState?.nickname ?? "" },
                    set: { viewStore.send(.auth(.nicknameChanged($0))) }
                ))
            }

            MomentPillButton(isLoading ? "처리 중…" : (isSignup ? "가입하기" : "로그인"),
                             style: .primary) {
                viewStore.send(.auth(.emailSubmitTapped))
            }
            .disabled(!canSubmit || isLoading)
            .opacity((!canSubmit || isLoading) ? 0.6 : 1.0)

            Button(isSignup ? "이미 계정이 있어요 — 로그인" : "계정이 없어요 — 가입하기") {
                viewStore.send(.auth(.modeChanged(isSignup ? .emailLogin : .emailSignup)))
            }
            .font(MomentTypography.bodySM)
            .foregroundColor(MomentColor.ink)

            Button("← Apple로 돌아가기") {
                viewStore.send(.auth(.modeChanged(.apple)))
            }
            .font(MomentTypography.caption)
            .foregroundColor(MomentColor.ink.opacity(0.6))
            .padding(.top, Spacing.xs)
        }
        .padding(.horizontal, Spacing.lg)
    }

    // MARK: - Connect View
    private func connectView(_ viewStore: ViewStoreOf<AppFeature>) -> some View {
        guard case .connect(let connectState) = viewStore.state else {
            return AnyView(EmptyView())
        }

        return AnyView(
            ZStack {
                MomentColor.canvas.ignoresSafeArea()

                VStack(spacing: Spacing.lg) {
                    // Error banner
                    if let error = connectState.error {
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            HStack {
                                VStack(alignment: .leading, spacing: Spacing.xs) {
                                    Text(error.errorDescription ?? "오류가 발생했습니다")
                                        .font(MomentTypography.body)
                                        .foregroundColor(MomentColor.ink)
                                }
                                Spacer()
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(MomentColor.ink)
                                    .onTapGesture {
                                        viewStore.send(.connect(.dismissError))
                                    }
                            }
                            .padding(Spacing.md)
                            .background(MomentColor.blockCoral.opacity(0.4))
                            .cornerRadius(Spacing.Radius.sm)
                        }
                        .padding(.horizontal, Spacing.lg)
                    }

                    // Loading indicator
                    if connectState.isLoading {
                        ProgressView()
                            .tint(MomentColor.ink)
                            .padding(.vertical, Spacing.lg)
                    }

                    // Issue code section
                    EyebrowText("초대 코드")
                        .padding(.top, Spacing.lg)

                    Text("상대방을 초대해 보세요")
                        .font(MomentTypography.headline)
                        .foregroundColor(MomentColor.ink)

                    Spacer()
                        .frame(height: Spacing.md)

                    ColorBlock(color: .lime) {
                        VStack(alignment: .center, spacing: Spacing.md) {
                            if let code = connectState.issuedCode {
                                Text(code)
                                    .font(MomentTypography.displayLG)
                                    .tracking(-0.9)
                                    .foregroundColor(MomentColor.ink)
                                    .textSelection(.enabled)

                                Text("24시간 동안 유효합니다")
                                    .font(MomentTypography.caption)
                                    .tracking(0.8)
                                    .foregroundColor(MomentColor.ink.opacity(0.6))

                                MomentIconCircleButton(systemName: "square.on.square") {
                                    UIPasteboard.general.string = code
                                }
                                .padding(.top, Spacing.sm)
                            } else {
                                Text("코드를 발급해 보세요")
                                    .font(MomentTypography.body)
                                    .foregroundColor(MomentColor.ink)
                            }
                        }
                    }
                    .padding(.horizontal, Spacing.lg)

                    if connectState.issuedCode == nil {
                        MomentPillButton("새 코드 발급", style: .primary) {
                            viewStore.send(.connect(.issueCodeTapped))
                        }
                        .padding(.horizontal, Spacing.lg)
                    }

                    Spacer()

                    // Send/receive invitations
                    EyebrowText("상대방 초대하기")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, Spacing.lg)

                    VStack(spacing: Spacing.md) {
                        MomentTextField("초대 코드 입력", text: Binding(
                            get: { connectState.codeInput },
                            set: { viewStore.send(.connect(.codeInputChanged($0))) }
                        ))
                        .padding(.horizontal, Spacing.lg)

                        MomentPillButton("연결 요청 보내기", style: .primary) {
                            viewStore.send(.connect(.submitCodeTapped))
                        }
                        .padding(.horizontal, Spacing.lg)
                    }

                    // Show pending sent invitations
                    if connectState.sentInvitations.contains(where: { $0.status == .pending }) {
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            Text("요청을 보냈어요 — 상대방의 수락을 기다리는 중")
                                .font(MomentTypography.caption)
                                .tracking(0.8)
                                .foregroundColor(MomentColor.ink.opacity(0.6))
                        }
                        .padding(.horizontal, Spacing.lg)
                    }

                    // Received invitations
                    if !connectState.receivedInvitations.isEmpty {
                        EyebrowText("받은 초대")
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, Spacing.lg)

                        VStack(spacing: Spacing.md) {
                            ForEach(connectState.receivedInvitations.filter { $0.status == .pending }, id: \.id) { invitation in
                                HStack(spacing: Spacing.md) {
                                    VStack(alignment: .leading, spacing: Spacing.xs) {
                                        Text(invitation.counterpart.nickname)
                                            .font(MomentTypography.body)
                                            .foregroundColor(MomentColor.ink)

                                        Text("@\(invitation.counterpart.handle)")
                                            .font(MomentTypography.caption)
                                            .tracking(0.8)
                                            .foregroundColor(MomentColor.ink.opacity(0.6))
                                    }

                                    Spacer()

                                    HStack(spacing: Spacing.sm) {
                                        MomentPillButton("수락", style: .primary) {
                                            viewStore.send(.connect(.respondTapped(id: invitation.id, action: .accept)))
                                        }
                                        .frame(maxWidth: .infinity)

                                        MomentSecondaryPillButton("거절") {
                                            viewStore.send(.connect(.respondTapped(id: invitation.id, action: .decline)))
                                        }
                                        .frame(maxWidth: .infinity)
                                    }
                                }
                                .padding(Spacing.md)
                                .background(MomentColor.surfaceSoft)
                                .cornerRadius(Spacing.Radius.sm)
                            }
                        }
                        .padding(.horizontal, Spacing.lg)
                    }

                    // Refresh button — 초대 목록 갱신 + 스페이스 재확인(상대 수락 시 메인 전환)
                    Button(action: {
                        viewStore.send(.refreshConnection)
                    }) {
                        Text("연결 상태 새로고침")
                            .font(MomentTypography.bodySM)
                            .foregroundColor(MomentColor.ink)
                            .underline()
                    }
                    .padding(.vertical, Spacing.md)

                    Spacer()
                        .frame(height: Spacing.xl)
                }
                .padding(.vertical, Spacing.lg)
            }
            .onAppear {
                viewStore.send(.connect(.onAppear))
            }
        )
    }

    // MARK: - Main Tab View
    private func mainTabView(_ viewStore: ViewStoreOf<AppFeature>, _ mainTabState: AppFeature.MainTabState) -> some View {
        TabView(selection: Binding(
            get: { mainTabState.selectedTab },
            set: { viewStore.send(.selectTab($0)) }
        )) {
            feedView(viewStore, mainTabState)
            composeView(viewStore, mainTabState)
            settingsView(viewStore, mainTabState)
        }
        .tint(MomentColor.ink)
    }

    // MARK: - Feed View
    private func feedView(_ viewStore: ViewStoreOf<AppFeature>, _ mainTabState: AppFeature.MainTabState) -> some View {
        NavigationStack {
            ZStack {
                MomentColor.canvas.ignoresSafeArea()

                VStack(spacing: 0) {
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        EyebrowText("피드")
                            .padding(.horizontal, Spacing.lg)
                            .padding(.top, Spacing.lg)

                        Text("우리 둘의 순간")
                            .font(MomentTypography.headline)
                            .foregroundColor(MomentColor.ink)
                            .padding(.horizontal, Spacing.lg)
                    }

                    if mainTabState.feedState.moments.isEmpty {
                        Spacer()

                        ColorBlock(color: .cream) {
                            VStack(alignment: .center, spacing: Spacing.md) {
                                Image(systemName: "sparkles")
                                    .font(.system(size: 32, weight: .semibold))
                                    .foregroundColor(MomentColor.ink)

                                Text("첫 순간을 기다리는 중")
                                    .font(MomentTypography.body)
                                    .foregroundColor(MomentColor.ink)
                                    .multilineTextAlignment(.center)
                            }
                        }
                        .padding(.horizontal, Spacing.lg)
                        .padding(.vertical, Spacing.xxl)

                        Spacer()
                    } else {
                        ScrollView {
                            VStack(spacing: Spacing.lg) {
                                feedMomentsList(mainTabState.feedState.moments)
                            }
                            .padding(.horizontal, Spacing.lg)
                            .padding(.vertical, Spacing.lg)
                        }
                    }

                    if mainTabState.feedState.isLoading {
                        ProgressView()
                            .padding(.vertical, Spacing.lg)
                    }
                }
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
        VStack(spacing: Spacing.lg) {
            ForEach(moments.enumerated().map({ $0 }), id: \.element.id) { index, moment in
                feedMomentCard(moment, index: index)
            }
        }
    }

    private func feedMomentCard(_ moment: Moment, index: Int) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            if moment.imageURL == nil {
                let blockColor = MomentColor.BlockColor.forFeedIndex(index)
                ColorBlock(color: blockColor) {
                    VStack(alignment: .center, spacing: Spacing.md) {
                        Text(moment.text ?? "")
                            .font(MomentTypography.subhead)
                            .foregroundColor(blockColor.textColor)
                            .multilineTextAlignment(.center)
                            .lineLimit(5)
                    }
                }

                HStack(spacing: Spacing.sm) {
                    Text(moment.author.nickname)
                        .font(MomentTypography.bodySM)
                        .fontWeight(.medium)
                        .foregroundColor(MomentColor.ink)

                    Spacer()

                    Text(moment.createdAt.relativeTimeString)
                        .font(MomentTypography.caption)
                        .tracking(0.8)
                        .foregroundColor(MomentColor.ink.opacity(0.6))
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.vertical, Spacing.sm)

            } else {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    AsyncImage(url: moment.imageURL) { phase in
                        if let image = phase.image {
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(maxHeight: 200)
                                .clipped()
                        } else if phase.error != nil {
                            Color.gray.opacity(0.2)
                                .frame(maxHeight: 200)
                        } else {
                            Color.gray.opacity(0.2)
                                .frame(maxHeight: 200)
                        }
                    }
                    .cornerRadius(Spacing.Radius.md)

                    if let text = moment.text {
                        Text(text)
                            .font(MomentTypography.body)
                            .foregroundColor(MomentColor.ink)
                            .lineLimit(3)
                    }

                    HStack(spacing: Spacing.sm) {
                        Text(moment.author.nickname)
                            .font(MomentTypography.bodySM)
                            .fontWeight(.medium)
                            .foregroundColor(MomentColor.ink)

                        Spacer()

                        Text(moment.createdAt.relativeTimeString)
                            .font(MomentTypography.caption)
                            .tracking(0.8)
                            .foregroundColor(MomentColor.ink.opacity(0.6))
                    }
                }
            }

            if !moment.reactions.isEmpty {
                HStack(spacing: Spacing.xs) {
                    ForEach(moment.reactions, id: \.emoji) { reaction in
                        HStack(spacing: 4) {
                            Text(reaction.emoji)
                                .font(.system(size: 14))

                            Text("\(reaction.count)")
                                .font(MomentTypography.bodySM)
                                .foregroundColor(moment.myReaction == reaction.emoji ? MomentColor.inverseInk : MomentColor.ink)
                        }
                        .padding(.horizontal, Spacing.sm)
                        .padding(.vertical, Spacing.xxs)
                        .background(moment.myReaction == reaction.emoji ? MomentColor.ink : MomentColor.surfaceSoft)
                        .foregroundColor(moment.myReaction == reaction.emoji ? MomentColor.inverseInk : MomentColor.ink)
                        .cornerRadius(Spacing.Radius.full)
                    }

                    Spacer()
                }
            }
        }
    }

    // MARK: - Compose View
    private func composeView(_ viewStore: ViewStoreOf<AppFeature>, _ mainTabState: AppFeature.MainTabState) -> some View {
        NavigationStack {
            ZStack {
                MomentColor.canvas.ignoresSafeArea()

                VStack(spacing: Spacing.lg) {
                    EyebrowText("새 순간")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, Spacing.lg)
                        .padding(.top, Spacing.lg)

                    Text("우리의 순간을 기록하세요")
                        .font(MomentTypography.headline)
                        .foregroundColor(MomentColor.ink)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, Spacing.lg)

                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        TextEditor(text: Binding(
                            get: { mainTabState.composeState.text },
                            set: { viewStore.send(.compose(.textChanged($0))) }
                        ))
                        .font(MomentTypography.body)
                        .foregroundColor(MomentColor.ink)
                        .scrollContentBackground(.hidden)
                        .background(MomentColor.canvas)
                        .border(MomentColor.hairline, width: 1)
                        .cornerRadius(Spacing.Radius.md)
                        .frame(minHeight: 120)

                        HStack(alignment: .center, spacing: Spacing.sm) {
                            Spacer()

                            Text(String(format: "%04d / 0500", mainTabState.composeState.characterCount))
                                .font(MomentTypography.caption)
                                .tracking(0.8)
                                .foregroundColor(MomentColor.ink.opacity(0.6))
                        }
                    }
                    .padding(.horizontal, Spacing.lg)

                    MomentPillButton("공유하기", style: mainTabState.composeState.canSubmit ? .primary : .secondary) {
                        viewStore.send(.compose(.submitTapped))
                    }
                    .disabled(!mainTabState.composeState.canSubmit)
                    .padding(.horizontal, Spacing.lg)

                    if mainTabState.composeState.isUploading {
                        ProgressView()
                    }

                    Spacer()
                }
                .padding(.vertical, Spacing.lg)
            }
        }
        .tabItem {
            Label("Compose", systemImage: "plus")
        }
        .tag(AppFeature.MainTabState.Tab.compose)
    }

    // MARK: - Settings View
    private func settingsView(_ viewStore: ViewStoreOf<AppFeature>, _ mainTabState: AppFeature.MainTabState) -> some View {
        NavigationStack {
            ZStack {
                MomentColor.canvas.ignoresSafeArea()

                VStack(spacing: 0) {
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        EyebrowText("설정")
                            .padding(.horizontal, Spacing.lg)
                            .padding(.top, Spacing.lg)

                        Text("프로필 및 설정")
                            .font(MomentTypography.headline)
                            .foregroundColor(MomentColor.ink)
                            .padding(.horizontal, Spacing.lg)
                    }

                    ScrollView {
                        VStack(spacing: Spacing.lg) {
                            if let profile = mainTabState.settingsState.userProfile {
                                VStack(alignment: .leading, spacing: Spacing.md) {
                                    EyebrowText("프로필")

                                    HStack(spacing: Spacing.md) {
                                        VStack(alignment: .leading, spacing: Spacing.xs) {
                                            Text(profile.nickname)
                                                .font(MomentTypography.cardTitle)
                                                .foregroundColor(MomentColor.ink)

                                            Text("@\(profile.handle)")
                                                .font(MomentTypography.caption)
                                                .tracking(0.8)
                                                .foregroundColor(MomentColor.ink.opacity(0.6))
                                        }

                                        Spacer()

                                        MomentIconCircleButton(systemName: "square.on.square") {
                                            // Copy handle
                                        }
                                    }
                                }
                                .padding(.horizontal, Spacing.lg)
                                .padding(.vertical, Spacing.lg)

                                HairlineDivider()
                                    .padding(.horizontal, Spacing.lg)
                            }

                            if let space = mainTabState.settingsState.currentSpace {
                                ColorBlock(color: .mint) {
                                    VStack(alignment: .leading, spacing: Spacing.md) {
                                        EyebrowText("연결 정보")

                                        if let partner = space.members.first(where: { $0.id != mainTabState.currentUser?.id }) {
                                            VStack(alignment: .leading, spacing: Spacing.xs) {
                                                Text("함께하는 사람")
                                                    .font(MomentTypography.bodySM)
                                                    .foregroundColor(MomentColor.ink.opacity(0.7))

                                                Text(partner.nickname)
                                                    .font(MomentTypography.cardTitle)
                                                    .foregroundColor(MomentColor.ink)

                                                let daysConnected = Calendar.current.dateComponents([.day], from: space.createdAt, to: Date()).day ?? 0
                                                Text("D+\(daysConnected)")
                                                    .font(MomentTypography.bodySM)
                                                    .foregroundColor(MomentColor.ink.opacity(0.6))
                                            }
                                        }
                                    }
                                }
                                .padding(.horizontal, Spacing.lg)
                            }

                            VStack(alignment: .leading, spacing: Spacing.md) {
                                EyebrowText("위험한 작업")

                                VStack(spacing: Spacing.sm) {
                                    Button {
                                        // Disconnect
                                    } label: {
                                        Text("연결 해제")
                                            .font(MomentTypography.button)
                                            .foregroundColor(MomentColor.ink)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                    }

                                    HairlineDivider()

                                    Button {
                                        viewStore.send(.settings(.logoutTapped))
                                    } label: {
                                        Text("로그아웃")
                                            .font(MomentTypography.button)
                                            .foregroundColor(MomentColor.ink)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                    }

                                    HairlineDivider()

                                    Button {
                                        // Delete account
                                    } label: {
                                        Text("계정 삭제")
                                            .font(MomentTypography.button)
                                            .foregroundColor(MomentColor.accentMagenta)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                    }
                                }
                            }
                            .padding(.horizontal, Spacing.lg)
                            .padding(.vertical, Spacing.lg)
                        }
                        .padding(.vertical, Spacing.lg)
                    }

                    if mainTabState.settingsState.isLoading {
                        ProgressView()
                            .padding(.vertical, Spacing.lg)
                    }
                }
            }
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

// MARK: - Helper Extensions
extension Date {
    fileprivate var relativeTimeString: String {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.minute, .hour, .day], from: self, to: now)

        if let day = components.day, day >= 1 {
            return "\(day)일 전"
        } else if let hour = components.hour, hour >= 1 {
            return "\(hour)시간 전"
        } else if let minute = components.minute, minute >= 1 {
            return "\(minute)분 전"
        } else {
            return "방금"
        }
    }
}
