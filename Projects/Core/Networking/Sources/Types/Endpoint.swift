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

    // 서버 계약: POST /v1/auth/email/signup { email, password, nickname }
    static func emailSignup(email: String, password: String, nickname: String) -> Endpoint {
        return Endpoint(
            path: "/v1/auth/email/signup",
            method: .post,
            body: EmailSignupRequest(email: email, password: password, nickname: nickname),
            requiresAuth: false
        )
    }

    // 서버 계약: POST /v1/auth/email/login { email, password }
    static func emailLogin(email: String, password: String) -> Endpoint {
        return Endpoint(
            path: "/v1/auth/email/login",
            method: .post,
            body: EmailLoginRequest(email: email, password: password),
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

    /// 계정 삭제 — 서버 계약: DELETE /v1/users/me
    static func deleteMe() -> Endpoint {
        return Endpoint(
            path: "/v1/users/me",
            method: .delete,
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

    static func leave(spaceId: UUID) -> Endpoint {
        return Endpoint(
            path: "/v1/spaces/\(spaceId.uuidString)/members/me",
            method: .delete,
            requiresAuth: true
        )
    }
}

// MARK: - Invitation Endpoints

public enum InvitationEndpoints {
    static func issueInviteCode() -> Endpoint {
        return Endpoint(
            path: "/v1/invite-codes",
            method: .post,
            requiresAuth: true
        )
    }

    static func sendInvitation(body: SendInvitationRequest) -> Endpoint {
        return Endpoint(
            path: "/v1/invitations",
            method: .post,
            body: body,
            requiresAuth: true
        )
    }

    static func listInvitations(received: Bool) -> Endpoint {
        let query = [URLQueryItem(name: "received", value: received ? "true" : "false")]
        return Endpoint(
            path: "/v1/invitations",
            method: .get,
            query: query,
            requiresAuth: true
        )
    }

    static func respondInvitation(invitationId: UUID, body: RespondInvitationRequest) -> Endpoint {
        return Endpoint(
            path: "/v1/invitations/\(invitationId.uuidString)",
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
            URLQueryItem(name: "limit", value: String(limit))
        ]
        if let cursor = cursor {
            query.append(URLQueryItem(name: "cursor", value: cursor))
        }
        // 서버 계약: GET /v1/spaces/{spaceId}/moments?cursor=&limit=
        return Endpoint(
            path: "/v1/spaces/\(spaceId)/moments",
            method: .get,
            query: query,
            requiresAuth: true
        )
    }

    /// 위젯/피드용 최신 1건 — 서버 계약: GET /v1/spaces/{spaceId}/moments/latest?excludeMine=true
    static func latestMoment(spaceId: String, excludeMine: Bool) -> Endpoint {
        return Endpoint(
            path: "/v1/spaces/\(spaceId)/moments/latest",
            method: .get,
            query: [URLQueryItem(name: "excludeMine", value: excludeMine ? "true" : "false")],
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
    // 서버 계약: PUT /v1/moments/{id}/reaction (단수) — 등록/교체/토글 모두 PUT 하나
    static func addReaction(momentId: String, emoji: String) -> Endpoint {
        let body = AddReactionRequest(emoji: emoji)
        return Endpoint(
            path: "/v1/moments/\(momentId)/reaction",
            method: .put,
            body: body,
            requiresAuth: true
        )
    }

    static func removeReaction(momentId: String) -> Endpoint {
        return Endpoint(
            path: "/v1/moments/\(momentId)/reaction",
            method: .delete,
            requiresAuth: true
        )
    }
}

// MARK: - Presign Endpoints

public enum PresignEndpoints {
    static func presign(contentType: String = "image/jpeg") -> Endpoint {
        // 서버 계약: POST /v1/moments/presign { contentType }
        return Endpoint(
            path: "/v1/moments/presign",
            method: .post,
            body: PresignRequest(contentType: contentType),
            requiresAuth: true
        )
    }
}

struct PresignRequest: Encodable, Sendable {
    let contentType: String
}

// MARK: - Request Bodies

struct LoginAppleRequest: Encodable, Sendable {
    let identityToken: String
    let nickname: String?
}

struct RefreshTokenRequest: Encodable, Sendable {
    let refreshToken: String
}

struct EmailSignupRequest: Encodable, Sendable {
    let email: String
    let password: String
    let nickname: String
}

struct EmailLoginRequest: Encodable, Sendable {
    let email: String
    let password: String
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

struct SendInvitationRequest: Encodable, Sendable {
    let toUserId: UUID?
    let code: String?

    enum CodingKeys: String, CodingKey {
        case toUserId
        case code
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        if let toUserId = toUserId {
            try container.encode(toUserId, forKey: .toUserId)
        }
        if let code = code {
            try container.encode(code, forKey: .code)
        }
    }
}

struct RespondInvitationRequest: Encodable, Sendable {
    let action: String
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
