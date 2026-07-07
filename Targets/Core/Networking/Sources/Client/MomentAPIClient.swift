import Foundation
import Alamofire
import Domain

public final class MomentAPIClient: APIClientProtocol {
    private let session: Session
    private let baseURL: URL
    private let decoder: JSONDecoder

    public init(
        baseURL: URL = URL(string: "http://localhost:8080")!,
        tokenStore: TokenStoreProtocol
    ) {
        self.baseURL = baseURL

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)

            if let date = Self.iso8601Formatter.date(from: dateString) {
                return date
            }
            // 서버 Instant는 소수점 초가 없을 수도 있다 (예: "2026-07-07T00:00:00Z")
            if let date = Self.iso8601PlainFormatter.date(from: dateString) {
                return date
            }
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Invalid date format: \(dateString)"
            )
        }
        self.decoder = decoder

        let interceptor = AuthRequestInterceptor(tokenStore: tokenStore)
        self.session = Session(interceptor: interceptor)
    }

    public func request<T: Decodable & Sendable>(_ endpoint: Endpoint) async throws -> T {
        let url = buildURL(for: endpoint)
        let request = try buildRequest(endpoint: endpoint, url: url)

        return try await withCheckedThrowingContinuation { continuation in
            // .validate()를 쓰지 않는다 — 서버가 4xx에도 에러 엔벨로프를 담아 보내므로
            // 상태코드 대신 envelope.success/error로 판정해야 서버 에러 메시지가 보존된다.
            session.request(request)
                .responseDecodable(of: ApiEnvelope<T>.self, decoder: decoder) { response in
                    switch response.result {
                    case .success(let envelope):
                        if envelope.success, let data = envelope.data {
                            continuation.resume(returning: data)
                        } else if let error = envelope.error {
                            continuation.resume(throwing: self.mapError(code: error.code, message: error.message))
                        } else {
                            continuation.resume(throwing: DomainError.unknown(code: "INVALID_RESPONSE", message: "No data in response"))
                        }
                    case .failure(let error):
                        continuation.resume(throwing: self.mapNetworkError(error))
                    }
                }
        }
    }

    public func requestOptional<T: Decodable & Sendable>(_ endpoint: Endpoint) async throws -> T? {
        let url = buildURL(for: endpoint)
        let request = try buildRequest(endpoint: endpoint, url: url)

        return try await withCheckedThrowingContinuation { continuation in
            session.request(request)
                .responseDecodable(of: ApiEnvelope<T>.self, decoder: decoder) { response in
                    switch response.result {
                    case .success(let envelope):
                        if envelope.success {
                            continuation.resume(returning: envelope.data)
                        } else if let error = envelope.error {
                            continuation.resume(throwing: self.mapError(code: error.code, message: error.message))
                        } else {
                            continuation.resume(throwing: DomainError.unknown(code: "INVALID_RESPONSE", message: "Invalid response"))
                        }
                    case .failure(let error):
                        continuation.resume(throwing: self.mapNetworkError(error))
                    }
                }
        }
    }

    public func requestWithMeta<T: Decodable & Sendable>(_ endpoint: Endpoint) async throws -> (data: T, meta: ApiMeta?) {
        let url = buildURL(for: endpoint)
        let request = try buildRequest(endpoint: endpoint, url: url)

        return try await withCheckedThrowingContinuation { continuation in
            session.request(request)
                .responseDecodable(of: ApiEnvelope<T>.self, decoder: decoder) { response in
                    switch response.result {
                    case .success(let envelope):
                        if envelope.success, let data = envelope.data {
                            continuation.resume(returning: (data: data, meta: envelope.meta))
                        } else if let error = envelope.error {
                            continuation.resume(throwing: self.mapError(code: error.code, message: error.message))
                        } else {
                            continuation.resume(throwing: DomainError.unknown(code: "INVALID_RESPONSE", message: "No data in response"))
                        }
                    case .failure(let error):
                        continuation.resume(throwing: self.mapNetworkError(error))
                    }
                }
        }
    }

    public func requestVoid(_ endpoint: Endpoint) async throws {
        let url = buildURL(for: endpoint)
        let request = try buildRequest(endpoint: endpoint, url: url)

        return try await withCheckedThrowingContinuation { continuation in
            // .validate()를 쓰지 않는다 — 서버가 4xx에도 에러 엔벨로프를 담아 보내므로
            // 상태코드 대신 envelope.success/error로 판정해야 서버 에러 메시지가 보존된다.
            session.request(request)
                .responseDecodable(of: ApiEnvelope<EmptyResponse>.self, decoder: decoder) { response in
                    switch response.result {
                    case .success(let envelope):
                        if envelope.success {
                            continuation.resume()
                        } else if let error = envelope.error {
                            continuation.resume(throwing: self.mapError(code: error.code, message: error.message))
                        } else {
                            continuation.resume(throwing: DomainError.unknown(code: "INVALID_RESPONSE", message: "Invalid response"))
                        }
                    case .failure(let error):
                        continuation.resume(throwing: self.mapNetworkError(error))
                    }
                }
        }
    }

    private func buildURL(for endpoint: Endpoint) -> URL {
        var components = URLComponents(url: baseURL.appendingPathComponent(endpoint.path), resolvingAgainstBaseURL: true)!
        if !endpoint.query.isEmpty {
            components.queryItems = endpoint.query
        }
        return components.url!
    }

    private func buildRequest(endpoint: Endpoint, url: URL) throws -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        if let body = endpoint.body {
            request.httpBody = try JSONEncoder().encode(AnyEncodable(body))
        }

        return request
    }

    private func mapError(code: String, message: String) -> DomainError {
        switch code {
        case "UNAUTHORIZED", "INVALID_TOKEN":
            return .unauthorized
        case "NOT_FOUND":
            return .notFound
        case "CONFLICT":
            return .conflict
        case "TOO_MANY_REQUESTS":
            return .tooManyRequests
        default:
            return .unknown(code: code, message: message)
        }
    }

    private func mapNetworkError(_ error: AFError) -> DomainError {
        return .network(underlying: error)
    }

    private static let iso8601Formatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    private static let iso8601PlainFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()
}

// MARK: - Helper Types

private struct EmptyResponse: Decodable {}

private struct AnyEncodable: Encodable {
    private let encodable: any Encodable

    init(_ encodable: any Encodable) {
        self.encodable = encodable
    }

    func encode(to encoder: Encoder) throws {
        try encodable.encode(to: encoder)
    }
}
