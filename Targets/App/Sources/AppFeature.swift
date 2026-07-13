import Foundation
import ComposableArchitecture
import Domain
import AuthFeature
import ConnectFeature
import HomeFeature
import FeedFeature
import ComposeFeature
import SettingsFeature
import CoreKit
import WidgetKit

public struct AppFeature {
    let userRepository: UserRepositoryProtocol
    let spaceRepository: SpaceRepositoryProtocol
    let momentRepository: MomentRepositoryProtocol

    public enum State: Equatable {
        case launching
        case auth(AuthFeatureReducer.State)
        case connect(ConnectFeatureReducer.State)
        case main(MainTabState)

        public init() {
            self = .launching
        }
    }

    public struct MainTabState: Equatable {
        public var homeState: HomeFeatureReducer.State
        public var feedState: FeedFeatureReducer.State
        public var composeState: ComposeFeatureReducer.State
        public var settingsState: SettingsFeatureReducer.State
        // 로그인 직후엔 홈(스페이스 카드)이 현관 역할을 한다
        public var selectedTab: Tab = .home
        public var currentSpace: Space? = nil
        public var currentUser: UserProfile? = nil

        public enum Tab: Equatable {
            case home
            case feed
            case compose
            case settings
        }

        public init() {
            self.homeState = HomeFeatureReducer.State()
            self.feedState = FeedFeatureReducer.State()
            self.composeState = ComposeFeatureReducer.State()
            self.settingsState = SettingsFeatureReducer.State()
        }
    }

    public enum Action {
        case onAppear
        case appInitialized(result: Result<(UserProfile, [Space]), DomainError>)
        case spacesLoaded(result: Result<[Space], DomainError>)
        // 로그인 직후 메인 전환 시 프로필을 뒤늦게 채운다 (홈 인사말·상대방 계산용)
        case profileLoaded(UserProfile)
        // 연결 대기 중 새로고침: 받은 초대 목록을 갱신하는 동시에 스페이스를 재확인해
        // 상대가 수락했으면(스페이스 생성됨) 메인으로 전환한다.
        case refreshConnection
        case selectTab(MainTabState.Tab)

        case auth(AuthFeatureReducer.Action)
        case connect(ConnectFeatureReducer.Action)
        case home(HomeFeatureReducer.Action)
        case feed(FeedFeatureReducer.Action)
        case compose(ComposeFeatureReducer.Action)
        case settings(SettingsFeatureReducer.Action)
    }

