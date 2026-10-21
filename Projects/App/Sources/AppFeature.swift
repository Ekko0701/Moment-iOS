import Foundation
import ComposableArchitecture
import Dependencies
import Domain
import AuthFeature
import ConnectFeature
import HomeFeature
import FeedFeature
import ComposeFeature
import SettingsFeature
import GroupFeature
import CoreKit
import UIKit
import WidgetKit

public struct AppFeature {
    @Dependency(\.sessionUseCase) var sessionUseCase

    public enum State: Equatable {
        case launching
        case auth(AuthFeatureReducer.State)
        case main(MainTabState)

        public init() {
            self = .launching
        }

        var isMain: Bool {
            if case .main = self { return true }
            return false
        }

        /// 홈 목록을 다시 받는 중인지. 당겨서 새로고침 스피너가 이 값이 꺼질 때까지 기다린다
        var isHomeRefreshing: Bool {
            if case .main(let main) = self { return main.homeState.isRefreshing }
            return false
        }
    }

    public struct MainTabState: Equatable {
        public var homeState: HomeFeatureReducer.State
        public var feedState: FeedFeatureReducer.State
        public var composeState: ComposeFeatureReducer.State
        public var settingsState: SettingsFeatureReducer.State
        // 스페이스가 하나도 없을 때 홈 탭이, 1:1이 없을 때 홈의 "1:1로 연결하기"가 보여주는 연결 화면 상태
        public var connectState: ConnectFeatureReducer.State
        // 로그인 직후엔 홈(스페이스 카드)이 현관 역할을 한다
        public var selectedTab: Tab = .home
        /// 내가 속한 스페이스 전체. 1:1이 먼저, 그다음 그룹
        public var spaces: [Space] = []
        /// 마지막으로 연 스페이스. 작성 탭의 기본 보낼 곳이 된다
        public var selectedSpaceId: UUID? = nil
        public var currentUser: UserProfile? = nil
        // 1:1 히스토리(Feed)를 네비게이션 스택으로 표시할지 여부
        public var isHistoryPresented = false
        // 그룹이 있지만 1:1이 없을 때 홈에서 연결 화면을 푸시할지 여부
        public var isConnectPresented = false
        // 그룹 상세(멤버 스트립 + 타임라인)와 그 안의 설정 화면
        public var groupDetail: GroupDetailFeature.State? = nil
        public var groupSettings: GroupSettingsFeature.State? = nil
        // 그룹 만들기·코드로 참여 시트
        public var groupCreate: GroupCreateFeature.State? = nil
        public var groupJoin: GroupJoinFeature.State? = nil
        // 보내기 완료 토스트 표시 여부 (잠시 표시 후 자동 해제)
        public var showsShareConfirmation = false

        public enum Tab: Equatable {
            case home
            case compose
            case settings
        }

        public init() {
            self.homeState = HomeFeatureReducer.State()
            self.feedState = FeedFeatureReducer.State()
            self.composeState = ComposeFeatureReducer.State()
            self.settingsState = SettingsFeatureReducer.State()
            self.connectState = ConnectFeatureReducer.State()
        }

        public var currentSpace: Space? { spaces.first { $0.id == selectedSpaceId } }
        public var oneToOneSpace: Space? { spaces.first { $0.type == .oneToOne } }

        /// 서버에서 받은 스페이스 목록을 하위 화면 상태에 퍼뜨린다.
        /// 선택된 스페이스·작성 대상·열려 있는 그룹 화면은 목록에 남아 있으면 유지하고, 사라졌으면 정리한다.
        mutating func apply(spaces: [Space]) {
            self.spaces = spaces
            let ids = Set(spaces.map(\.id))
            if selectedSpaceId.map({ !ids.contains($0) }) ?? true {
                selectedSpaceId = spaces.first?.id
            }
            homeState.spaces = spaces
            homeState.isRefreshing = false
            composeState.availableSpaces = spaces
            if composeState.selectedSpaceId.map({ !ids.contains($0) }) ?? true {
                composeState.selectedSpaceId = selectedSpaceId
            }
            settingsState.currentSpace = oneToOneSpace
            if let detail = groupDetail {
                if let refreshed = spaces.first(where: { $0.id == detail.space.id }) {
                    groupDetail?.space = refreshed
                } else {
                    groupDetail = nil
                    groupSettings = nil
                }
            }
            // 상대가 연결을 끊는 등으로 1:1이 사라지면 그 지난 순간 화면도 닫는다
            if isHistoryPresented, feedState.selectedSpaceId.map({ !ids.contains($0) }) ?? true {
                isHistoryPresented = false
                feedState = FeedFeatureReducer.State()
            }
            if !spaces.isEmpty {
                connectState = oneToOneSpace == nil ? connectState : ConnectFeatureReducer.State()
            }
        }

