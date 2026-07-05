import Foundation

public struct ApiEnvelope<T: Decodable>: Decodable {
    public let success: Bool
    public let data: T?
    public let error: ApiError?
    public let meta: ApiMeta?

    enum CodingKeys: String, CodingKey {
        case success
        case data
        case error
        case meta
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.success = try container.decode(Bool.self, forKey: .success)
        self.data = try container.decodeIfPresent(T.self, forKey: .data)
        self.error = try container.decodeIfPresent(ApiError.self, forKey: .error)
        self.meta = try container.decodeIfPresent(ApiMeta.self, forKey: .meta)
    }
}

public struct ApiError: Decodable, Sendable {
    public let code: String
    public let message: String

    public init(code: String, message: String) {
        self.code = code
        self.message = message
    }
}

public struct ApiMeta: Decodable, Sendable {
    public let total: Int?
    public let page: Int?
    public let limit: Int?

    public init(total: Int? = nil, page: Int? = nil, limit: Int? = nil) {
        self.total = total
        self.page = page
        self.limit = limit
    }
}
