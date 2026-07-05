import Foundation
import ComposableArchitecture
import Domain
import Networking

public struct ComposeFeature {
    public struct State: Equatable {
        public var selectedImage: Data? = nil
        public var imageFileName: String = ""
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

        case presignResponse(Result<PresignResponse, DomainError>)
        case createResponse(Result<Moment, DomainError>)
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

                if let image = state.selectedImage {
                    return .run { [image] send in
                        @Dependency(\.momentRepository) var momentRepository
                        do {
                            let presign = try await momentRepository.presign()
                            await send(.presignResponse(.success(presign)))
                        } catch {
                            let domainError = error as? DomainError ?? .unknown(code: "ERROR", message: error.localizedDescription)
                            await send(.presignResponse(.failure(domainError)))
                        }
                    }
                } else {
                    return .run { [spaceId, text = state.text] send in
                        @Dependency(\.momentRepository) var momentRepository
                        do {
                            let moment = try await momentRepository.create(
                                spaceId: spaceId,
                                imageKey: nil,
                                text: text.isEmpty ? nil : text
                            )
                            await send(.createResponse(.success(moment)))
                        } catch {
                            let domainError = error as? DomainError ?? .unknown(code: "ERROR", message: error.localizedDescription)
                            await send(.createResponse(.failure(domainError)))
                        }
                    }
                }

            case .cancelTapped:
                return .send(.delegate(.dismissed))

            case .dismissError:
                state.error = nil
                return .none

            case .presignResponse(.success(let presignResponse)):
                guard let imageData = state.selectedImage else {
                    state.isUploading = false
                    state.error = .unknown(code: "ERROR", message: "이미지를 찾을 수 없습니다.")
                    return .none
                }

                state.imageFileName = presignResponse.imageKey

                return .run { [imageData, presignResponse, spaceId = state.selectedSpaceId ?? UUID(), text = state.text] send in
                    @Dependency(\.momentRepository) var momentRepository
                    do {
                        let uploadUrl = URL(string: presignResponse.uploadUrl)
                        guard let uploadUrl = uploadUrl else {
                            throw DomainError.unknown(code: "ERROR", message: "Invalid presign URL")
                        }

                        var request = URLRequest(url: uploadUrl)
                        request.httpMethod = "PUT"
                        request.setValue("image/jpeg", forHTTPHeaderField: "Content-Type")
                        request.httpBody = imageData

                        let (_, response) = try await URLSession.shared.data(for: request)

                        guard let httpResponse = response as? HTTPURLResponse,
                              (200...299).contains(httpResponse.statusCode) else {
                            throw DomainError.unknown(code: "ERROR", message: "이미지 업로드 실패")
                        }

                        let moment = try await momentRepository.create(
                            spaceId: spaceId,
                            imageKey: presignResponse.imageKey,
                            text: text.isEmpty ? nil : text
                        )
                        await send(.createResponse(.success(moment)))
                    } catch {
                        if let domainError = error as? DomainError {
                            await send(.createResponse(.failure(domainError)))
                        } else {
                            await send(.createResponse(.failure(.unknown(code: "ERROR", message: error.localizedDescription))))
                        }
                    }
                }

            case .presignResponse(.failure(let error)):
                state.isUploading = false
                state.error = error
                return .none

            case .createResponse(.success(let moment)):
                state.isUploading = false
                state.selectedImage = nil
                state.text = ""
                state.error = nil
                return .send(.delegate(.shared(moment)))

            case .createResponse(.failure(let error)):
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