        /// 스페이스 하나를 홈 탭 스택에 연다. 그룹은 상세 화면, 1:1은 히스토리 화면이다.
        /// 열려 있던 상세·설정·히스토리·연결 화면을 먼저 닫아, 화면에 보이는 스페이스와 피드가 항상 같은 스페이스를 가리키게 한다.
        /// 이미 같은 그룹 상세가 열려 있으면 불러온 멤버를 유지한다. 타임라인 로드는 호출 측이 `.feed(.onAppear)`로 시작한다.
        mutating func open(_ space: Space) {
            let sameGroupDetail = groupDetail?.space.id == space.id ? groupDetail : nil
            groupDetail = nil
            groupSettings = nil
            isHistoryPresented = false
            isConnectPresented = false
            selectedTab = .home

            selectedSpaceId = space.id
            composeState.selectedSpaceId = space.id
            feedState = FeedFeatureReducer.State()
            feedState.selectedSpaceId = space.id

            if space.isGroup {
                var detail = sameGroupDetail ?? GroupDetailFeature.State(space: space)
                detail.space = space
                groupDetail = detail
            } else {
                isHistoryPresented = true
            }
        }

        /// 다른 스페이스를 보여주는 상세·설정·히스토리 화면을 닫는다.
        /// 작성 탭에서 보낸 뒤 피드가 보낸 스페이스로 바뀌므로, 남는 화면은 항상 그 스페이스를 보여준다.
        mutating func closeScreens(notShowing spaceId: UUID) {
            if groupDetail?.space.id != spaceId {
                groupDetail = nil
                groupSettings = nil
            }
            if isHistoryPresented && oneToOneSpace?.id != spaceId {
                isHistoryPresented = false
            }
        }
    }

    public enum Action {
        case onAppear
        case appInitialized(result: Result<(UserProfile, [Space]), DomainError>)
        case spacesLoaded(result: Result<[Space], DomainError>)
        // 로그인 직후 메인 전환 시 프로필을 뒤늦게 채운다 (홈 인사말·상대방 계산용)
        case profileLoaded(UserProfile)
        // 연결 대기 중 새로고침: 받은 초대 목록을 갱신하는 동시에 스페이스를 재확인해
        // 상대가 수락했으면(스페이스 생성됨) 홈 카드로 전환한다.
        case refreshConnection
        case reloadSpaces
        // 내가 보낸, 방장 수락을 기다리는 그룹 참여 요청
        case joinRequestsLoaded([GroupJoinRequest])
        case selectTab(MainTabState.Tab)
        case setHistoryPresented(Bool)
        case setConnectPresented(Bool)
        case setGroupDetailPresented(Bool)
        case setGroupSettingsPresented(Bool)
        case dismissGroupSheets
        case setShareConfirmationVisible(Bool)

        case auth(AuthFeatureReducer.Action)
        case connect(ConnectFeatureReducer.Action)
        case home(HomeFeatureReducer.Action)
        case feed(FeedFeatureReducer.Action)
        case compose(ComposeFeatureReducer.Action)
        case settings(SettingsFeatureReducer.Action)
        case groupDetail(GroupDetailFeature.Action)
        case groupSettings(GroupSettingsFeature.Action)
        case groupCreate(GroupCreateFeature.Action)
        case groupJoin(GroupJoinFeature.Action)
    }

