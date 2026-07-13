import Foundation
import SwiftUI
import ComposableArchitecture
import Domain
import Networking
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

        case timelineResponse(Result<PaginatedMoments, DomainError>)
        case reactionResponse(momentId: UUID, emoji: String, Result<Void, DomainError>)
        case removeReactionResponse(momentId: UUID, Result<Void, DomainError>)
    }

    public var body: some ReducerOf<Self> {
        Reduce<State, Action> { state, action in
            switch action {
            case .onAppear:
                guard let spaceId = state.selectedSpaceId else {
                    return .none
                }
                state.isLoading = true
                return .run { [spaceId] send in
                    @Dependency(\.momentRepository) var momentRepository
                    do {
                        let moments = try await momentRepository.timeline(
                            spaceId: spaceId,
                            cursor: nil,
                            limit: 20
                        )
                        await send(.timelineResponse(.success(moments)))
                    } catch {
                        let domainError = error as? DomainError ?? .unknown(code: "ERROR", message: error.localizedDescription)
                        await send(.timelineResponse(.failure(domainError)))
                    }
                }

            case .refresh:
                guard let spaceId = state.selectedSpaceId else {
                    return .none
                }
                state.isLoading = true
                state.moments = []
                state.nextCursor = nil
                return .run { [spaceId] send in
                    @Dependency(\.momentRepository) var momentRepository
                    do {
                        let moments = try await momentRepository.timeline(
                            spaceId: spaceId,
                            cursor: nil,
                            limit: 20
                        )
                        await send(.timelineResponse(.success(moments)))
                    } catch {
                        let domainError = error as? DomainError ?? .unknown(code: "ERROR", message: error.localizedDescription)
                        await send(.timelineResponse(.failure(domainError)))
                    }
                }

            case .loadMore:
                guard let spaceId = state.selectedSpaceId,
                      let nextCursor = state.nextCursor,
                      !state.isLoadingMore else {
                    return .none
                }
                state.isLoadingMore = true
                return .run { [spaceId, nextCursor] send in
                    @Dependency(\.momentRepository) var momentRepository
                    do {
                        let moments = try await momentRepository.timeline(
                            spaceId: spaceId,
                            cursor: nextCursor,
                            limit: 20
                        )
                        await send(.timelineResponse(.success(moments)))
                    } catch {
                        let domainError = error as? DomainError ?? .unknown(code: "ERROR", message: error.localizedDescription)
                        await send(.timelineResponse(.failure(domainError)))
                    }
                }

            case .reactionTapped(let momentId, let emoji):
                let previousReaction = state.selectedReactions[momentId]

                if previousReaction == emoji {
                    state.selectedReactions.removeValue(forKey: momentId)
                    return .run { [momentId] send in
                        @Dependency(\.momentRepository) var momentRepository
                        do {
                            try await momentRepository.removeReaction(from: momentId)
                            await send(.removeReactionResponse(momentId: momentId, .success(())))
                        } catch {
                            let domainError = error as? DomainError ?? .unknown(code: "ERROR", message: error.localizedDescription)
                            await send(.removeReactionResponse(momentId: momentId, .failure(domainError)))
                        }
                    }
                } else {
                    state.selectedReactions[momentId] = emoji
                    return .run { [momentId, emoji] send in
                        @Dependency(\.momentRepository) var momentRepository
                        do {
                            try await momentRepository.react(to: momentId, emoji: emoji)
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
                    @Dependency(\.momentRepository) var momentRepository
                    do {
                        try await momentRepository.removeReaction(from: momentId)
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

            case .timelineResponse(.success(let paginated)):
                if state.isLoadingMore {
                    state.moments.append(contentsOf: paginated.moments)
                    state.isLoadingMore = false
                } else {
                    state.moments = paginated.moments
                    state.isLoading = false
                }
                state.nextCursor = paginated.nextCursor
                state.error = nil
                return .none

            case .timelineResponse(.failure(let error)):
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
