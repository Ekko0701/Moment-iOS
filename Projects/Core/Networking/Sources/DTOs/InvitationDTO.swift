import Foundation
import Domain

/// 서버 InvitationResponse 매핑: { id, fromUserId, toUserId, via, status, createdAt, respondedAt, counterpart }
struct InvitationDTO: Decodable {
    let id: UUID
    let via: String
    let status: String
    let createdAt: Date
    let counterpart: UserProfileDTO

    func toDomainModel() -> Invitation {
        Invitation(
            id: id,
            via: InvitationVia(rawValue: via.uppercased()) ?? .code,
            status: InvitationStatus(rawValue: status.lowercased()) ?? .pending,
            counterpart: counterpart.toDomainModel(),
            createdAt: createdAt
        )
    }
}
