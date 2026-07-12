import Foundation

public enum DomainError: LocalizedError, Sendable, Equatable {
    case unauthorized
    case notFound(message: String)
    case conflict(message: String)
    case tooManyRequests(message: String)
    case network(underlying: Error)
    case unknown(code: String, message: String)

    // network의 underlying Error는 Equatable이 아니므로 케이스 단위로만 비교한다.
    public static func == (lhs: DomainError, rhs: DomainError) -> Bool {
        switch (lhs, rhs) {
        case (.unauthorized, .unauthorized),
             (.network, .network):
            return true
        case let (.notFound(l), .notFound(r)),
             let (.conflict(l), .conflict(r)),
             let (.tooManyRequests(l), .tooManyRequests(r)):
            return l == r
        case let (.unknown(lhsCode, lhsMessage), .unknown(rhsCode, rhsMessage)):
            return lhsCode == rhsCode && lhsMessage == rhsMessage
        default:
            return false
        }
    }

    // 서버가 이미 사용자용 한국어 메시지를 내려주므로 그대로 노출한다.
    public var errorDescription: String? {
        switch self {
        case .unauthorized:
            return "로그인이 필요해요. 다시 로그인해 주세요."
        case .notFound(let message),
             .conflict(let message),
             .tooManyRequests(let message):
            return message
        case .network:
            return "네트워크 연결을 확인해 주세요."
        case .unknown(_, let message):
            return message
        }
    }
}
