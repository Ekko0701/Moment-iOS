import Foundation

public struct Endpoint: Sendable {
    public enum HTTPMethod: String, Sendable {
        case get = "GET"
        case post = "POST"
        case put = "PUT"
        case patch = "PATCH"
        case delete = "DELETE"
    }

    public let path: String
    public let method: HTTPMethod
    public let query: [URLQueryItem]
    public let body: (any Encodable & Sendable)?
    public let requiresAuth: Bool

    public init(
        path: String,
        method: HTTPMethod = .get,
        query: [URLQueryItem] = [],
        body: (any Encodable & Sendable)? = nil,
        requiresAuth: Bool = true
    ) {
        self.path = path
        self.method = method
        self.query = query
        self.body = body
        self.requiresAuth = requiresAuth
    }
}

// MARK: - Auth Endpoints

public enum AuthEndpoints {
    static func loginWithApple(identityToken: String, nickname: String?) -> Endpoint {
        let body = LoginAppleRequest(identityToken: identityToken, nickname: nickname)
        return Endpoint(
            path: "/v1/auth/apple",
            method: .post,
            body: body,
            requiresAuth: false
        )
    }

    static func refresh(refreshToken: String) -> Endpoint {
        let body = RefreshTokenRequest(refreshToken: refreshToken)
        return Endpoint(
            path: "/v1/auth/refresh",
            method: .post,
            body: body,
            requiresAuth: false
        )
    }
}

// MARK: - User Endpoints

public enum UserEndpoints {
    static func search(handle: String) -> Endpoint {
        return Endpoint(
            path: "/v1/users/search",
            method: .get,
            query: [URLQueryItem(name: "handle", value: handle)],
            requiresAuth: true
        )
    }

    static func getProfile() -> Endpoint {
        return Endpoint(
            path: "/v1/users/me",
            method: .get,
            requiresAuth: true
        )
    }

    static func updateProfile(nickname: String?, profileImageUrl: String?) -> Endpoint {
        return Endpoint(
            path: "/v1/users/me",
            method: .patch,
            body: UserUpdateRequest(nickname: nickname, profileImageUrl: profileImageUrl),
            requiresAuth: true
        )
    }
}

// MARK: - Space Endpoints

public enum SpaceEndpoints {
    static func getActiveSpace() -> Endpoint {
        return Endpoint(
            path: "/v1/spaces/me",
            method: .get,
            requiresAuth: true
        )
    }
}

// MARK: - Invitation Endpoints

public enum InvitationEndpoints {
    static func createInvitation(handle: String) -> Endpoint {
        let body = CreateInvitationRequest(handle: handle)
        return Endpoint(
            path: "/v1/invitations",
            method: .post,
            body: body,
            requiresAuth: true
        )
    }

    static func listInvitations() -> Endpoint {
        return Endpoint(
            path: "/v1/invitations",
            method: .get,
            requiresAuth: true
        )
    }

    static func updateInvitation(invitationId: String, status: String) -> Endpoint {
        let body = UpdateInvitationRequest(status: status)
        return Endpoint(
            path: "/v1/invitations/\(invitationId)",
            method: .patch,
            body: body,
            requiresAuth: true
        )
    }
}

// MARK: - Moment Endpoints

public enum MomentEndpoints {
    static func listMoments(spaceId: String, limit: Int = 20, cursor: String?) -> Endpoint {
        var query: [URLQueryItem] = [
            URLQueryItem(name: "spaceId", value: spaceId),
            URLQueryItem(name: "limit", value: String(limit))
        ]
        if let cursor = cursor {
            query.append(URLQueryItem(name: "cursor", value: cursor))
        }
        return Endpoint(
            path: "/v1/moments",
            method: .get,
            query: query,
            requiresAuth: true
        )
    }

    static func createMoment(spaceId: String, imageUrl: String?, text: String?) -> Endpoint {
        let body = CreateMomentRequest(spaceId: spaceId, imageUrl: imageUrl, text: text)
        return Endpoint(
            path: "/v1/moments",
            method: .post,
            body: body,
            requiresAuth: true
        )
    }

    static func deleteMoment(momentId: String) -> Endpoint {
        return Endpoint(
            path: "/v1/moments/\(momentId)",
            method: .delete,
            requiresAuth: true
        )
    }
}

// MARK: - Reaction Endpoints

public enum ReactionEndpoints {
    static func addReaction(momentId: String, emoji: String) -> Endpoint {
        let body = AddReactionRequest(emoji: emoji)
        return Endpoint(
            path: "/v1/moments/\(momentId)/reactions",
            method: .post,
            body: body,
            requiresAuth: true
        )
    }

    static func updateReaction(momentId: String, emoji: String) -> Endpoint {
        let body = UpdateReactionRequest(emoji: emoji)
        return Endpoint(
            path: "/v1/moments/\(momentId)/reactions",
            method: .patch,
            body: body,
            requiresAuth: true
        )
    }
}

// MARK: - Request Bodies

struct LoginAppleRequest: Encodable, Sendable {
    let identityToken: String
    let nickname: String?
}

struct RefreshTokenRequest: Encodable, Sendable {
    let refreshToken: String
}

struct UserUpdateRequest: Encodable, Sendable {
    let nickname: String?
    let profileImageUrl: String?

    enum CodingKeys: String, CodingKey {
        case nickname
        case profileImageUrl
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        if let nickname = nickname {
            try container.encode(nickname, forKey: .nickname)
        }
        if let profileImageUrl = profileImageUrl {
            try container.encode(profileImageUrl, forKey: .profileImageUrl)
        }
    }
}

struct CreateInvitationRequest: Encodable, Sendable {
    let handle: String
}

struct UpdateInvitationRequest: Encodable, Sendable {
    let status: String
}

struct CreateMomentRequest: Encodable, Sendable {
    let spaceId: String
    let imageUrl: String?
    let text: String?

    enum CodingKeys: String, CodingKey {
        case spaceId
        case imageUrl
        case text
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(spaceId, forKey: .spaceId)
        if let imageUrl = imageUrl {
            try container.encode(imageUrl, forKey: .imageUrl)
        }
        if let text = text {
            try container.encode(text, forKey: .text)
        }
    }
}

struct AddReactionRequest: Encodable, Sendable {
    let emoji: String
}

struct UpdateReactionRequest: Encodable, Sendable {
    let emoji: String
}
