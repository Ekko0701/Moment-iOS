import Foundation
import SwiftUI
import UIKit
import ComposableArchitecture
import CoreKit
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
        public var isProcessingPhoto = false
        public var error: DomainError? = nil

        public var characterCount: Int { text.count }
        public var maxCharacters = 500
        // 서버 계약: 사진 또는 글 중 최소 1개 (F-04-01)
        public var canSubmit: Bool {
            (selectedImage != nil || !text.isEmpty) && !isUploading && !isProcessingPhoto
        }

        public init() {}
    }

    public enum Action {
        case photoPicked(Data?)
        case imageSelected(Data)
        case photoProcessingFailed
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
            case .photoPicked(let rawData):
                guard let rawData, !rawData.isEmpty else {
                    state.error = .unknown(
                        code: "PHOTO_LOAD_FAILED",
                        message: "사진을 불러오지 못했어요. 다른 사진을 선택해 주세요.")
                    return .none
                }
                state.isProcessingPhoto = true
                state.error = nil
                return .run { send in
                    // 디코드·리사이즈(2048px)·JPEG 인코딩은 CPU 작업 — 메인 액터 밖에서 수행.
                    // EXIF 제거는 resizedAndCompressed가 담당한다.
                    let compressed = await Task.detached(priority: .userInitiated) {
                        UIImage(data: rawData)?.resizedAndCompressed()
                    }.value
                    if let compressed {
                        await send(.imageSelected(compressed))
                    } else {
                        await send(.photoProcessingFailed)
                    }
                }

            case .imageSelected(let data):
                state.isProcessingPhoto = false
                state.selectedImage = data
                state.error = nil
                return .none

            case .photoProcessingFailed:
                state.isProcessingPhoto = false
                state.error = .unknown(
                    code: "PHOTO_PROCESS_FAILED",
                    message: "사진을 처리하지 못했어요. 다른 사진을 선택해 주세요.")
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
