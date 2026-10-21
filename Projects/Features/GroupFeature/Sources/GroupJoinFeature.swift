import Foundation
import ComposableArchitecture
import Domain
import Dependencies

/// 초대 코드로 그룹 참여를 요청한다. 코드는 6자리 영문 대문자·숫자이고, 방장이 수락해야 그룹에 들어간다.
public struct GroupJoinFeature {
    public static let codeLength = 6

    public struct State: Equatable {
        public var code: String = ""
        public var isSubmitting = false
        public var error: DomainError? = nil
        /// 보낸 요청. 있으면 시트가 "수락을 기다리는 중" 안내로 바뀐다
        public var sentRequest: GroupJoinRequest? = nil

        public init() {}

        public var canSubmit: Bool {
            code.count == GroupJoinFeature.codeLength && !isSubmitting && sentRequest == nil
        }
    }

    public enum Action {
        case codeChanged(String)
        case submitTapped
        case joinResponse(Result<GroupJoinRequest, DomainError>)
        case doneTapped
        case cancelTapped
        case dismissError
        case delegate(Delegate)

        public enum Delegate: Equatable {
            case requested(GroupJoinRequest)
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
                        await send(.joinResponse(.success(try await groupUseCase.requestJoin(code: code))))
                    } catch {
                        await send(.joinResponse(.failure(error.asDomainError)))
                    }
                }

            case .joinResponse(.success(let request)):
                state.isSubmitting = false
                state.sentRequest = request
                return .none

            case .joinResponse(.failure(let error)):
                state.isSubmitting = false
                state.error = error
                return .none

            case .doneTapped:
                guard let request = state.sentRequest else { return .none }
                return .send(.delegate(.requested(request)))

            case .cancelTapped:
                // 요청을 보내는 중에는 닫지 않는다. 결과가 버려지면 서버와 화면이 어긋난다
                guard !state.isSubmitting else { return .none }
                if let request = state.sentRequest {
                    return .send(.delegate(.requested(request)))
                }
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
