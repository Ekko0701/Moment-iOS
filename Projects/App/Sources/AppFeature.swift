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
        // 스페이스 미연결 상태에서 홈 탭이 표시할 연결 화면 상태
        public var connectState: ConnectFeatureReducer.State
        // 로그인 직후엔 홈(스페이스 카드)이 현관 역할을 한다
        public var selectedTab: Tab = .home
        public var currentSpace: Space? = nil
        public var currentUser: UserProfile? = nil
        // 히스토리(Feed)를 네비게이션 스택으로 표시할지 여부
        public var isHistoryPresented = false
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
        case setHistoryPresented(Bool)
        case setShareConfirmationVisible(Bool)

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
                if let space = spaces.first {
                    mainState.currentSpace = space
                    mainState.homeState.space = space
                    mainState.feedState.selectedSpaceId = space.id
                    mainState.composeState.selectedSpaceId = space.id
                    mainState.settingsState.currentSpace = space
                } else {
                    // Save widget state: need to connect
                    let store = WidgetMomentStore()
                    store.saveState(.needConnect)
                    store.clearCache()
                    WidgetCenter.shared.reloadAllTimelines()
                }
                state = .main(mainState)
                return .none

            case .appInitialized(.failure):
                state = .auth(AuthFeatureReducer.State())
                // Save widget state: need login
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
                if let space = spaces.first {
                    mainState.currentSpace = space
                    mainState.homeState.space = space
                    mainState.feedState.selectedSpaceId = space.id
                    mainState.composeState.selectedSpaceId = space.id
                    mainState.settingsState.currentSpace = space
                    mainState.connectState = ConnectFeatureReducer.State()
                } else {
                    // 아직 스페이스 없음 → 홈 탭이 연결 화면을 유지한다
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
                }
                return .none

            case .refreshConnection:
                guard case .main(var mainState) = state, mainState.currentSpace == nil else {
                    return .none
                }
                // 받은 초대 목록 갱신 + 스페이스 재확인을 동시에 수행.
                // 스페이스가 생겼으면 spacesLoaded 핸들러가 홈 탭을 스페이스 홈으로 전환한다.
                let effect = ConnectFeatureReducer().reduce(into: &mainState.connectState, action: .onAppear)
                state = .main(mainState)
                return effect.map { Action.connect($0) }
                    .merge(with: .run { [sessionUseCase = self.sessionUseCase] send in
                        let result: Result<[Space], DomainError> = await Result {
                            try await sessionUseCase.mySpaces()
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
                // 히스토리를 열 때마다 타임라인을 로드한다.
                // (피드가 탭이던 시절에는 탭 진입이 로드를 트리거했지만,
                //  홈 카드 push 구조에서는 여기가 유일한 진입 트리거다)
                if isPresented {
                    return .send(.feed(.onAppear))
                }
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
                        .merge(with: .run { [sessionUseCase = self.sessionUseCase] send in
                            let result: Result<[Space], DomainError> = await Result {
                                try await sessionUseCase.mySpaces()
                            }.mapError { error in
                                error as? DomainError ?? .unknown(code: "ERROR", message: error.localizedDescription)
                            }
                            await send(.spacesLoaded(result: result))
                        })
                }

                return effect.map { .auth($0) }

            case .connect(let action):
                guard case .main(var mainState) = state else {
                    return .none
                }
                let effect = ConnectFeatureReducer().reduce(into: &mainState.connectState, action: action)
                state = .main(mainState)

                // Handle delegates from connect
                if case .delegate(.connected) = action {
                    return effect.map { .connect($0) }
                        .merge(with: .run { [sessionUseCase = self.sessionUseCase] send in
                            let result: Result<[Space], DomainError> = await Result {
                                try await sessionUseCase.mySpaces()
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

                // 카드 탭 → 히스토리 네비게이션 스택 표시
                if case .delegate(.openFeed) = action {
                    return effect.map { .home($0) }
                        .merge(with: .send(.setHistoryPresented(true)))
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

                // Handle delegates from compose
                if case .delegate(.shared) = action {
                    var newMainState = mainState
                    newMainState.composeState = ComposeFeatureReducer.State()
                    newMainState.selectedTab = .home
                    // 지난 순간으로 점프하지 않고 홈에 머문다 — 내 모먼트는 홈 히어로(상대 전용)에
                    // 보이지 않으므로, 완료 확인은 화면 이동 대신 가벼운 토스트가 담당
                    newMainState.showsShareConfirmation = true
                    newMainState.feedState = FeedFeatureReducer.State()
                    newMainState.feedState.selectedSpaceId = newMainState.currentSpace?.id
                    state = .main(newMainState)
                    return effect.map { .compose($0) }
                        .merge(with: .send(.feed(.onAppear))) // 타임라인 선로드·위젯 동기화 유지
                        .merge(with: .run { send in
                            try? await Task.sleep(for: .seconds(2))
                            await send(.setShareConfirmationVisible(false))
                        })
                }

                if case .delegate(.dismissed) = action {
                    var newMainState = mainState
                    newMainState.composeState = ComposeFeatureReducer.State()
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

                // Handle delegates from settings
                if case .delegate(.loggedOut) = action {
                    state = .auth(AuthFeatureReducer.State())
                    return effect.map { .settings($0) }
                }

                // 스페이스 이름 변경 → 홈·설정이 보는 currentSpace를 갱신한다
                // (설정 모듈이 홈 상태를 직접 건드리지 않고 부모가 중계하는 구조)
                if case .delegate(.spaceRenamed(let newName)) = action,
                   let space = mainState.currentSpace {
                    var newMainState = mainState
                    let renamed = Space(
                        id: space.id,
                        type: space.type,
                        name: newName,
                        maxMembers: space.maxMembers,
                        status: space.status,
                        members: space.members,
                        createdAt: space.createdAt
                    )
                    newMainState.currentSpace = renamed
                    newMainState.homeState.space = renamed
                    newMainState.settingsState.currentSpace = renamed
                    state = .main(newMainState)
                    return effect.map { .settings($0) }
                }

                if case .delegate(.disconnected) = action {
                    // 연결 해제 → 메인 탭 유지, 홈 탭이 연결 화면으로 돌아간다
                    var newMainState = mainState
                    newMainState.currentSpace = nil
                    newMainState.homeState = HomeFeatureReducer.State()
                    newMainState.homeState.currentUser = newMainState.currentUser
                    newMainState.feedState = FeedFeatureReducer.State()
                    newMainState.composeState = ComposeFeatureReducer.State()
                    newMainState.settingsState.currentSpace = nil
                    newMainState.connectState = ConnectFeatureReducer.State()
                    newMainState.selectedTab = .home
                    newMainState.isHistoryPresented = false
                    state = .main(newMainState)
                    let store = WidgetMomentStore()
                    store.saveState(.needConnect)
                    store.clearCache()
                    WidgetCenter.shared.reloadAllTimelines()
                    return effect.map { .settings($0) }
                }

                return effect.map { .settings($0) }
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
