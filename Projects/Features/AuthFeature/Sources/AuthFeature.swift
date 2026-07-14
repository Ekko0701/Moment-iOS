import Foundation
import SwiftUI
import ComposableArchitecture
import Dependencies
import Domain
import MomentUIKit

public struct AuthFeature {
    /// 로그인 화면 모드: Apple 기본 → 이메일 로그인 ↔ 이메일 가입
    public enum Mode: Equatable {
        case apple
        case emailLogin
        case emailSignup
    }

    public struct State: Equatable {
        public var mode: Mode = .apple
        public var email: String = ""
        public var password: String = ""
        public var nickname: String = ""
        public var isLoading = false
        public var error: DomainError? = nil

        public init() {}

        /// 이메일 폼 제출 가능 여부 — 클라이언트 1차 검증(서버가 최종 검증).
        public var canSubmitEmail: Bool {
            guard email.contains("@"), password.count >= 8 else { return false }
            if mode == .emailSignup { return nickname.count >= 2 }
            return true
        }
    }

    public enum Action {
        case appleSignInTapped
        case appleSignInCompleted(identityToken: String)
        case modeChanged(Mode)
        case emailChanged(String)
        case passwordChanged(String)
        case nicknameChanged(String)
        case emailSubmitTapped
        case loginResponse(Result<Bool, DomainError>)
        case dismissError
        case delegate(Delegate)

        public enum Delegate: Equatable {
            case loggedIn(isNewUser: Bool)
        }
    }

    public var body: some ReducerOf<Self> {
        Reduce<State, Action> { state, action in
            switch action {
            case .appleSignInTapped:
                state.isLoading = true
                return .none

            case .appleSignInCompleted(let token):
                state.isLoading = true
                return .run { send in
                    @Dependency(\.authUseCase) var authUseCase
                    do {
                        let isNewUser = try await authUseCase.loginWithApple(identityToken: token)
                        await send(.loginResponse(.success(isNewUser)))
                    } catch {
                        let domainError = error as? DomainError ?? .unknown(code: "ERROR", message: error.localizedDescription)
                        await send(.loginResponse(.failure(domainError)))
                    }
                }

            case .modeChanged(let mode):
                state.mode = mode
                state.error = nil
                return .none

            case .emailChanged(let value):
                state.email = value
                return .none

            case .passwordChanged(let value):
                state.password = value
                return .none

            case .nicknameChanged(let value):
                state.nickname = value
                return .none

            case .emailSubmitTapped:
                guard state.canSubmitEmail, !state.isLoading else { return .none }
                state.isLoading = true
                let mode = state.mode
                let email = state.email.trimmingCharacters(in: .whitespaces)
                let password = state.password
                let nickname = state.nickname.trimmingCharacters(in: .whitespaces)
                return .run { send in
                    @Dependency(\.authUseCase) var authUseCase
                    do {
                        if mode == .emailSignup {
                            let isNewUser = try await authUseCase.signUpWithEmail(email: email, password: password, nickname: nickname)
                            await send(.loginResponse(.success(isNewUser)))
                        } else {
                            try await authUseCase.loginWithEmail(email: email, password: password)
                            await send(.loginResponse(.success(false)))
                        }
                    } catch {
                        let domainError = error as? DomainError ?? .unknown(code: "ERROR", message: error.localizedDescription)
                        await send(.loginResponse(.failure(domainError)))
                    }
                }

            case .loginResponse(.success(let isNewUser)):
                state.isLoading = false
                state.error = nil
                return .send(.delegate(.loggedIn(isNewUser: isNewUser)))

            case .loginResponse(.failure(let error)):
                state.isLoading = false
                state.error = error
                return .none

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

extension AuthFeature: Reducer {}

public typealias AuthFeatureReducer = AuthFeature
