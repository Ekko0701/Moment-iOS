import Foundation
import ComposableArchitecture
import Domain
import Dependencies

/// 그룹 만들기 — 이름 입력 → 생성 → 초대 코드 공유 → 완료.
public struct GroupCreateFeature {
    public static let nameMaxLength = 10

    public struct State: Equatable {
        public var name: String = ""
        public var isSubmitting = false
        public var error: DomainError? = nil
        /// 생성이 끝나면 채워진다. 화면은 이 값이 있으면 코드 공유 단계를 보여준다
        public var created: CreatedGroup? = nil

        public init() {}

        public var trimmedName: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }
        public var canSubmit: Bool { !trimmedName.isEmpty && !isSubmitting && created == nil }
    }

    public enum Action {
        case nameChanged(String)
        case submitTapped
        case createResponse(Result<CreatedGroup, DomainError>)
        case doneTapped
        case cancelTapped
        case dismissError
        case delegate(Delegate)

        public enum Delegate: Equatable {
            case created(Space)
            case cancelled
        }
    }

    public var body: some ReducerOf<Self> {
        Reduce<State, Action> { state, action in
            switch action {
            case .nameChanged(let name):
                state.name = String(name.prefix(Self.nameMaxLength))
                return .none

            case .submitTapped:
                guard state.canSubmit else { return .none }
                state.isSubmitting = true
                state.error = nil
                return .run { [name = state.trimmedName] send in
                    @Dependency(\.groupUseCase) var groupUseCase
                    do {
                        await send(.createResponse(.success(try await groupUseCase.create(name: name))))
                    } catch {
                        await send(.createResponse(.failure(error.asDomainError)))
                    }
                }

            case .createResponse(.success(let created)):
                state.isSubmitting = false
                state.created = created
                return .none

            case .createResponse(.failure(let error)):
                state.isSubmitting = false
                state.error = error
                return .none

            case .doneTapped:
                guard let created = state.created else { return .send(.delegate(.cancelled)) }
                return .send(.delegate(.created(created.space)))

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

extension GroupCreateFeature: Reducer {}

extension Error {
    var asDomainError: DomainError {
        self as? DomainError ?? .unknown(code: "ERROR", message: localizedDescription)
    }
}
