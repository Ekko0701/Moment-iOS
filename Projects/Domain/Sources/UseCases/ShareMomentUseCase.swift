import Dependencies
import Foundation

/// 모먼트 공유 유스케이스 — presign → 업로드 → 생성의 3단계 오케스트레이션을 소유한다.
/// 화면(리듀서)은 이 단계를 알 필요가 없다.
public struct ShareMomentUseCase: Sendable {
    @Dependency(\.momentRepository) private var momentRepository

    public init() {}

    public func execute(spaceId: UUID, text: String, imageData: Data?) async throws -> Moment {
        var imageKey: String? = nil

        if let imageData {
            let presign = try await momentRepository.presign()
            try await upload(imageData, to: presign.uploadUrl)
            imageKey = presign.imageKey
        }

        return try await momentRepository.create(
            spaceId: spaceId,
            imageKey: imageKey,
            text: text.isEmpty ? nil : text
        )
    }

    private func upload(_ data: Data, to urlString: String) async throws {
        guard let url = URL(string: urlString) else {
            throw DomainError.unknown(code: "INVALID_PRESIGN", message: "업로드 주소가 올바르지 않아요.")
        }
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("image/jpeg", forHTTPHeaderField: "Content-Type")
        request.httpBody = data

        let (_, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw DomainError.unknown(code: "UPLOAD_FAILED", message: "사진 업로드에 실패했어요.")
        }
    }
}

public extension DependencyValues {
    var shareMomentUseCase: ShareMomentUseCase {
        get { self[ShareMomentUseCaseKey.self] }
        set { self[ShareMomentUseCaseKey.self] = newValue }
    }
}

private enum ShareMomentUseCaseKey: DependencyKey {
    static let liveValue = ShareMomentUseCase()
}
