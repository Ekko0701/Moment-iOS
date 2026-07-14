import Foundation
import SwiftUI
import ComposableArchitecture
import Domain
import Dependencies
import MomentUIKit

public struct SettingsFeature {
    public struct State: Equatable {
        public var userProfile: UserProfile? = nil
        public var currentSpace: Space? = nil
        public var nicknameInput: String = ""
        public var isLoading = false
        public var error: DomainError? = nil
        public var showDisconnectConfirm = false
        public var showDeleteAccountConfirm = false
        public var showNicknameSheet = false

        public init() {}
    }

    public enum Action {
        case onAppear
        case nicknameChanged(String)
        case nicknameSubmitTapped
        case showNicknameEditSheet
        case hideNicknameEditSheet
        case disconnectTapped
        case confirmDisconnect
        case cancelDisconnect
        case deleteAccountTapped
        case confirmDeleteAccount
        case cancelDeleteAccount
        case logoutTapped
        case dismissError

        case profileResponse(Result<UserProfile, DomainError>)
        case nicknameUpdateResponse(Result<UserProfile, DomainError>)
        case disconnectResponse(Result<Void, DomainError>)
        case deleteResponse(Result<Void, DomainError>)
        case delegate(Delegate)

        public enum Delegate: Equatable {
            case loggedOut
            case disconnected
        }
    }

    public var body: some ReducerOf<Self> {
        Reduce<State, Action> { state, action in
            switch action {
            case .onAppear:
                state.isLoading = true
                return .run { send in
                    @Dependency(\.settingsUseCase) var settingsUseCase
                    do {
                        let profile = try await settingsUseCase.myProfile()
                        await send(.profileResponse(.success(profile)))
                    } catch {
                        let domainError = error as? DomainError ?? .unknown(code: "ERROR", message: error.localizedDescription)
                        await send(.profileResponse(.failure(domainError)))
                    }
                }

            case .nicknameChanged(let newNickname):
                state.nicknameInput = newNickname
                return .none

            case .nicknameSubmitTapped:
                let nickname = state.nicknameInput.trimmingCharacters(in: .whitespaces)
                guard !nickname.isEmpty else {
                    state.error = .unknown(code: "ERROR", message: "닉네임을 입력해 주세요.")
                    return .none
                }

                state.isLoading = true
                return .run { [nickname] send in
                    @Dependency(\.settingsUseCase) var settingsUseCase
                    do {
                        let profile = try await settingsUseCase.updateNickname(nickname)
                        await send(.nicknameUpdateResponse(.success(profile)))
                    } catch {
                        let domainError = error as? DomainError ?? .unknown(code: "ERROR", message: error.localizedDescription)
                        await send(.nicknameUpdateResponse(.failure(domainError)))
                    }
                }

            case .showNicknameEditSheet:
                state.showNicknameSheet = true
                state.nicknameInput = state.userProfile?.nickname ?? ""
                return .none

            case .hideNicknameEditSheet:
                state.showNicknameSheet = false
                state.nicknameInput = ""
                return .none

            case .disconnectTapped:
                state.showDisconnectConfirm = true
                return .none

            case .confirmDisconnect:
                guard let spaceId = state.currentSpace?.id else {
                    state.error = .unknown(code: "ERROR", message: "스페이스를 찾을 수 없습니다.")
                    return .none
                }

                state.isLoading = true
                state.showDisconnectConfirm = false
                return .run { [spaceId] send in
                    @Dependency(\.settingsUseCase) var settingsUseCase
                    do {
                        try await settingsUseCase.leaveSpace(spaceId: spaceId)
                        await send(.disconnectResponse(.success(())))
                    } catch {
                        let domainError = error as? DomainError ?? .unknown(code: "ERROR", message: error.localizedDescription)
                        await send(.disconnectResponse(.failure(domainError)))
                    }
                }

            case .cancelDisconnect:
                state.showDisconnectConfirm = false
                return .none

            case .deleteAccountTapped:
                state.showDeleteAccountConfirm = true
                return .none

            case .confirmDeleteAccount:
                state.isLoading = true
                state.showDeleteAccountConfirm = false
                return .run { send in
                    @Dependency(\.settingsUseCase) var settingsUseCase
                    do {
                        try await settingsUseCase.deleteAccount()
                        await send(.deleteResponse(.success(())))
                    } catch {
                        let domainError = error as? DomainError ?? .unknown(code: "ERROR", message: error.localizedDescription)
                        await send(.deleteResponse(.failure(domainError)))
                    }
                }

            case .cancelDeleteAccount:
                state.showDeleteAccountConfirm = false
                return .none

            case .logoutTapped:
                return .send(.delegate(.loggedOut))

            case .dismissError:
                state.error = nil
                return .none

            case .profileResponse(.success(let profile)):
                state.userProfile = profile
                state.isLoading = false
                state.error = nil
                return .none

            case .profileResponse(.failure(let error)):
                state.isLoading = false
                state.error = error
                return .none

            case .nicknameUpdateResponse(.success(let profile)):
                state.userProfile = profile
                state.nicknameInput = ""
                state.showNicknameSheet = false
                state.isLoading = false
                state.error = nil
                return .none

            case .nicknameUpdateResponse(.failure(let error)):
                state.isLoading = false
                state.error = error
                return .none

            case .disconnectResponse(.success):
                state.isLoading = false
                state.error = nil
                return .send(.delegate(.disconnected))

            case .disconnectResponse(.failure(let error)):
                state.isLoading = false
                state.error = error
                return .none

            case .deleteResponse(.success):
                state.isLoading = false
                state.error = nil
                return .send(.delegate(.loggedOut))

            case .deleteResponse(.failure(let error)):
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

extension SettingsFeature: Reducer {}

public typealias SettingsFeatureReducer = SettingsFeature
