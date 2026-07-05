import Foundation
import ComposableArchitecture
import Domain
import AuthFeature
import ConnectFeature
import FeedFeature
import ComposeFeature
import SettingsFeature

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
        public var feedState: FeedFeatureReducer.State
        public var composeState: ComposeFeatureReducer.State
        public var settingsState: SettingsFeatureReducer.State
        public var selectedTab: Tab = .feed
        public var currentSpace: Space? = nil

        public enum Tab: Equatable {
            case feed
            case compose
            case settings
        }

        public init() {
            self.feedState = FeedFeatureReducer.State()
            self.composeState = ComposeFeatureReducer.State()
            self.settingsState = SettingsFeatureReducer.State()
        }
    }

    public enum Action {
        case onAppear
        case appInitialized(result: Result<(UserProfile, [Space]), DomainError>)
        case spacesLoaded(result: Result<[Space], DomainError>)
        case selectTab(MainTabState.Tab)

        case auth(AuthFeatureReducer.Action)
        case connect(ConnectFeatureReducer.Action)
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

            case .appInitialized(.success((_, let spaces))):
                if !spaces.isEmpty {
                    var mainState = MainTabState()
                    mainState.currentSpace = spaces.first
                    mainState.feedState.selectedSpaceId = spaces.first?.id
                    mainState.composeState.selectedSpaceId = spaces.first?.id
                    mainState.settingsState.currentSpace = spaces.first
                    state = .main(mainState)
                } else {
                    state = .connect(ConnectFeatureReducer.State())
                }
                return .none

            case .appInitialized(.failure):
                state = .auth(AuthFeatureReducer.State())
                return .none

            case .spacesLoaded(.success(let spaces)):
                if !spaces.isEmpty {
                    var mainState = MainTabState()
                    mainState.currentSpace = spaces.first
                    mainState.feedState.selectedSpaceId = spaces.first?.id
                    mainState.composeState.selectedSpaceId = spaces.first?.id
                    mainState.settingsState.currentSpace = spaces.first
                    state = .main(mainState)
                }
                return .none

            case .spacesLoaded(.failure):
                return .none

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

            case .feed(let action):
                guard case .main(var mainState) = state else {
                    return .none
                }
                let effect = FeedFeatureReducer().reduce(into: &mainState.feedState, action: action)
                state = .main(mainState)
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