    // 한 번에 하나만 살아 있어야 하는 effect. 새로 시작하면 이전 것은 취소된다
    private enum CancelID: Hashable, Sendable {
        case loadSpaces
        case widgetSync
    }

    /// 내 스페이스 목록과 내 참여 요청을 불러온다. 마지막 요청만 반영되도록 이전 요청은 취소한다
    private func loadSpaces() -> Effect<Action> {
        .run { [sessionUseCase = self.sessionUseCase] send in
            let result: Result<[Space], DomainError> = await Result {
                try await sessionUseCase.mySpaces()
            }.mapError { error in
                error as? DomainError ?? .unknown(code: "ERROR", message: error.localizedDescription)
            }
            await send(.spacesLoaded(result: result))
            // 참여 요청 목록은 실패해도 스페이스 카드에 영향이 없으므로 이전 목록을 유지한다
            @Dependency(\.groupUseCase) var groupUseCase
            if case .success = result, let requests = try? await groupUseCase.myJoinRequests() {
                await send(.joinRequestsLoaded(requests))
            }
        }
        .cancellable(id: CancelID.loadSpaces, cancelInFlight: true)
    }

    /// 위젯 데이터를 스페이스 목록에 맞춘다. 새 동기화가 시작되거나 로그아웃하면 진행 중인 동기화는 취소된다
    private func widgetSync(spaces: [Space], myUserId: UUID?) -> Effect<Action> {
        guard !spaces.isEmpty else {
            WidgetMomentStore().resetForNoSpaces()
            WidgetCenter.shared.reloadAllTimelines()
            return .cancel(id: CancelID.widgetSync)
        }
        return .run { _ in
            await syncWidget(spaces: spaces, myUserId: myUserId)
        }
        .cancellable(id: CancelID.widgetSync, cancelInFlight: true)
    }

