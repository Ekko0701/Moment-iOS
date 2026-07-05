import Foundation

public struct Space: Sendable, Equatable, Identifiable {
    public let id: UUID
    public let type: SpaceType
    public let name: String?
    public let maxMembers: Int
    public let status: String
    public let members: [UserProfile]
    public let createdAt: Date

    public init(
        id: UUID,
        type: SpaceType,
        name: String? = nil,
        maxMembers: Int,
        status: String,
        members: [UserProfile],
        createdAt: Date
    ) {
        self.id = id
        self.type = type
        self.name = name
        self.maxMembers = maxMembers
        self.status = status
        self.members = members
        self.createdAt = createdAt
    }
}
