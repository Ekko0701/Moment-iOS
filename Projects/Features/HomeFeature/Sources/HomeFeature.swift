import Foundation
import ComposableArchitecture
import Domain
import Dependencies

/// 홈 — 내가 속한 스페이스마다 카드 한 장. 각 카드는 나를 제외한 최신 모먼트 1건을 보여준다.
/// 방장 수락을 기다리는 내 참여 요청도 함께 보여준다.
/// 데이터는 앱 셸이 내 스페이스 목록(/v1/spaces/me)과 참여 요청으로 채우며, 홈은 새로고침·진입·요청 취소만 요청한다.
public struct HomeFeature {
    public struct State: Equatable {
        public var spaces: [Space] = []
        public var currentUser: UserProfile? = nil
        public var isRefreshing = false
        /// 내가 보낸, 방장 수락을 기다리는 참여 요청
        public var pendingJoinRequests: [GroupJoinRequest] = []

        public init() {}

        public var oneToOneSpace: Space? { spaces.first { $0.type == .oneToOne } }

        /// 1:1 스페이스의 상대. 내 정보가 아직 없으면 첫 멤버로 대신한다
        public func partner(in space: Space) -> UserProfile? {
            guard space.type == .oneToOne else { return nil }
            return space.partner(excluding: currentUser?.id) ?? space.members.first
        }

        /// 연결 후 함께한 일수 (연결 당일 = 1일차)
        public func daysTogether(in space: Space, now: Date = Date()) -> Int {
            let days = Calendar.current.dateComponents([.day], from: space.createdAt, to: now).day ?? 0
            return days + 1
        }
    }

    public enum Action {
        case onAppear
        case refreshPulled
        case spaceTapped(UUID)
        case connectTapped
        case createGroupTapped
        case joinGroupTapped
        case cancelJoinRequestTapped(GroupJoinRequest)
        case delegate(Delegate)

        public enum Delegate: Equatable {
            case refresh
            case openSpace(UUID)
            case connectOneToOne
            case createGroup
            case joinGroup
            case cancelJoinRequest(GroupJoinRequest)
        }
    }

    public var body: some ReducerOf<Self> {
        Reduce<State, Action> { state, action in
            switch action {
            case .onAppear, .refreshPulled:
                state.isRefreshing = true
                return .send(.delegate(.refresh))

            case .spaceTapped(let id):
                return .send(.delegate(.openSpace(id)))

            case .connectTapped:
                return .send(.delegate(.connectOneToOne))

            case .createGroupTapped:
                return .send(.delegate(.createGroup))

            case .joinGroupTapped:
                return .send(.delegate(.joinGroup))

            case .cancelJoinRequestTapped(let request):
                // 화면에서 바로 빼고, 실제 취소는 앱 셸이 처리한 뒤 목록을 서버 기준으로 다시 맞춘다
                state.pendingJoinRequests.removeAll { $0.id == request.id }
                return .send(.delegate(.cancelJoinRequest(request)))

            case .delegate:
                return .none
            }
        }
    }

    public init() {}
}

extension HomeFeature: Reducer {}

public typealias HomeFeatureReducer = HomeFeature