    public var body: some ReducerOf<Self> {
        Reduce<State, Action> { state, action in
            switch action {
            case .onAppear:
                return .run { [sessionUseCase = self.sessionUseCase] send in
                    let result: Result<(UserProfile, [Space]), DomainError> = await Result {
                        try await sessionUseCase.bootstrap()
                    }.mapError { error in
                        error as? DomainError ?? .unknown(code: "ERROR", message: error.localizedDescription)
                    }
                    await send(.appInitialized(result: result))
                }

            case .appInitialized(.success((let user, let spaces))):
                // 스페이스 유무와 무관하게 메인 탭으로 진입한다.
                // 스페이스가 없으면 홈 탭이 연결 화면(connectState)을 보여준다.
                var mainState = MainTabState()
                mainState.currentUser = user
                mainState.homeState.currentUser = user
                mainState.settingsState.userProfile = user
                mainState.apply(spaces: spaces)
                state = .main(mainState)
                return widgetSync(spaces: spaces, myUserId: user.id).merge(with: .run { send in
                    @Dependency(\.groupUseCase) var groupUseCase
                    if let requests = try? await groupUseCase.myJoinRequests() {
                        await send(.joinRequestsLoaded(requests))
                    }
                })

            case .appInitialized(.failure):
                state = .auth(AuthFeatureReducer.State())
                WidgetMomentStore().resetForLogout()
                WidgetCenter.shared.reloadAllTimelines()
                return .cancel(id: CancelID.widgetSync)

            case .spacesLoaded(.success(let spaces)):
                // 기존 메인 상태가 있으면 유지(currentUser 등 보존), 없으면 새로 만든다.
                var mainState: MainTabState
                if case .main(let existing) = state {
                    mainState = existing
                } else {
                    mainState = MainTabState()
                }
                mainState.apply(spaces: spaces)
                state = .main(mainState)
                let sync = widgetSync(spaces: spaces, myUserId: mainState.currentUser?.id)
                if mainState.currentUser == nil {
                    return sync.merge(with: .run { [sessionUseCase = self.sessionUseCase] send in
                        if let user = try? await sessionUseCase.myProfile() {
                            await send(.profileLoaded(user))
                        }
                    })
                }
                return sync

            case .joinRequestsLoaded(let requests):
                guard case .main(var mainState) = state else {
                    return .none
                }
                mainState.homeState.pendingJoinRequests = requests
                state = .main(mainState)
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
                } else if case .main(var mainState) = state {
                    mainState.homeState.isRefreshing = false
                    state = .main(mainState)
                }
                return .none

            case .reloadSpaces:
                return loadSpaces()

            case .refreshConnection:
                guard case .main(var mainState) = state, mainState.oneToOneSpace == nil else {
                    return .none
                }
                // 받은 초대 목록 갱신 + 스페이스 재확인을 동시에 수행.
                let effect = ConnectFeatureReducer().reduce(into: &mainState.connectState, action: .onAppear)
                state = .main(mainState)
                return effect.map { Action.connect($0) }.merge(with: loadSpaces())

            case .selectTab(let tab):
                guard case .main(var mainState) = state else {
                    return .none
                }
                mainState.selectedTab = tab
                state = .main(mainState)
                return .none

            case .setShareConfirmationVisible(let visible):
                guard case .main(var mainState) = state else {
                    return .none
                }
                mainState.showsShareConfirmation = visible
                state = .main(mainState)
                return .none

            case .setHistoryPresented(let isPresented):
                guard case .main(var mainState) = state else {
                    return .none
                }
                mainState.isHistoryPresented = isPresented
                state = .main(mainState)
                // 히스토리를 열 때마다 타임라인을 로드한다 (홈 카드 push가 유일한 진입 트리거)
                if isPresented {
                    return .send(.feed(.onAppear))
                }
                return .none

            case .setConnectPresented(let isPresented):
                guard case .main(var mainState) = state else {
                    return .none
                }
                mainState.isConnectPresented = isPresented
                state = .main(mainState)
                return .none

            case .setGroupDetailPresented(let isPresented):
                guard case .main(var mainState) = state, !isPresented else {
                    return .none
                }
                mainState.groupDetail = nil
                mainState.groupSettings = nil
                state = .main(mainState)
                return .none

            case .setGroupSettingsPresented(let isPresented):
                guard case .main(var mainState) = state, !isPresented else {
                    return .none
                }
                mainState.groupSettings = nil
                state = .main(mainState)
                return .none

            case .dismissGroupSheets:
                guard case .main(var mainState) = state else {
                    return .none
                }
                // 요청을 보낸 뒤 시트를 쓸어내려 닫아도 홈에 대기 중 요청이 보이게 한다
                let sentRequest = mainState.groupJoin?.sentRequest
                let createdGroup = mainState.groupCreate?.created != nil
                mainState.groupCreate = nil
                mainState.groupJoin = nil
                if let sentRequest, !mainState.homeState.pendingJoinRequests.contains(where: { $0.id == sentRequest.id }) {
                    mainState.homeState.pendingJoinRequests.insert(sentRequest, at: 0)
                }
                state = .main(mainState)
                return sentRequest != nil || createdGroup ? loadSpaces() : .none

            case .auth(let action):
                guard case .auth(var authState) = state else {
                    return .none
                }
                let effect = AuthFeatureReducer().reduce(into: &authState, action: action)
                state = .auth(authState)

                if case .delegate(.loggedIn) = action {
                    return effect.map { .auth($0) }.merge(with: loadSpaces())
                }
                return effect.map { .auth($0) }

            case .connect(let action):
                guard case .main(var mainState) = state else {
                    return .none
                }
                let effect = ConnectFeatureReducer().reduce(into: &mainState.connectState, action: action)
                if case .delegate(.connected) = action {
                    mainState.isConnectPresented = false
                }
                state = .main(mainState)

                if case .delegate(.connected) = action {
                    return effect.map { .connect($0) }.merge(with: loadSpaces())
                }
                return effect.map { .connect($0) }

            case .home(let action):
                guard case .main(var mainState) = state else {
                    return .none
                }
                let effect = HomeFeatureReducer().reduce(into: &mainState.homeState, action: action)

                guard case .delegate(let delegate) = action else {
                    state = .main(mainState)
                    return effect.map { .home($0) }
                }

                switch delegate {
                case .refresh:
                    state = .main(mainState)
                    return effect.map { .home($0) }.merge(with: loadSpaces())

                case .openSpace(let spaceId):
                    guard let space = mainState.spaces.first(where: { $0.id == spaceId }) else {
                        state = .main(mainState)
                        return effect.map { .home($0) }
                    }
                    mainState.open(space)
                    state = .main(mainState)
                    return effect.map { .home($0) }.merge(with: .send(.feed(.onAppear)))

                case .connectOneToOne:
                    mainState.isConnectPresented = true
                    state = .main(mainState)
                    return effect.map { .home($0) }

                case .createGroup:
                    mainState.groupCreate = GroupCreateFeature.State()
                    state = .main(mainState)
                    return effect.map { .home($0) }

                case .joinGroup:
                    mainState.groupJoin = GroupJoinFeature.State()
                    state = .main(mainState)
                    return effect.map { .home($0) }

                case .cancelJoinRequest(let request):
                    state = .main(mainState)
                    return effect.map { .home($0) }.merge(with: .run { send in
                        @Dependency(\.groupUseCase) var groupUseCase
                        try? await groupUseCase.cancelJoinRequest(request)
                        await send(.reloadSpaces)
                    })
                }

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

                if case .delegate(.shared(let moment)) = action {
                    var newMainState = mainState
                    newMainState.composeState = ComposeFeatureReducer.State()
                    newMainState.composeState.availableSpaces = mainState.spaces
                    newMainState.composeState.selectedSpaceId = moment.spaceId
                    newMainState.selectedSpaceId = moment.spaceId
                    newMainState.selectedTab = .home
                    // 내 모먼트는 홈 카드(다른 멤버 전용)에 보이지 않으므로, 완료 확인은 화면 이동 대신 토스트가 담당
                    newMainState.showsShareConfirmation = true
                    newMainState.feedState = FeedFeatureReducer.State()
                    newMainState.feedState.selectedSpaceId = moment.spaceId
                    newMainState.closeScreens(notShowing: moment.spaceId)
                    state = .main(newMainState)
                    return effect.map { .compose($0) }
                        .merge(with: .send(.feed(.onAppear)))
                        .merge(with: .run { send in
                            try? await Task.sleep(for: .seconds(2))
                            await send(.setShareConfirmationVisible(false))
                        })
                }

                if case .delegate(.dismissed) = action {
                    var newMainState = mainState
                    let selected = mainState.composeState.selectedSpaceId
                    newMainState.composeState = ComposeFeatureReducer.State()
                    newMainState.composeState.availableSpaces = mainState.spaces
                    newMainState.composeState.selectedSpaceId = selected
                    newMainState.selectedTab = .home
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

                if case .delegate(.loggedOut) = action {
                    // 진행 중인 위젯 동기화·목록 로드를 먼저 끊어, 이전 계정 데이터가 다시 쓰이지 않게 한다
                    state = .auth(AuthFeatureReducer.State())
                    WidgetMomentStore().resetForLogout()
                    WidgetCenter.shared.reloadAllTimelines()
                    return .merge(
                        .cancel(id: CancelID.widgetSync),
                        .cancel(id: CancelID.loadSpaces),
                        effect.map { .settings($0) }
                    )
                }

                // 1:1 이름 변경·연결 해제 → 스페이스 목록을 다시 받아 홈·작성·설정을 함께 갱신한다
                if case .delegate(.spaceRenamed) = action {
                    return effect.map { .settings($0) }.merge(with: loadSpaces())
                }

                if case .delegate(.disconnected) = action {
                    var newMainState = mainState
                    newMainState.isHistoryPresented = false
                    newMainState.selectedTab = .home
                    newMainState.connectState = ConnectFeatureReducer.State()
                    newMainState.apply(spaces: mainState.spaces.filter { $0.type != .oneToOne })
                    state = .main(newMainState)
                    return effect.map { .settings($0) }.merge(with: loadSpaces())
                }

                return effect.map { .settings($0) }

            case .groupDetail(let action):
                guard case .main(var mainState) = state, var detail = mainState.groupDetail else {
                    return .none
                }
                let effect = GroupDetailFeature().reduce(into: &detail, action: action)
                mainState.groupDetail = detail

                switch action {
                case .delegate(.openSettings):
                    mainState.groupSettings = GroupSettingsFeature.State(
                        space: detail.space, currentUserId: mainState.currentUser?.id)
                case .delegate(.compose(let spaceId)):
                    mainState.composeState.selectedSpaceId = spaceId
                    mainState.selectedSpaceId = spaceId
                    mainState.selectedTab = .compose
                default:
                    break
                }
                state = .main(mainState)
                return effect.map { .groupDetail($0) }

            case .groupSettings(let action):
                guard case .main(var mainState) = state, var settings = mainState.groupSettings else {
                    return .none
                }
                let effect = GroupSettingsFeature().reduce(into: &settings, action: action)
                mainState.groupSettings = settings

                switch action {
                case .delegate(.spaceChanged):
                    state = .main(mainState)
                    return effect.map { .groupSettings($0) }
                        .merge(with: loadSpaces())
                        .merge(with: .send(.groupDetail(.onAppear)))
                case .delegate(.notificationsChanged(let enabled)):
                    // 알림 설정은 이 스페이스 값만 바꾸면 되므로 목록을 다시 받지 않는다
                    let spaceId = settings.space.id
                    mainState.apply(spaces: mainState.spaces.map { space in
                        guard space.id == spaceId else { return space }
                        var updated = space
                        updated.notificationsEnabled = enabled
                        return updated
                    })
                    state = .main(mainState)
                    return effect.map { .groupSettings($0) }
                case .delegate(.exited):
                    mainState.groupSettings = nil
                    mainState.groupDetail = nil
                    mainState.apply(spaces: mainState.spaces.filter { $0.id != settings.space.id })
                    state = .main(mainState)
                    return effect.map { .groupSettings($0) }.merge(with: loadSpaces())
                default:
                    state = .main(mainState)
                    return effect.map { .groupSettings($0) }
                }

            case .groupCreate(let action):
                guard case .main(var mainState) = state, var create = mainState.groupCreate else {
                    return .none
                }
                let effect = GroupCreateFeature().reduce(into: &create, action: action)
                mainState.groupCreate = create

                switch action {
                case .delegate(.created):
                    mainState.groupCreate = nil
                    state = .main(mainState)
                    return effect.map { .groupCreate($0) }.merge(with: loadSpaces())
                case .delegate(.cancelled):
                    mainState.groupCreate = nil
                    state = .main(mainState)
                    return effect.map { .groupCreate($0) }
                case .createResponse(.success):
                    // 시트가 코드 공유 단계로 넘어가는 동안 홈에 새 카드가 미리 생기도록 목록을 갱신한다
                    state = .main(mainState)
                    return effect.map { .groupCreate($0) }.merge(with: loadSpaces())
                default:
                    state = .main(mainState)
                    return effect.map { .groupCreate($0) }
                }

            case .groupJoin(let action):
                guard case .main(var mainState) = state, var join = mainState.groupJoin else {
                    return .none
                }
                let effect = GroupJoinFeature().reduce(into: &join, action: action)
                mainState.groupJoin = join

                switch action {
                case .delegate(.requested(let request)):
                    // 방장이 수락하기 전까지 그룹은 목록에 없다. 홈에는 대기 중 요청으로 보인다
                    mainState.groupJoin = nil
                    if !mainState.homeState.pendingJoinRequests.contains(where: { $0.id == request.id }) {
                        mainState.homeState.pendingJoinRequests.insert(request, at: 0)
                    }
                    state = .main(mainState)
                    return effect.map { .groupJoin($0) }.merge(with: loadSpaces())
                case .delegate(.cancelled):
                    mainState.groupJoin = nil
                    state = .main(mainState)
                    return effect.map { .groupJoin($0) }
                default:
                    state = .main(mainState)
                    return effect.map { .groupJoin($0) }
                }
            }
        }
    }

}

