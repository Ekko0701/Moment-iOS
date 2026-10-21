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
        public var selectedReactions: [UUID: String] = [:]

        public init() {}
    }

    public enum Action {
        case onAppear
        case refresh
        case loadMore
        case reactionTapped(momentId: UUID, emoji: String)
        case removeReaction(momentId: UUID)
        case momentTapped(Moment)
        case dismissError

        /// 요청한 스페이스와 페이지 종류를 함께 돌려받아, 그사이 스페이스가 바뀌었으면 응답을 버린다
        case timelineResponse(spaceId: UUID, page: Page, Result<PaginatedMoments, DomainError>)
        case reactionResponse(momentId: UUID, emoji: String, Result<Void, DomainError>)
        case removeReactionResponse(momentId: UUID, Result<Void, DomainError>)
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
                let previousReaction = state.selectedReactions[momentId]

                if previousReaction == emoji {
                    state.selectedReactions.removeValue(forKey: momentId)
                    return .run { [momentId] send in
                        @Dependency(\.feedUseCase) var feedUseCase
                        do {
                            try await feedUseCase.removeReaction(from: momentId)
                            await send(.removeReactionResponse(momentId: momentId, .success(())))
                        } catch {
                            let domainError = error as? DomainError ?? .unknown(code: "ERROR", message: error.localizedDescription)
                            await send(.removeReactionResponse(momentId: momentId, .failure(domainError)))
                        }
                    }
                } else {
                    state.selectedReactions[momentId] = emoji
                    return .run { [momentId, emoji] send in
                        @Dependency(\.feedUseCase) var feedUseCase
                        do {
                            try await feedUseCase.react(to: momentId, emoji: emoji)
                            await send(.reactionResponse(momentId: momentId, emoji: emoji, .success(())))
                        } catch {
                            let domainError = error as? DomainError ?? .unknown(code: "ERROR", message: error.localizedDescription)
                            await send(.reactionResponse(momentId: momentId, emoji: emoji, .failure(domainError)))
                        }
                    }
                }

            case .removeReaction(let momentId):
                state.selectedReactions.removeValue(forKey: momentId)
                return .run { [momentId] send in
                    @Dependency(\.feedUseCase) var feedUseCase
                    do {
                        try await feedUseCase.removeReaction(from: momentId)
                        await send(.removeReactionResponse(momentId: momentId, .success(())))
                    } catch {
                        let domainError = error as? DomainError ?? .unknown(code: "ERROR", message: error.localizedDescription)
                        await send(.removeReactionResponse(momentId: momentId, .failure(domainError)))
                    }
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

            case .reactionResponse(let momentId, let emoji, .success):
                state.selectedReactions[momentId] = emoji
                state.error = nil
                return .none

            case .reactionResponse(_, _, .failure(let error)):
                state.error = error
                return .none

            case .removeReactionResponse(_, .success):
                state.error = nil
                return .none

            case .removeReactionResponse(_, .failure(let error)):
                state.error = error
                return .none
            }
        }
    }

    public init() {}
}

extension FeedFeature: Reducer {}

public typealias FeedFeatureReducer = FeedFeature
