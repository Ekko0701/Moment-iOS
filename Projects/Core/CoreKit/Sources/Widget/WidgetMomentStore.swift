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
        // 위젯 확장이 같은 파일을 읽는 동안 앱이 덮어쓸 수 있다.
        // 원자적 쓰기로 잘린 데이터가 읽히는 경우를 막는다.
        try data.write(to: fileURL, options: .atomic)
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

    /// 위젯이 표시할 파일 하나만 남기고 캐시를 비운다.
    /// 위젯은 항상 상대의 최신 모먼트 1건만 보여주므로 지난 이미지를 보관할 이유가 없다.
    /// fileName이 nil이면 전부 삭제 — 연결 해제·로그아웃 후 상대 사진을 컨테이너에 남기지 않는다.
    public func pruneImageCache(keeping fileName: String?) {
        guard let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: Self.appGroupIdentifier
        ) else {
            return
        }

        let cacheURL = containerURL
            .appendingPathComponent(Self.imageCacheDirectory, isDirectory: true)

        guard let files = try? FileManager.default.contentsOfDirectory(
            at: cacheURL,
            includingPropertiesForKeys: nil
        ) else {
            return
        }

        for file in files where file.lastPathComponent != fileName {
            try? FileManager.default.removeItem(at: file)
        }
    }
}