extension AppFeature: Reducer {}

// MARK: - Widget Sync Helper
/// 위젯 캐시 이미지의 최대 변 길이 — systemMedium(3x 기준 약 1080px)에 충분하고,
/// 위젯 확장의 메모리 한도(약 30MB) 안에서 안전한 크기.
private let widgetImageMaxDimension: CGFloat = 800
private let widgetImageDownloadTimeout: TimeInterval = 10
/// 우리 스토리지가 주는 이미지는 1MB 안쪽(2048px · JPEG 0.85)이다.
/// 그보다 훨씬 큰 응답은 위젯에 싣지 않고 텍스트 폴백으로 떨어뜨린다.
private let widgetImageMaxBytes = 10 * 1024 * 1024

/// 스페이스 목록으로 위젯 데이터를 맞춘다. 스페이스마다 나 제외 최신 모먼트 1건과 그 사진을 저장하고,
/// 위젯 설정에서 고를 수 있는 스페이스 목록을 갱신한다. 목록에서 빠진 스페이스의 데이터와 사진은 지운다.
private func syncWidget(spaces: [Space], myUserId: UUID?) async {
    // 취소되면(로그아웃·새 동기화) 더 쓰지 않는다. 사진 내려받기 사이사이에서도 확인한다
    guard !Task.isCancelled else { return }
    let store = WidgetMomentStore()
    // 전체 상태를 비워 두면 위젯은 스페이스별 상태를 읽는다(로그인·연결 필요가 아님을 뜻함)
    store.saveState(.empty)
    store.saveSpaces(spaces.map { space in
        WidgetSpaceInfo(id: space.id, name: widgetSpaceName(space, myUserId: myUserId), isGroup: space.isGroup)
    })

    var keptImages = Set<String>()
    for space in spaces {
        guard let moment = space.latestMoment, moment.author.id != myUserId else {
            store.saveState(.empty, for: space.id)
            continue
        }
        let imageFileName = await cacheWidgetImage(for: moment, using: store)
        guard !Task.isCancelled else { return }
        if let imageFileName { keptImages.insert(imageFileName) }
        store.saveState(.hasMoment(WidgetMomentSnapshot(
            momentId: moment.id,
            spaceId: space.id,
            authorNickname: moment.author.nickname,
            text: moment.text,
            imageFileName: imageFileName,
            createdAt: moment.createdAt,
            hasImage: moment.imageURL != nil
        )), for: space.id)
    }

    guard !Task.isCancelled else { return }
    store.removeSpaceStates(except: Set(spaces.map(\.id)))
    store.pruneImageCache(keeping: keptImages)
    WidgetCenter.shared.reloadAllTimelines()
}