    public var body: some ReducerOf<Self> {
        Reduce<State, Action> { state, action in
            switch action {
            case .onAppear:
                return .run { [userRepository = self.userRepository, spaceRepository = self.spaceRepository] send in
                    let result: Result<(UserProfile, [Space]), DomainError> = await Result {
                        let user = try await userRepository.me()
                        let spaces = try await spaceRepository.mySpaces()
                        return (user, spaces)
                    }.mapError { error in
                        error as? DomainError ?? .unknown(code: "ERROR", message: error.localizedDescription)
                    }
                    await send(.appInitialized(result: result))
                }

            case .appInitialized(.success((let user, let spaces))):
                if !spaces.isEmpty {
                    var mainState = MainTabState()
                    mainState.currentUser = user
                    mainState.currentSpace = spaces.first
                    mainState.homeState.space = spaces.first
                    mainState.homeState.currentUser = user
                    mainState.feedState.selectedSpaceId = spaces.first?.id
                    mainState.composeState.selectedSpaceId = spaces.first?.id
                    mainState.settingsState.currentSpace = spaces.first
                    mainState.settingsState.userProfile = user
                    state = .main(mainState)
                    // Save widget state: has spaces, no need to check moment yet
                    return .none
                } else {
                    state = .connect(ConnectFeatureReducer.State())
                    // Save widget state: need to connect
                    let store = WidgetMomentStore()
                    store.saveState(.needConnect)
                    WidgetCenter.shared.reloadAllTimelines()
                    return .none
                }

            case .appInitialized(.failure):
                state = .auth(AuthFeatureReducer.State())
                // Save widget state: need login
                let store = WidgetMomentStore()
                store.saveState(.needLogin)
                WidgetCenter.shared.reloadAllTimelines()
                return .none

            case .spacesLoaded(.success(let spaces)):
                if !spaces.isEmpty {
                    var mainState = MainTabState()
                    mainState.currentSpace = spaces.first
                    mainState.homeState.space = spaces.first
                    mainState.feedState.selectedSpaceId = spaces.first?.id
                    mainState.composeState.selectedSpaceId = spaces.first?.id
                    mainState.settingsState.currentSpace = spaces.first
                    state = .main(mainState)
                    return .run { [userRepository = self.userRepository] send in
                        if let user = try? await userRepository.me() {
                            await send(.profileLoaded(user))
                        }
                    }
                } else if case .connect = state {
                    // 이미 연결 화면이면 유지 (새로고침 결과가 "아직 스페이스 없음")
                } else {
                    // 로그인 직후 스페이스가 없는 신규/미연결 사용자 → 연결 화면으로
                    state = .connect(ConnectFeatureReducer.State())
                }
                return .none

            case .profileLoaded(let user):
                guard case .main(var mainState) = state else {
                    return .none
                }
                mainState.currentUser = user
                mainState.homeState.currentUser = user
                mainState.settingsState.userProfile = user
                state = .main(mainState)
                return .none

            case .spacesLoaded(.failure(let error)):
                // 로그인 직후 스페이스 조회 실패 — 로그인 화면이면 에러를 노출해 무반응을 방지
                if case .auth(var authState) = state {
                    authState.error = error
                    state = .auth(authState)
                }
                return .none

            case .refreshConnection:
                guard case .connect(var connectState) = state else {
                    return .none
                }
                // 받은 초대 목록 갱신 + 스페이스 재확인을 동시에 수행.
                // 스페이스가 생겼으면 spacesLoaded 핸들러가 메인으로 전환한다.
                let effect = ConnectFeatureReducer().reduce(into: &connectState, action: .onAppear)
                state = .connect(connectState)
                return effect.map { Action.connect($0) }
                    .merge(with: .run { [spaceRepository = self.spaceRepository] send in
                        let result: Result<[Space], DomainError> = await Result {
                            try await spaceRepository.mySpaces()
                        }.mapError { error in
                            error as? DomainError ?? .unknown(code: "ERROR", message: error.localizedDescription)
                        }
                        await send(.spacesLoaded(result: result))
                    })

            case .selectTab(let tab):
                guard case .main(var mainState) = state else {
                    return .none
                }
                mainState.selectedTab = tab
                state = .main(mainState)
                return .none

            case .auth(let action):
                guard case .auth(var authState) = state else {
                    return .none
                }
                let effect = AuthFeatureReducer().reduce(into: &authState, action: action)
                state = .auth(authState)

                // Handle delegates from auth
                if case .delegate(.loggedIn) = action {
                    return effect.map { .auth($0) }
                        .merge(with: .run { [spaceRepository = self.spaceRepository] send in
                            let result: Result<[Space], DomainError> = await Result {
                                try await spaceRepository.mySpaces()
                            }.mapError { error in
                                error as? DomainError ?? .unknown(code: "ERROR", message: error.localizedDescription)
                            }
                            await send(.spacesLoaded(result: result))
                        })
                }

                return effect.map { .auth($0) }

            case .connect(let action):
                guard case .connect(var connectState) = state else {
                    return .none
                }
                let effect = ConnectFeatureReducer().reduce(into: &connectState, action: action)
                state = .connect(connectState)

                // Handle delegates from connect
                if case .delegate(.connected) = action {
                    return effect.map { .connect($0) }
                        .merge(with: .run { [spaceRepository = self.spaceRepository] send in
                            let result: Result<[Space], DomainError> = await Result {
                                try await spaceRepository.mySpaces()
                            }.mapError { error in
                                error as? DomainError ?? .unknown(code: "ERROR", message: error.localizedDescription)
                            }
                            await send(.spacesLoaded(result: result))
                        })
                }

                return effect.map { .connect($0) }

            case .home(let action):
                guard case .main(var mainState) = state else {
                    return .none
                }
                let effect = HomeFeatureReducer().reduce(into: &mainState.homeState, action: action)
                state = .main(mainState)

                // 카드 탭 → 피드로 이동
                if case .delegate(.openFeed) = action {
                    return effect.map { .home($0) }
                        .merge(with: .send(.selectTab(.feed)))
                }

                return effect.map { .home($0) }

            case .feed(let action):
                guard case .main(var mainState) = state else {
                    return .none
                }
                let effect = FeedFeatureReducer().reduce(into: &mainState.feedState, action: action)
                state = .main(mainState)

                // Sync widget when timeline is loaded
                if case .timelineResponse(.success) = action {
                    return effect.map { .feed($0) }
                        .merge(with: .run { [feedState = mainState.feedState,
                                             myUserId = mainState.currentUser?.id] _ in
                            syncWidgetMoment(from: feedState, excludingAuthorId: myUserId)
                        })
                }

                return effect.map { .feed($0) }

            case .compose(let action):
                guard case .main(var mainState) = state else {
                    return .none
                }
                let effect = ComposeFeatureReducer().reduce(into: &mainState.composeState, action: action)
                state = .main(mainState)

                // Handle delegates from compose
                if case .delegate(.shared) = action {
                    var newMainState = mainState
                    newMainState.composeState = ComposeFeatureReducer.State()
                    newMainState.selectedTab = .feed
                    newMainState.feedState = FeedFeatureReducer.State()
                    newMainState.feedState.selectedSpaceId = newMainState.currentSpace?.id
                    state = .main(newMainState)
                    return effect.map { .compose($0) }
                        .merge(with: .send(.feed(.onAppear)))
                }

                if case .delegate(.dismissed) = action {
                    var newMainState = mainState
                    newMainState.composeState = ComposeFeatureReducer.State()
                    newMainState.selectedTab = .feed
                    state = .main(newMainState)
                    return effect.map { .compose($0) }
                }

                return effect.map { .compose($0) }

            case .settings(let action):
                guard case .main(var mainState) = state else {
                    return .none
                }
                let effect = SettingsFeatureReducer().reduce(into: &mainState.settingsState, action: action)
                state = .main(mainState)

                // Handle delegates from settings
                if case .delegate(.loggedOut) = action {
                    state = .auth(AuthFeatureReducer.State())
                    return effect.map { .settings($0) }
                }

                if case .delegate(.disconnected) = action {
                    state = .connect(ConnectFeatureReducer.State())
                    return effect.map { .settings($0) }
                }

                return effect.map { .settings($0) }
            }
        }
    }

