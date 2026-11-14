import Foundation
import SwiftUI
import ComposableArchitecture
import Domain
import Dependencies
import MomentUIKit
import CoreKit

public struct FeedFeature {
    public struct State: Equatable {
        public var moments: [Moment] = []
        public var nextCursor: String? = nil
        public var isLoading = false
        public var isLoadingMore = false
        public var selectedSpaceId: UUID? = nil
        public var error: DomainError? = nil

        public init() {}
    }

    public enum Action {
        case onAppear
        case refresh
        case loadMore
        case reactionTapped(momentId: UUID, emoji: String)
        case momentTapped(Moment)
        case dismissError

        /// 요청한 스페이스와 페이지 종류를 함께 돌려받아, 그사이 스페이스가 바뀌었으면 응답을 버린다
        case timelineResponse(spaceId: UUID, page: Page, Result<PaginatedMoments, DomainError>)
        /// applied: 낙관적으로 반영한 내 반응, previous: 실패하면 되돌릴 모먼트
        case reactionResponse(momentId: UUID, applied: String?, previous: Moment, Result<Void, DomainError>)
    }

    /// 첫 페이지는 목록을 교체하고, 다음 페이지는 이어 붙인다
    public enum Page: Equatable, Sendable {
        case first
        case next
    }

    // 타임라인 요청은 한 번에 하나만 살아 있다. 새 요청이 나가면 이전 요청은 취소된다
    private enum CancelID: Hashable, Sendable {
        case timeline
    }

    private static func loadTimeline(spaceId: UUID, cursor: String?, page: Page) -> Effect<Action> {
        .run { send in
            @Dependency(\.feedUseCase) var feedUseCase
            do {
                let moments = try await feedUseCase.timeline(spaceId: spaceId, cursor: cursor, limit: 20)
                await send(.timelineResponse(spaceId: spaceId, page: page, .success(moments)))
            } catch {
                let domainError = error as? DomainError ?? .unknown(code: "ERROR", message: error.localizedDescription)
                await send(.timelineResponse(spaceId: spaceId, page: page, .failure(domainError)))
            }
        }
        .cancellable(id: CancelID.timeline, cancelInFlight: true)
    }

    public var body: some ReducerOf<Self> {
        Reduce<State, Action> { state, action in
            switch action {
            case .onAppear:
                guard let spaceId = state.selectedSpaceId else {
                    return .none
                }
                state.isLoading = true
                state.isLoadingMore = false
                return Self.loadTimeline(spaceId: spaceId, cursor: nil, page: .first)

            case .refresh:
                guard let spaceId = state.selectedSpaceId else {
                    return .none
                }
                state.isLoading = true
                state.isLoadingMore = false
                state.moments = []
                state.nextCursor = nil
                return Self.loadTimeline(spaceId: spaceId, cursor: nil, page: .first)

            case .loadMore:
                guard let spaceId = state.selectedSpaceId,
                      let nextCursor = state.nextCursor,
                      !state.isLoading,
                      !state.isLoadingMore else {
                    return .none
                }
                state.isLoadingMore = true
                return Self.loadTimeline(spaceId: spaceId, cursor: nextCursor, page: .next)

            case .reactionTapped(let momentId, let emoji):
                // 같은 반응을 다시 누르면 지우고, 다른 반응이면 바꾼다. 서버 응답 전에 선택과 개수를 먼저 반영한다
                guard let index = state.moments.firstIndex(where: { $0.id == momentId }) else { return .none }
                let previous = state.moments[index]
                let applied: String? = previous.myReaction == emoji ? nil : emoji
                state.moments[index] = previous.withMyReaction(applied)
                return .run { send in
                    @Dependency(\.feedUseCase) var feedUseCase
                    let result: Result<Void, DomainError> = await Result {
                        if let applied {
                            try await feedUseCase.react(to: momentId, emoji: applied)
                        } else {
                            try await feedUseCase.removeReaction(from: momentId)
                        }
                    }.mapError { $0 as? DomainError ?? .unknown(code: "ERROR", message: $0.localizedDescription) }
                    await send(.reactionResponse(momentId: momentId, applied: applied, previous: previous, result))
                }

            case .momentTapped:
                return .none

            case .dismissError:
                state.error = nil
                return .none

            case .timelineResponse(let spaceId, _, _) where spaceId != state.selectedSpaceId:
                return .none

            case .timelineResponse(_, let page, .success(let paginated)):
                switch page {
                case .first:
                    state.moments = paginated.moments
                    state.isLoading = false
                case .next:
                    state.moments.append(contentsOf: paginated.moments)
                    state.isLoadingMore = false
                }
                state.nextCursor = paginated.nextCursor
                state.error = nil
                return .none

            case .timelineResponse(_, _, .failure(let error)):
                state.isLoading = false
                state.isLoadingMore = false
                state.error = error
                return .none

            case .reactionResponse(_, _, _, .success):
                state.error = nil
                return .none

            case .reactionResponse(let momentId, let applied, let previous, .failure(let error)):
                // 그사이 다른 반응을 누르지 않았을 때만 되돌린다
                if let index = state.moments.firstIndex(where: { $0.id == momentId }),
                   state.moments[index].myReaction == applied {
                    state.moments[index] = previous
                }
                state.error = error
                return .none
            }
        }
    }

    public init() {}
}

extension FeedFeature: Reducer {}

public typealias FeedFeatureReducer = FeedFeature
