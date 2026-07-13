import Foundation
import Alamofire

/// 모든 요청에 Bearer 액세스 토큰을 부착하고, 401 응답 시 리프레시 토큰으로
/// 토큰을 1회 갱신한 뒤 원 요청을 재시도한다.
/// 리프레시 호출은 인터셉터 재귀를 피하기 위해 URLSession을 직접 사용한다.
final class AuthRequestInterceptor: RequestInterceptor, @unchecked Sendable {
    private let tokenStore: TokenStoreProtocol
    private let baseURL: URL

    init(tokenStore: TokenStoreProtocol, baseURL: URL) {
        self.tokenStore = tokenStore
        self.baseURL = baseURL
    }

    nonisolated func adapt(_ urlRequest: URLRequest, for session: Session, completion: @escaping (Result<URLRequest, Error>) -> Void) {
        Task {
            var request = urlRequest
            if let token = await tokenStore.getAccessToken() {
                request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            }
            completion(.success(request))
        }
    }

    nonisolated func retry(_ request: Request, for session: Session, dueTo error: Error, completion: @escaping (RetryResult) -> Void) {
        // 401 이외, 또는 이미 재시도한 요청은 그대로 실패시킨다 (무한 재시도 방지)
        guard request.response?.statusCode == 401, request.retryCount == 0 else {
            completion(.doNotRetry)
            return
        }
        // 로그인/리프레시 등 인증 엔드포인트 자체의 401은 자격 증명 문제이므로 재시도하지 않는다
        if let path = request.request?.url?.path, path.hasPrefix("/v1/auth/") {
            completion(.doNotRetry)
            return
        }

        Task {
            guard let refreshToken = await tokenStore.getRefreshToken() else {
                completion(.doNotRetry)
                return
            }
            do {
                let pair = try await Self.requestRefresh(refreshToken: refreshToken, baseURL: baseURL)
                try await tokenStore.setAccessToken(pair.accessToken)
                try await tokenStore.setRefreshToken(pair.refreshToken)
                completion(.retry)
            } catch {
                // 리프레시 실패 = 세션 만료. 토큰을 비워 다음 시작 시 로그인 화면으로 가게 한다.
                try? await tokenStore.deleteTokens()
                completion(.doNotRetry)
            }
        }
    }

    private struct RefreshEnvelope: Decodable {
        let success: Bool
        let data: RefreshTokens?
    }

    private struct RefreshTokens: Decodable {
        let accessToken: String
        let refreshToken: String
    }

    private static func requestRefresh(refreshToken: String, baseURL: URL) async throws -> RefreshTokens {
        var request = URLRequest(url: baseURL.appendingPathComponent("/v1/auth/refresh"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(["refreshToken": refreshToken])

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw URLError(.userAuthenticationRequired)
        }
        let envelope = try JSONDecoder().decode(RefreshEnvelope.self, from: data)
        guard envelope.success, let tokens = envelope.data else {
            throw URLError(.userAuthenticationRequired)
        }
        return tokens
    }
}
