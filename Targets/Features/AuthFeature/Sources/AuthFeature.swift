import Foundation
import ComposableArchitecture
import Domain
import Networking

public struct AuthFeature {
    public struct State: Equatable {
        public var isLoading = false
        public var error: DomainError? = nil

        public init() {}
    }

    public enum Action {
        case appleSignInTapped
        case appleSignInCompleted(identityToken: String)
        case loginResponse(Result<(TokenPair, Bool), DomainError>)
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
                    @Dependency(\.authRepository) var authRepository
                    do {
                        // Generate a default nickname if not provided
                        let defaultNickname = "User\(Int.random(in: 1000...9999))"
                        let result = try await authRepository.loginWithApple(identityToken: token, nickname: defaultNickname)
                        await send(.loginResponse(.success(result)))
                    } catch {
                        let domainError = error as? DomainError ?? .unknown(code: "ERROR", message: error.localizedDescription)
                        await send(.loginResponse(.failure(domainError)))
                    }
                }

            case .loginResponse(.success(let isNewUser)):
                state.isLoading = false
                state.error = nil
                return .send(.delegate(.loggedIn(isNewUser: isNewUser.1)))

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
