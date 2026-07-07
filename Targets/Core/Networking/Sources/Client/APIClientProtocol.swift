import Foundation
import Domain

public protocol APIClientProtocol: Sendable {
    func request<T: Decodable & Sendable>(_ endpoint: Endpoint) async throws -> T
    /// data가 null일 수 있는 응답 (예: 위젯용 latest — 모먼트 없음)
    func requestOptional<T: Decodable & Sendable>(_ endpoint: Endpoint) async throws -> T?
    /// 페이지네이션 등 meta가 필요한 응답
    func requestWithMeta<T: Decodable & Sendable>(_ endpoint: Endpoint) async throws -> (data: T, meta: ApiMeta?)
    func requestVoid(_ endpoint: Endpoint) async throws
}
