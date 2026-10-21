import Foundation

// MARK: - Group Endpoints

/// 그룹 스페이스 생성·참여·초대 코드·종료 — 서버 계약: /v1/groups
public enum GroupEndpoints {
    static func create(name: String) -> Endpoint {
        Endpoint(path: "/v1/groups", method: .post, body: CreateGroupRequest(name: name), requiresAuth: true)
    }

    static func join(code: String) -> Endpoint {
        Endpoint(path: "/v1/groups/join", method: .post, body: JoinGroupRequest(code: code), requiresAuth: true)
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

struct UpdateMembershipRequest: Encodable, Sendable {
    let notificationsEnabled: Bool
}