    public init(
        userRepository: UserRepositoryProtocol,
        spaceRepository: SpaceRepositoryProtocol,
        momentRepository: MomentRepositoryProtocol
    ) {
        self.userRepository = userRepository
        self.spaceRepository = spaceRepository
        self.momentRepository = momentRepository
    }
}

extension AppFeature: Reducer {}

// MARK: - Widget Sync Helper
private func syncWidgetMoment(from feedState: FeedFeatureReducer.State, excludingAuthorId: UUID?) {
    let store = WidgetMomentStore()

    // 위젯 계약(F-06): "내가 작성하지 않은" 최신 모먼트만 표시한다.
    let candidates = feedState.moments.filter { moment in
        guard let excludingAuthorId else { return true }
        return moment.author.id != excludingAuthorId
    }
    if let latestMoment = candidates.first {
        let snapshot = WidgetMomentSnapshot(
            momentId: latestMoment.id,
            spaceId: latestMoment.spaceId,
            authorNickname: latestMoment.author.nickname,
            text: latestMoment.text,
            imageFileName: nil,
            createdAt: latestMoment.createdAt,
            hasImage: latestMoment.imageURL != nil
        )
        store.saveState(.hasMoment(snapshot))
    } else {
        store.saveState(.empty)
    }

    WidgetCenter.shared.reloadAllTimelines()
}
