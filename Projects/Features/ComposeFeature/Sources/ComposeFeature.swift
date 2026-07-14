import Foundation
import SwiftUI
import ComposableArchitecture
import Domain
import Dependencies
import MomentUIKit

public struct ComposeFeature {
    @Dependency(\.shareMomentUseCase) var shareMomentUseCase

    public struct State: Equatable {
        public var selectedImage: Data? = nil
        public var text: String = ""
        public var selectedSpaceId: UUID? = nil
        public var isUploading = false
        public var error: DomainError? = nil

        public var characterCount: Int { text.count }
        public var maxCharacters = 500
        public var canSubmit: Bool {
            (selectedImage != nil || !text.isEmpty) && !text.isEmpty && !isUploading
        }

        public init() {}
    }

    public enum Action {
        case imageSelected(Data)
        case textChanged(String)
        case clearImage
        case submitTapped
        case cancelTapped
        case dismissError

        case submitResponse(Result<Moment, DomainError>)
        case delegate(Delegate)

        public enum Delegate: Equatable {
            case shared(Moment)
            case dismissed
        }
    }

    public var body: some ReducerOf<Self> {
        Reduce<State, Action> { state, action in
            switch action {
            case .imageSelected(let data):
                state.selectedImage = data
                state.error = nil
                return .none

            case .textChanged(let newText):
                if newText.count <= state.maxCharacters {
                    state.text = newText
                }
                return .none

            case .clearImage:
                state.selectedImage = nil
                return .none

            case .submitTapped:
                guard let spaceId = state.selectedSpaceId else {
                    state.error = .unknown(code: "NO_SPACE", message: "스페이스를 찾을 수 없습니다.")
                    return .none
                }

                state.isUploading = true

                return .run { [useCase = self.shareMomentUseCase, spaceId, text = state.text, imageData = state.selectedImage] send in
                    do {
                        let moment = try await useCase.execute(
                            spaceId: spaceId,
                            text: text,
                            imageData: imageData
                        )
                        await send(.submitResponse(.success(moment)))
                    } catch {
                        let domainError = error as? DomainError ?? .unknown(code: "ERROR", message: error.localizedDescription)
                        await send(.submitResponse(.failure(domainError)))
                    }
                }

            case .cancelTapped:
                return .send(.delegate(.dismissed))

            case .dismissError:
                state.error = nil
                return .none

            case .submitResponse(.success(let moment)):
                state.isUploading = false
                state.selectedImage = nil
                state.text = ""
                state.error = nil
                return .send(.delegate(.shared(moment)))

            case .submitResponse(.failure(let error)):
                state.isUploading = false
                state.error = error
                return .none

            case .delegate:
                return .none
            }
        }
    }

    public init() {}
}

extension ComposeFeature: Reducer {}

public typealias ComposeFeatureReducer = ComposeFeature
