import Foundation

/// 서버 InviteCodeResponse 매핑: { code, expiresAt(ISO) }
struct InviteCodeDTO: Decodable {
    let code: String
    let expiresAt: String
}