private func widgetSpaceName(_ space: Space, myUserId: UUID?) -> String {
    if let name = space.name, !name.isEmpty { return name }
    if let partner = space.partner(excluding: myUserId) { return "\(partner.nickname)님과의 스페이스" }
    return space.isGroup ? "그룹" : "1:1 스페이스"
}

/// 모먼트 사진을 내려받아 위젯 캐시에 저장하고 파일명을 돌려준다.
/// 같은 모먼트가 이미 캐시돼 있으면 재다운로드하지 않는다(파일명이 momentId로 결정적).
/// 실패 시 nil — 사진 때문에 위젯이 비지 않도록 텍스트 폴백으로 렌더된다.
private func cacheWidgetImage(for moment: Moment, using store: WidgetMomentStore) async -> String? {
    guard let imageURL = moment.imageURL else { return nil }

    let fileName = "\(moment.id.uuidString).jpg"
    if store.loadCachedImage(fileName: fileName) != nil {
        return fileName
    }

    var request = URLRequest(url: imageURL)
    request.timeoutInterval = widgetImageDownloadTimeout

    do {
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse,
              (200...299).contains(http.statusCode),
              data.count <= widgetImageMaxBytes,
              let downsampled = UIImage(data: data)?
                  .resizedAndCompressed(maxDimension: widgetImageMaxDimension)
        else {
            return nil
        }
        try store.cacheImage(downsampled, fileName: fileName)
        return fileName
    } catch {
        return nil
    }
}
