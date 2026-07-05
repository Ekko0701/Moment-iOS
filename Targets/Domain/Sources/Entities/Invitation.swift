import Foundation

public struct Invitation: Sendable, Equatable, Identifiable {
    public let id: UUID
    public let via: InvitationVia
    public let status: InvitationStatus
    public let counterpart: UserProfile
    public let createdAt: Date

    public init(
        id: UUID,
        via: InvitationVia,
        status: InvitationStatus,
        counterpart: UserProfile,
        createdAt: Date
    ) {
        self.id = id
        self.via = via
        self.status = status
        self.counterpart = counterpart
        self.createdAt = createdAt
    }
}

public enum InvitationVia: String, Codable, Sendable {
    case code = "CODE"
    case search = "SEARCH"
}

public enum InvitationStatus: String, Codable, Sendable {
    case pending = "pending"
    case accepted = "accepted"
    case declined = "declined"
    case canceled = "canceled"
    case expired = "expired"
}
