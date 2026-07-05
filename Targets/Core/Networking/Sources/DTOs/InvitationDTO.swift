import Foundation
import Domain

struct InvitationDTO: Decodable {
    let id: String
    let spaceId: String

    enum CodingKeys: String, CodingKey {
        case id
        case spaceId
    }

    func toDomainModel() -> Invitation {
        Invitation(id: UUID(uuidString: id) ?? UUID(), spaceId: UUID(uuidString: spaceId) ?? UUID())
    }
}
