import Dependencies
import Foundation

/// 모먼트 공유 유스케이스 — presign → 업로드 → 생성의 3단계 오케스트레이션을 소유한다.
/// 화면(리듀서)은 이 단계를 알 필요가 없다.
public struct ShareMomentUseCase: Sendable {
    @Dependency(\.momentRepository) private var momentRepository

    public init() {}

    /// textStyle은 사진 위에 글씨를 올릴 때의 위치·색. 사진이나 글이 없으면 보내지 않는다
    public func execute(
        spaceId: UUID,
        text: String,
        imageData: Data?,
        textStyle: MomentTextStyle = .standard
    ) async throws -> Moment {
        var imageKey: String? = nil

        if let imageData {
            let presign = try await momentRepository.presign()
            try await upload(imageData, to: presign.uploadUrl)
            imageKey = presign.imageKey
        }

        return try await momentRepository.create(
            spaceId: spaceId,
            imageKey: imageKey,
            text: text.isEmpty ? nil : text,
            textStyle: imageKey != nil && !text.isEmpty ? textStyle : nil
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

        let response: URLResponse
        do {
            (_, response) = try await URLSession.shared.data(for: request)
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            // 연결 실패·시간 초과는 시스템 문구 대신 앱의 말투로 알린다
            throw DomainError.unknown(
                code: "UPLOAD_FAILED",
                message: "사진을 올리지 못했어요. 네트워크를 확인하고 다시 시도해 주세요.")
        }
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
