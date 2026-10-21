import Foundation

// MARK: - Group Endpoints

/// 그룹 스페이스 생성·참여 요청·초대 코드·종료 — 서버 계약: /v1/groups
public enum GroupEndpoints {
    static func create(name: String) -> Endpoint {
        Endpoint(path: "/v1/groups", method: .post, body: CreateGroupRequest(name: name), requiresAuth: true)
    }

    /// 코드로 참여를 요청한다. 응답은 참여 요청이며, 방장이 수락해야 멤버가 된다
    static func join(code: String) -> Endpoint {
        Endpoint(path: "/v1/groups/join", method: .post, body: JoinGroupRequest(code: code), requiresAuth: true)
    }

    static func myJoinRequests() -> Endpoint {
        Endpoint(path: "/v1/groups/join-requests/me", method: .get, requiresAuth: true)
    }

    static func joinRequests(spaceId: UUID) -> Endpoint {
        Endpoint(path: "/v1/groups/\(spaceId.uuidString)/join-requests", method: .get, requiresAuth: true)
    }

    static func decideJoinRequest(spaceId: UUID, requestId: UUID, approve: Bool) -> Endpoint {
        Endpoint(path: "/v1/groups/\(spaceId.uuidString)/join-requests/\(requestId.uuidString)", method: .patch,
                 body: DecideJoinRequestBody(action: approve ? "approve" : "reject"), requiresAuth: true)
    }

    static func cancelJoinRequest(spaceId: UUID, requestId: UUID) -> Endpoint {
        Endpoint(path: "/v1/groups/\(spaceId.uuidString)/join-requests/\(requestId.uuidString)", method: .delete,
                 requiresAuth: true)
    }

    static func inviteCode(spaceId: UUID) -> Endpoint {
        Endpoint(path: "/v1/groups/\(spaceId.uuidString)/invite-code", method: .get, requiresAuth: true)
    }

    static func reissueInviteCode(spaceId: UUID) -> Endpoint {
        Endpoint(path: "/v1/groups/\(spaceId.uuidString)/invite-code", method: .post, requiresAuth: true)
    }

    static func delete(spaceId: UUID) -> Endpoint {
        Endpoint(path: "/v1/groups/\(spaceId.uuidString)", method: .delete, requiresAuth: true)
    }
}

// MARK: - Space Member Endpoints

/// 1:1·그룹 공통 멤버 API — 서버 계약: /v1/spaces/{spaceId}/members
public enum SpaceMemberEndpoints {
    static func list(spaceId: UUID) -> Endpoint {
        Endpoint(path: "/v1/spaces/\(spaceId.uuidString)/members", method: .get, requiresAuth: true)
    }

    static func remove(spaceId: UUID, userId: UUID) -> Endpoint {
        Endpoint(path: "/v1/spaces/\(spaceId.uuidString)/members/\(userId.uuidString)", method: .delete,
                 requiresAuth: true)
    }

    static func updateMine(spaceId: UUID, notificationsEnabled: Bool) -> Endpoint {
        Endpoint(path: "/v1/spaces/\(spaceId.uuidString)/members/me", method: .patch,
                 body: UpdateMembershipRequest(notificationsEnabled: notificationsEnabled), requiresAuth: true)
    }
}

struct CreateGroupRequest: Encodable, Sendable {
    let name: String
}

struct JoinGroupRequest: Encodable, Sendable {
    let code: String
}

struct DecideJoinRequestBody: Encodable, Sendable {
    let action: String
}

struct UpdateMembershipRequest: Encodable, Sendable {
    let notificationsEnabled: Bool
}
