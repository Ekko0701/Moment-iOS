import Foundation
import ComposableArchitecture
import Domain

struct ConnectFeature {
    struct State: Equatable {
        var selectedTab: Tab = .code
        var isLoading = false
        var error: DomainError? = nil
        var codeInput: String = ""
        var searchHandle: String = ""
        
        enum Tab {
            case code
            case search
        }
        
        init() {}
    }
    
    enum Action {
        case tabSelected(State.Tab)
        case codeInputChanged(String)
        case searchHandleChanged(String)
        case generateCodeTapped
        case searchTapped
        case dismissError
    }
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .tabSelected(let tab):
                state.selectedTab = tab
                return .none
                
            case .codeInputChanged(let input):
                state.codeInput = input
                return .none
                
            case .searchHandleChanged(let input):
                state.searchHandle = input
                return .none
                
            case .generateCodeTapped:
                state.isLoading = true
                return .none
                
            case .searchTapped:
                state.isLoading = true
                return .none
                
            case .dismissError:
                state.error = nil
                return .none
            }
        }
    }
    
    init() {}
}

extension ConnectFeature: Reducer {}
