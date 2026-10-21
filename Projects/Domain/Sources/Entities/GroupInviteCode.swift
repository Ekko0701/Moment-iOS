import Foundation

/// 그룹 초대 코드. 만료 전까지 여러 사람이 같은 코드로 참여할 수 있다.
public struct GroupInviteCode: Sendable, Equatable {
    public let code: String
    public let expiresAt: Date

    public init(code: String, expiresAt: Date) {
        self.code = code
        self.expiresAt = expiresAt
    }

    public func isExpired(at now: Date = Date()) -> Bool {
        now > expiresAt
    }
}

/// 그룹 생성 결과 — 만들어진 스페이스와 첫 초대 코드
public struct CreatedGroup: Sendable, Equatable {
    public let space: Space
    public let inviteCode: GroupInviteCode

    public init(space: Space, inviteCode: GroupInviteCode) {
        self.space = space
        self.inviteCode = inviteCode
    }
}
