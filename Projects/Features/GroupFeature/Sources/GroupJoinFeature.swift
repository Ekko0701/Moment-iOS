import Foundation
import ComposableArchitecture
import Domain
import Dependencies

/// 초대 코드로 그룹 참여. 코드는 6자리 영문 대문자·숫자다.
public struct GroupJoinFeature {
    public static let codeLength = 6

    public struct State: Equatable {
        public var code: String = ""
        public var isSubmitting = false
        public var error: DomainError? = nil

        public init() {}

        public var canSubmit: Bool { code.count == GroupJoinFeature.codeLength && !isSubmitting }
    }

    public enum Action {
        case codeChanged(String)
        case submitTapped
        case joinResponse(Result<Space, DomainError>)
        case cancelTapped
        case dismissError
        case delegate(Delegate)

        public enum Delegate: Equatable {
            case joined(Space)
            case cancelled
        }
    }

    public var body: some ReducerOf<Self> {
        Reduce<State, Action> { state, action in
            switch action {
            case .codeChanged(let raw):
                // 입력 중 공백·소문자·기호를 걸러 6자리 대문자 코드로 맞춘다
                let filtered = raw.uppercased().filter { $0.isASCII && ($0.isLetter || $0.isNumber) }
                state.code = String(filtered.prefix(GroupJoinFeature.codeLength))
                return .none

            case .submitTapped:
                guard state.canSubmit else { return .none }
                state.isSubmitting = true
                state.error = nil
                return .run { [code = state.code] send in
                    @Dependency(\.groupUseCase) var groupUseCase
                    do {
                        await send(.joinResponse(.success(try await groupUseCase.join(code: code))))
                    } catch {
                        await send(.joinResponse(.failure(error.asDomainError)))
                    }
                }

            case .joinResponse(.success(let space)):
                state.isSubmitting = false
                return .send(.delegate(.joined(space)))

            case .joinResponse(.failure(let error)):
                state.isSubmitting = false
                state.error = error
                return .none

            case .cancelTapped:
                return .send(.delegate(.cancelled))

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

extension GroupJoinFeature: Reducer {}
