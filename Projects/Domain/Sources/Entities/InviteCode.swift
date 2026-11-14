import Foundation

/// 1:1 연결용 초대 코드. 만료 전까지 같은 코드로 연결 요청을 보낼 수 있다.
public struct InviteCode: Sendable, Equatable {
    public let code: String
    public let expiresAt: Date

    public init(code: String, expiresAt: Date) {
        self.code = code
        self.expiresAt = expiresAt
    }
}
