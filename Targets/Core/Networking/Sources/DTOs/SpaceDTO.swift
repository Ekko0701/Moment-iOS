import Foundation
import Domain

struct SpaceDTO: Decodable {
    let id: String
    let type: String
    let members: [String]?

    enum CodingKeys: String, CodingKey {
        case id
        case type
        case members
    }

    func toDomainModel() -> Space {
        Space(id: UUID(uuidString: id) ?? UUID(), type: .oneToOne)
    }
}
