import Foundation

public enum DomainError: LocalizedError, Sendable {
    case unauthorized
    case notFound
    case conflict
    case tooManyRequests
    case network(underlying: Error)
    case unknown(code: String, message: String)

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
