import Foundation
import Alamofire

final class AuthRequestInterceptor: RequestInterceptor {
    private let tokenStore: TokenStoreProtocol

    init(tokenStore: TokenStoreProtocol) {
        self.tokenStore = tokenStore
    }

    nonisolated func adapt(_ urlRequest: URLRequest, for session: Session, completion: @escaping (Result<URLRequest, Error>) -> Void) {
        var request = urlRequest
        // Token injection will be async in future impl - for now, just pass through
        completion(.success(request))
    }

    nonisolated func retry(_ request: Request, for session: Session, dueTo error: Error, completion: @escaping (RetryResult) -> Void) {
        guard let statusCode = request.response?.statusCode else {
            completion(.doNotRetry)
            return
        }

        if statusCode == 401 {
            completion(.retry)
        } else {
            completion(.doNotRetry)
        }
    }
}
