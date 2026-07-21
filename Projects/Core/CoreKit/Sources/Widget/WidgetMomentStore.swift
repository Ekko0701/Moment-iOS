import Foundation

// MARK: - Widget Moment State
public enum WidgetMomentState: Codable, Sendable {
    case needLogin
    case needConnect
    case empty
    case hasMoment(WidgetMomentSnapshot)

    public var isMoment: Bool {
        if case .hasMoment = self {
            return true
        }
        return false
    }
}

// MARK: - Widget Moment Snapshot
public struct WidgetMomentSnapshot: Codable, Sendable {
    public let momentId: UUID
    public let spaceId: UUID
    public let authorNickname: String
    public let text: String?
    public let imageFileName: String?
    public let createdAt: Date
    public let hasImage: Bool

    public init(
        momentId: UUID,
        spaceId: UUID,
        authorNickname: String,
        text: String?,
        imageFileName: String?,
        createdAt: Date,
        hasImage: Bool
    ) {
        self.momentId = momentId
        self.spaceId = spaceId
        self.authorNickname = authorNickname
        self.text = text
        self.imageFileName = imageFileName
        self.createdAt = createdAt
        self.hasImage = hasImage
    }
}

// MARK: - Widget Moment Store
public final class WidgetMomentStore: Sendable {
    private static let appGroupIdentifier = "group.com.ekko.moment"
    private static let stateKey = "widgetMomentState"
    private static let imageCacheDirectory = "WidgetMomentCache"

    private let userDefaults: UserDefaults

    public init() {
        guard let userDefaults = UserDefaults(suiteName: Self.appGroupIdentifier) else {
            fatalError("Failed to initialize UserDefaults with app group identifier")
        }
        self.userDefaults = userDefaults
    }

    // MARK: - Save State
    public func saveState(_ state: WidgetMomentState) {
        do {
            let encoded = try JSONEncoder().encode(state)
            userDefaults.set(encoded, forKey: Self.stateKey)
            userDefaults.synchronize()
        } catch {
            print("[WidgetMomentStore] Failed to encode state: \(error)")
        }
    }

    // MARK: - Load State
    public func loadState() -> WidgetMomentState {
        guard let data = userDefaults.data(forKey: Self.stateKey) else {
            return .empty
        }

        do {
            return try JSONDecoder().decode(WidgetMomentState.self, from: data)
        } catch {
            print("[WidgetMomentStore] Failed to decode state: \(error)")
            return .empty
        }
    }

    // MARK: - Image Cache Management
    public func cacheImage(_ data: Data, fileName: String) throws {
        guard let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: Self.appGroupIdentifier
        ) else {
            throw NSError(
                domain: "WidgetMomentStore",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Container URL not found"]
            )
        }

        let cacheURL = containerURL
            .appendingPathComponent(Self.imageCacheDirectory, isDirectory: true)

        try FileManager.default.createDirectory(
            at: cacheURL,
            withIntermediateDirectories: true,
            attributes: nil
        )

        let fileURL = cacheURL.appendingPathComponent(fileName)
        try data.write(to: fileURL)
    }

    public func loadCachedImage(fileName: String) -> Data? {
        guard let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: Self.appGroupIdentifier
        ) else {
            return nil
        }

        let fileURL = containerURL
            .appendingPathComponent(Self.imageCacheDirectory, isDirectory: true)
            .appendingPathComponent(fileName)

        return try? Data(contentsOf: fileURL)
    }

    public func clearCache() {
        guard let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: Self.appGroupIdentifier
        ) else {
            return
        }

        let cacheURL = containerURL
            .appendingPathComponent(Self.imageCacheDirectory, isDirectory: true)

        try? FileManager.default.removeItem(at: cacheURL)
    }
}
