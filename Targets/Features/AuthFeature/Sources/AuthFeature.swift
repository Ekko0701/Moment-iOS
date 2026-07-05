import Foundation
import ComposableArchitecture
import Domain

struct AuthFeature {
    struct State: Equatable {
        var isLoading = false
        var error: DomainError? = nil
        
        init() {}
    }
    
    enum Action {
        case appleSignInTapped
        case appleSignInCompleted(identityToken: String)
        case loginResponse(Result<(TokenPair, Bool), DomainError>)
        case dismissError
    }
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .appleSignInTapped:
                state.isLoading = true
                return .none
                
            case .appleSignInCompleted(let token):
                state.isLoading = true
                return .none
                
            case .loginResponse(.success):
                state.isLoading = false
                state.error = nil
                return .none
                
            case .loginResponse(.failure(let error)):
                state.isLoading = false
                state.error = error
                return .none
                
            case .dismissError:
                state.error = nil
                return .none
            }
        }
    }
    
    init() {}
}

extension AuthFeature: Reducer {}
