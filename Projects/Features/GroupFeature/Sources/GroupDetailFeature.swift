import Foundation
import ComposableArchitecture
import Domain
import Dependencies

/// 그룹 상세 상단의 멤버 스트립 — 멤버별 최신 모먼트 1건씩.
/// 타임라인은 앱 셸이 FeedFeature로 함께 보여준다.
public struct GroupDetailFeature {
    public struct State: Equatable {
        public var space: Space
        public var members: [SpaceMember] = []
        public var isLoading = false
        public var error: DomainError? = nil

        public init(space: Space) {
            self.space = space
        }

        /// 최신 모먼트가 있는 멤버가 앞, 그 안에서는 최신순. 모먼트가 없는 멤버는 가입 순서대로 뒤에
        public var orderedMembers: [SpaceMember] {
            let withMoment = members.filter { $0.latestMoment != nil }
                .sorted { ($0.latestMoment?.createdAt ?? .distantPast) > ($1.latestMoment?.createdAt ?? .distantPast) }
            let withoutMoment = members.filter { $0.latestMoment == nil }
            return withMoment + withoutMoment
        }
    }

    public enum Action {
        case onAppear
        /// 요청한 그룹을 함께 돌려받아, 그사이 다른 그룹으로 바뀌었으면 응답을 버린다
        case membersLoaded(spaceId: UUID, Result<[SpaceMember], DomainError>)
        case settingsTapped
        case composeTapped
        case dismissError
        case delegate(Delegate)

        public enum Delegate: Equatable {
            case openSettings
            case compose(spaceId: UUID)
        }
    }

    // 멤버 요청은 한 번에 하나만 살아 있다. 다시 불러오면 이전 요청은 취소된다
    private enum CancelID: Hashable, Sendable {
        case members
    }

    public var body: some ReducerOf<Self> {
        Reduce<State, Action> { state, action in
            switch action {
            case .onAppear:
                state.isLoading = true
                return .run { [spaceId = state.space.id] send in
                    @Dependency(\.groupUseCase) var groupUseCase
                    do {
                        await send(.membersLoaded(spaceId: spaceId, .success(try await groupUseCase.members(spaceId: spaceId))))
                    } catch {
                        await send(.membersLoaded(spaceId: spaceId, .failure(error.asDomainError)))
                    }
                }
                .cancellable(id: CancelID.members, cancelInFlight: true)

            case .membersLoaded(let spaceId, _) where spaceId != state.space.id:
                return .none

            case .membersLoaded(_, .success(let members)):
                state.isLoading = false
                state.members = members
                return .none

            case .membersLoaded(_, .failure(let error)):
                state.isLoading = false
                state.error = error
                return .none

            case .settingsTapped:
                return .send(.delegate(.openSettings))

            case .composeTapped:
                return .send(.delegate(.compose(spaceId: state.space.id)))

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

extension GroupDetailFeature: Reducer {}
