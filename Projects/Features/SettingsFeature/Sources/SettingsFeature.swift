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
        public var spaceNameInput: String = ""
        public var showSpaceNameSheet = false

        public init() {}

        public var trimmedNickname: String { nicknameInput.trimmingCharacters(in: .whitespaces) }
        public var trimmedSpaceName: String { spaceNameInput.trimmingCharacters(in: .whitespaces) }

        /// 서버 규칙(2~12자)을 만족하고 지금 닉네임과 다를 때만 저장할 수 있다
        public var canSubmitNickname: Bool {
            let length = trimmedNickname.utf16.count
            return !isLoading
                && SettingsFeature.nicknameLength.contains(length)
                && trimmedNickname != userProfile?.nickname
        }

        /// 비우기(기본 이름으로 되돌리기)를 포함해 최대 10자이고, 지금 이름과 다를 때만 저장할 수 있다
        public var canSubmitSpaceName: Bool {
            !isLoading
                && trimmedSpaceName.utf16.count <= SettingsFeature.spaceNameMaxLength
                && trimmedSpaceName != (currentSpace?.name ?? "")
        }
    }

    /// 서버 검증과 같은 길이 규칙. 서버는 UTF-16 길이로 센다.
    public static let nicknameLength = 2...12
    public static let spaceNameMaxLength = 10

    public enum Action {
        case onAppear
        case nicknameChanged(String)
        case nicknameSubmitTapped
        case showNicknameEditSheet
        case hideNicknameEditSheet
        case spaceNameChanged(String)
        case spaceNameSubmitTapped
        case showSpaceNameEditSheet
        case hideSpaceNameEditSheet
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
        /// 성공 시 서버가 정규화한 최종 이름(공백만 입력했으면 nil)을 함께 전달한다
        case spaceRenameResponse(Result<String?, DomainError>)
        case disconnectResponse(Result<Void, DomainError>)
        case deleteResponse(Result<Void, DomainError>)
        case delegate(Delegate)

        public enum Delegate: Equatable {
            case loggedOut
            case disconnected
            /// 홈이 보는 currentSpace는 AppFeature가 들고 있으므로, 부모에게 알려 갱신하게 한다
            case spaceRenamed(String?)
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
                state.nicknameInput = String(newNickname.prefix(Self.nicknameLength.upperBound))
                return .none

            case .nicknameSubmitTapped:
                guard state.canSubmitNickname else { return .none }
                let nickname = state.trimmedNickname

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

            case .spaceNameChanged(let newName):
                state.spaceNameInput = String(newName.prefix(Self.spaceNameMaxLength))
                return .none

            case .showSpaceNameEditSheet:
                state.showSpaceNameSheet = true
                state.spaceNameInput = state.currentSpace?.name ?? ""
                return .none

            case .hideSpaceNameEditSheet:
                state.showSpaceNameSheet = false
                state.spaceNameInput = ""
                return .none

            case .spaceNameSubmitTapped:
                guard let spaceId = state.currentSpace?.id, state.canSubmitSpaceName else { return .none }
                // 공백만 입력하면 이름을 지우는 것으로 본다 (서버가 null로 정규화)
                let trimmed = state.trimmedSpaceName
                let newName: String? = trimmed.isEmpty ? nil : trimmed

                state.isLoading = true
                return .run { [spaceId, newName] send in
                    @Dependency(\.settingsUseCase) var settingsUseCase
                    do {
                        try await settingsUseCase.renameSpace(spaceId: spaceId, name: newName)
                        await send(.spaceRenameResponse(.success(newName)))
                    } catch {
                        let domainError = error as? DomainError
                            ?? .unknown(code: "ERROR", message: error.localizedDescription)
                        await send(.spaceRenameResponse(.failure(domainError)))
                    }
                }

            case .spaceRenameResponse(.success(let newName)):
                state.showSpaceNameSheet = false
                state.spaceNameInput = ""
                state.isLoading = false
                state.error = nil
                // 홈도 새 이름을 보여야 하므로 부모(AppFeature)에게 알린다
                return .send(.delegate(.spaceRenamed(newName)))

            case .spaceRenameResponse(.failure(let error)):
                state.isLoading = false
                state.error = error
                return .none

            case .disconnectTapped:
                state.showDisconnectConfirm = true
                return .none

            case .confirmDisconnect:
                guard let spaceId = state.currentSpace?.id else {
                    state.error = .unknown(code: "ERROR", message: "스페이스를 찾을 수 없어요.")
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
