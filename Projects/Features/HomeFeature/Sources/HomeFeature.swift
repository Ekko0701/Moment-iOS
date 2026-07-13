import Foundation
import ComposableArchitecture
import Domain
import Networking

public struct HomeFeature {
    public struct State: Equatable {
        /// App 계층이 로그인/스페이스 로드 시 주입한다.
        public var space: Space? = nil
        public var currentUser: UserProfile? = nil
        public var latestMoment: Moment? = nil
        public var isLoading = false
        public var error: DomainError? = nil

        public init() {}

        /// 스페이스 멤버 중 나를 제외한 상대방.
        public var partner: UserProfile? {
            guard let space, let me = currentUser else { return space?.members.first }
            return space.members.first { $0.id != me.id }
        }

        /// 연결 후 함께한 일수 (연결 당일 = 1일차).
        public var daysTogether: Int? {
            guard let createdAt = space?.createdAt else { return nil }
            let days = Calendar.current.dateComponents([.day], from: createdAt, to: Date()).day ?? 0
            return days + 1
        }
    }

    public enum Action {
        case onAppear
        case latestLoaded(Result<Moment?, DomainError>)
        case spaceCardTapped
        case dismissError
        case delegate(Delegate)

        public enum Delegate: Equatable {
            case openFeed
        }
    }

    public var body: some ReducerOf<Self> {
        Reduce<State, Action> { state, action in
            switch action {
            case .onAppear:
                guard let spaceId = state.space?.id else { return .none }
                state.isLoading = true
                return .run { send in
                    @Dependency(\.momentRepository) var momentRepository
                    do {
                        let moment = try await momentRepository.latestExcludingMine(spaceId: spaceId)
                        await send(.latestLoaded(.success(moment)))
                    } catch {
                        let domainError = error as? DomainError ?? .unknown(code: "ERROR", message: error.localizedDescription)
                        await send(.latestLoaded(.failure(domainError)))
                    }
                }

            case .latestLoaded(.success(let moment)):
                state.isLoading = false
                state.latestMoment = moment
                return .none

            case .latestLoaded(.failure):
                // 미리보기 실패는 홈을 막을 이유가 없다 — 카드에서 미리보기만 생략
                state.isLoading = false
                return .none

            case .spaceCardTapped:
                return .send(.delegate(.openFeed))

            case .dismissError:
                state.error = nil
                return .none

            case .delegate:
                return .none
            }
        }
    }

    public init() {}
}

extension HomeFeature: Reducer {}

public typealias HomeFeatureReducer = HomeFeature
