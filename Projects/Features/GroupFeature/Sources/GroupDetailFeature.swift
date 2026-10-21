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
        case membersLoaded(Result<[SpaceMember], DomainError>)
        case settingsTapped
        case composeTapped
        case dismissError
        case delegate(Delegate)

        public enum Delegate: Equatable {
            case openSettings
            case compose(spaceId: UUID)
        }
    }

    public var body: some ReducerOf<Self> {
        Reduce<State, Action> { state, action in
            switch action {
            case .onAppear:
                state.isLoading = true
                return .run { [spaceId = state.space.id] send in
                    @Dependency(\.groupUseCase) var groupUseCase
                    do {
                        await send(.membersLoaded(.success(try await groupUseCase.members(spaceId: spaceId))))
                    } catch {
                        await send(.membersLoaded(.failure(error.asDomainError)))
                    }
                }

            case .membersLoaded(.success(let members)):
                state.isLoading = false
                state.members = members
                return .none

            case .membersLoaded(.failure(let error)):
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
