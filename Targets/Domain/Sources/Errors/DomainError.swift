import Foundation

public enum DomainError: LocalizedError, Sendable, Equatable {
    case unauthorized
    case notFound
    case conflict
    case tooManyRequests
    case network(underlying: Error)
    case unknown(code: String, message: String)

    // network의 underlying Error는 Equatable이 아니므로 케이스 단위로만 비교한다.
    public static func == (lhs: DomainError, rhs: DomainError) -> Bool {
        switch (lhs, rhs) {
        case (.unauthorized, .unauthorized),
             (.notFound, .notFound),
             (.conflict, .conflict),
             (.tooManyRequests, .tooManyRequests),
             (.network, .network):
            return true
        case let (.unknown(lhsCode, lhsMessage), .unknown(rhsCode, rhsMessage)):
            return lhsCode == rhsCode && lhsMessage == rhsMessage
        default:
            return false
        }
    }

    public var errorDescription: String? {
        switch self {
        case .unauthorized:
            return "Unauthorized access"
        case .notFound:
            return "Resource not found"
        case .conflict:
            return "Request conflict"
        case .tooManyRequests:
            return "Too many requests"
        case .network(let error):
            return "Network error: \(error.localizedDescription)"
        case .unknown(_, let message):
            return message
        }
    }
}
