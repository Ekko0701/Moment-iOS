import Foundation
import SwiftUI
import ComposableArchitecture
import Domain
import Networking
import CoreKit
import MomentUIKit

public struct ConnectFeature {
    public struct State: Equatable {
        public var selectedTab: Tab = .code
        public var issuedCode: String? = nil
        public var codeInput: String = ""
        public var searchHandle: String = ""
        public var searchResult: UserProfile? = nil
        public var receivedInvitations: [Invitation] = []
        public var sentInvitations: [Invitation] = []
        public var isLoading = false
        public var error: DomainError? = nil

        public enum Tab {
            case code
            case search
        }

        public init() {}
    }

    public enum Action {
        case onAppear
        case tabSelected(State.Tab)
        case codeInputChanged(String)
        case searchHandleChanged(String)
        case issueCodeTapped
        case submitCodeTapped
        case searchTapped
        case sendToUserTapped(UUID)
        case respondTapped(id: UUID, action: InvitationAction)
        case dismissError

        case codeResponse(Result<String, DomainError>)
        case submitCodeResponse(Result<Invitation, DomainError>)
        case searchResponse(Result<UserProfile?, DomainError>)
        case invitationsResponse(Result<(received: [Invitation], sent: [Invitation]), DomainError>)
        case respondResponse(Result<Void, DomainError>)

        case delegate(Delegate)

        public enum Delegate: Equatable {
            case connected
        }
    }

    public var body: some ReducerOf<Self> {
        Reduce<State, Action> { state, action in
            switch action {
            case .onAppear:
                state.isLoading = true
                return .run { send in
                    @Dependency(\.spaceRepository) var spaceRepository
                    do {
                        let received = try await spaceRepository.invitations(direction: .received)
                        let sent = try await spaceRepository.invitations(direction: .sent)
                        await send(.invitationsResponse(.success((received: received, sent: sent))))
                    } catch {
                        let domainError = error as? DomainError ?? .unknown(code: "ERROR", message: error.localizedDescription)
                        await send(.invitationsResponse(.failure(domainError)))
                    }
                }

            case .tabSelected(let tab):
                state.selectedTab = tab
                return .none

            case .codeInputChanged(let input):
                state.codeInput = input
                return .none

            case .searchHandleChanged(let input):
                state.searchHandle = input
                return .none

            case .issueCodeTapped:
                state.isLoading = true
                return .run { send in
                    @Dependency(\.spaceRepository) var spaceRepository
                    do {
                        let code = try await spaceRepository.issueInviteCode()
                        await send(.codeResponse(.success(code)))
                    } catch {
                        let domainError = error as? DomainError ?? .unknown(code: "ERROR", message: error.localizedDescription)
                        await send(.codeResponse(.failure(domainError)))
                    }
                }

            case .submitCodeTapped:
                guard !state.codeInput.isEmpty else {
                    state.error = .unknown(code: "ERROR", message: "코드를 입력해 주세요.")
                    return .none
                }
                state.isLoading = true
                return .run { [code = state.codeInput] send in
                    @Dependency(\.spaceRepository) var spaceRepository
                    do {
                        let invitation = try await spaceRepository.sendInvitationByCode(code: code)
                        await send(.submitCodeResponse(.success(invitation)))
                    } catch {
                        let domainError = error as? DomainError ?? .unknown(code: "ERROR", message: error.localizedDescription)
                        await send(.submitCodeResponse(.failure(domainError)))
                    }
                }

            case .searchTapped:
                guard !state.searchHandle.isEmpty else {
                    state.error = .unknown(code: "ERROR", message: "검색 핸들을 입력해 주세요.")
                    return .none
                }
                state.isLoading = true
                return .run { [handle = state.searchHandle] send in
                    @Dependency(\.userRepository) var userRepository
                    do {
                        let user = try await userRepository.search(handle: handle)
                        await send(.searchResponse(.success(user)))
                    } catch {
                        let domainError = error as? DomainError ?? .unknown(code: "ERROR", message: error.localizedDescription)
                        await send(.searchResponse(.failure(domainError)))
                    }
                }

            case .sendToUserTapped(let userId):
                state.isLoading = true
                return .run { [userId] send in
                    @Dependency(\.spaceRepository) var spaceRepository
                    do {
                        let invitation = try await spaceRepository.sendInvitation(toUserId: userId)
                        await send(.submitCodeResponse(.success(invitation)))
                    } catch {
                        let domainError = error as? DomainError ?? .unknown(code: "ERROR", message: error.localizedDescription)
                        await send(.submitCodeResponse(.failure(domainError)))
                    }
                }

            case .respondTapped(let id, let action):
                state.isLoading = true
                return .run { [id, action] send in
                    @Dependency(\.spaceRepository) var spaceRepository
                    do {
                        try await spaceRepository.respond(to: id, action: action)
                        // Only send connected delegate when accepting; for decline/cancel, just reload invitations
                        if action == .accept {
                            await send(.respondResponse(.success(())))
                        } else {
                            // Reload invitations list after decline/cancel
                            await send(.onAppear)
                        }
                    } catch {
                        let domainError = error as? DomainError ?? .unknown(code: "ERROR", message: error.localizedDescription)
                        await send(.respondResponse(.failure(domainError)))
                    }
                }

            case .dismissError:
                state.error = nil
                return .none

            case .codeResponse(.success(let code)):
                state.issuedCode = code
                state.isLoading = false
                state.error = nil
                return .none

            case .codeResponse(.failure(let error)):
                state.isLoading = false
                state.error = error
                return .none

            case .submitCodeResponse(.success):
                state.codeInput = ""
                state.searchHandle = ""
                state.searchResult = nil
                state.isLoading = false
                state.error = nil
                return .none

            case .submitCodeResponse(.failure(let error)):
                state.isLoading = false
                state.error = error
                return .none

            case .searchResponse(.success(let result)):
                state.searchResult = result
                state.isLoading = false
                state.error = nil
                return .none

            case .searchResponse(.failure(let error)):
                state.isLoading = false
                state.error = error
                return .none

            case .invitationsResponse(.success(let (received, sent))):
                state.receivedInvitations = received
                state.sentInvitations = sent
                state.isLoading = false
                state.error = nil
                return .none

            case .invitationsResponse(.failure(let error)):
                state.isLoading = false
                state.error = error
                return .none

            case .respondResponse(.success):
                state.isLoading = false
                state.error = nil
                return .send(.delegate(.connected))

            case .respondResponse(.failure(let error)):
                state.isLoading = false
                state.error = error
                return .none

            case .delegate:
                return .none
            }
        }
    }

    public init() {}
}

extension ConnectFeature: Reducer {}

public typealias ConnectFeatureReducer = ConnectFeature
