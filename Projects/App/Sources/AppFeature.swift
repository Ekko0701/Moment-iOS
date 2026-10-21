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
            if !spaces.isEmpty {
                connectState = oneToOneSpace == nil ? connectState : ConnectFeatureReducer.State()
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

    private func loadSpaces() -> Effect<Action> {
        .run { [sessionUseCase = self.sessionUseCase] send in
            let result: Result<[Space], DomainError> = await Result {
                try await sessionUseCase.mySpaces()
            }.mapError { error in
                error as? DomainError ?? .unknown(code: "ERROR", message: error.localizedDescription)
            }
            await send(.spacesLoaded(result: result))
        }
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
                if spaces.isEmpty {
                    let store = WidgetMomentStore()
                    store.saveState(.needConnect)
                    store.clearCache()
                    WidgetCenter.shared.reloadAllTimelines()
                }
                state = .main(mainState)
                return .none

            case .appInitialized(.failure):
                state = .auth(AuthFeatureReducer.State())
                let store = WidgetMomentStore()
                store.saveState(.needLogin)
                store.clearCache()
                WidgetCenter.shared.reloadAllTimelines()
                return .none

            case .spacesLoaded(.success(let spaces)):
                // 기존 메인 상태가 있으면 유지(currentUser 등 보존), 없으면 새로 만든다.
                var mainState: MainTabState
                if case .main(let existing) = state {
                    mainState = existing
                } else {
                    mainState = MainTabState()
                }
                mainState.apply(spaces: spaces)
                if spaces.isEmpty {
                    let store = WidgetMomentStore()
                    store.saveState(.needConnect)
                    store.clearCache()
                    WidgetCenter.shared.reloadAllTimelines()
                }
                state = .main(mainState)
                if mainState.currentUser == nil {
                    return .run { [sessionUseCase = self.sessionUseCase] send in
                        if let user = try? await sessionUseCase.myProfile() {
                            await send(.profileLoaded(user))
                        }
                    }
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
                mainState.groupCreate = nil
                mainState.groupJoin = nil
                state = .main(mainState)
                return .none

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
                    mainState.selectedSpaceId = spaceId
                    mainState.composeState.selectedSpaceId = spaceId
                    mainState.feedState = FeedFeatureReducer.State()
                    mainState.feedState.selectedSpaceId = spaceId
                    if space.isGroup {
                        mainState.groupDetail = GroupDetailFeature.State(space: space)
                        state = .main(mainState)
                        return effect.map { .home($0) }.merge(with: .send(.feed(.onAppear)))
                    }
                    state = .main(mainState)
                    return effect.map { .home($0) }.merge(with: .send(.setHistoryPresented(true)))

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
                }

            case .feed(let action):
                guard case .main(var mainState) = state else {
                    return .none
                }
                let effect = FeedFeatureReducer().reduce(into: &mainState.feedState, action: action)
                state = .main(mainState)

                // 1:1 타임라인을 불러오면 위젯을 갱신한다
                if case .timelineResponse(.success) = action,
                   mainState.feedState.selectedSpaceId == mainState.oneToOneSpace?.id {
                    return effect.map { .feed($0) }
                        .merge(with: .run { [feedState = mainState.feedState,
                                             myUserId = mainState.currentUser?.id] _ in
                            await syncWidgetMoment(from: feedState, excludingAuthorId: myUserId)
                        })
                }

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
                    state = .auth(AuthFeatureReducer.State())
                    return effect.map { .settings($0) }
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
                    if newMainState.spaces.isEmpty {
                        let store = WidgetMomentStore()
                        store.saveState(.needConnect)
                        store.clearCache()
                        WidgetCenter.shared.reloadAllTimelines()
                    }
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
                case .delegate(.joined(let space)):
                    // 참여한 그룹을 바로 연다. 목록은 뒤이어 서버 기준으로 다시 맞춘다
                    mainState.groupJoin = nil
                    if !mainState.spaces.contains(where: { $0.id == space.id }) {
                        mainState.apply(spaces: mainState.spaces + [space])
                    }
                    mainState.selectedSpaceId = space.id
                    mainState.composeState.selectedSpaceId = space.id
                    mainState.feedState = FeedFeatureReducer.State()
                    mainState.feedState.selectedSpaceId = space.id
                    mainState.groupDetail = GroupDetailFeature.State(space: space)
                    mainState.selectedTab = .home
                    state = .main(mainState)
                    return effect.map { .groupJoin($0) }
                        .merge(with: .send(.feed(.onAppear)))
                        .merge(with: loadSpaces())
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

private func syncWidgetMoment(from feedState: FeedFeatureReducer.State, excludingAuthorId: UUID?) async {
    let store = WidgetMomentStore()

    // 위젯 계약(F-06): "내가 작성하지 않은" 최신 모먼트만 표시한다.
    let candidates = feedState.moments.filter { moment in
        guard let excludingAuthorId else { return true }
        return moment.author.id != excludingAuthorId
    }

    guard let latestMoment = candidates.first else {
        store.saveState(.empty)
        store.pruneImageCache(keeping: nil)
        WidgetCenter.shared.reloadAllTimelines()
        return
    }

    // 사진은 App Group 컨테이너에 캐시해 둔다. 위젯 확장은 네트워크를 쓰지 않고
    // 이 캐시만 읽는다(15분 타임라인마다 재다운로드하면 낭비이고 오프라인에서도 깨진다).
    let imageFileName = await cacheWidgetImage(for: latestMoment, using: store)

    let snapshot = WidgetMomentSnapshot(
        momentId: latestMoment.id,
        spaceId: latestMoment.spaceId,
        authorNickname: latestMoment.author.nickname,
        text: latestMoment.text,
        imageFileName: imageFileName,
        createdAt: latestMoment.createdAt,
        hasImage: latestMoment.imageURL != nil
    )
    store.saveState(.hasMoment(snapshot))

    // 방금 쓴 파일만 남긴다 — 지난 모먼트 이미지가 컨테이너에 쌓이지 않게.
    store.pruneImageCache(keeping: imageFileName)

    WidgetCenter.shared.reloadAllTimelines()
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
