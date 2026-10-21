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

// MARK: - Widget Space Info
/// 위젯 설정 화면이 고를 수 있는 스페이스 한 줄. 앱이 스페이스 목록을 받을 때마다 갱신한다.
public struct WidgetSpaceInfo: Codable, Sendable, Equatable, Identifiable {
    public let id: UUID
    public let name: String
    public let isGroup: Bool

    public init(id: UUID, name: String, isGroup: Bool) {
        self.id = id
        self.name = name
        self.isGroup = isGroup
    }
}

// MARK: - Widget Moment Store
/// 앱과 위젯 확장이 App Group으로 공유하는 위젯 데이터.
///
/// - 전체 상태(`saveState(_:)`): 로그인·연결 필요 여부. `.empty`면 스페이스별 상태를 쓴다.
/// - 스페이스별 상태(`saveState(_:for:)`): 각 스페이스의 나 제외 최신 모먼트.
/// - 스페이스 목록(`saveSpaces`): 위젯 설정에서 고를 수 있는 스페이스.
public final class WidgetMomentStore: @unchecked Sendable {
    private static let appGroupIdentifier = "group.com.ekko.moment"
    private static let stateKey = "widgetMomentState"
    private static let spacesKey = "widgetSpaces"
    private static let spaceStatePrefix = "widgetMomentState."
    private static let imageCacheDirectory = "WidgetMomentCache"

    private let userDefaults: UserDefaults

    public init() {
        guard let userDefaults = UserDefaults(suiteName: Self.appGroupIdentifier) else {
            fatalError("Failed to initialize UserDefaults with app group identifier")
        }
        self.userDefaults = userDefaults
    }

    /// 테스트용 — 임의의 UserDefaults에 같은 규칙으로 읽고 쓴다
    init(userDefaults: UserDefaults) {
        self.userDefaults = userDefaults
    }

    // MARK: - Spaces

    public func saveSpaces(_ spaces: [WidgetSpaceInfo]) {
        guard let encoded = try? JSONEncoder().encode(spaces) else { return }
        userDefaults.set(encoded, forKey: Self.spacesKey)
    }

    public func loadSpaces() -> [WidgetSpaceInfo] {
        guard let data = userDefaults.data(forKey: Self.spacesKey),
              let spaces = try? JSONDecoder().decode([WidgetSpaceInfo].self, from: data)
        else { return [] }
        return spaces
    }

    /// 위젯에서 스페이스를 고르지 않았을 때 보여줄 스페이스 — 1:1이 있으면 1:1, 없으면 첫 스페이스
    public func defaultSpaceId() -> UUID? {
        let spaces = loadSpaces()
        return (spaces.first { !$0.isGroup } ?? spaces.first)?.id
    }

    // MARK: - Per-space State

    public func saveState(_ state: WidgetMomentState, for spaceId: UUID) {
        guard let encoded = try? JSONEncoder().encode(state) else { return }
        userDefaults.set(encoded, forKey: Self.spaceStatePrefix + spaceId.uuidString)
    }

    public func loadState(for spaceId: UUID) -> WidgetMomentState {
        guard let data = userDefaults.data(forKey: Self.spaceStatePrefix + spaceId.uuidString),
              let state = try? JSONDecoder().decode(WidgetMomentState.self, from: data)
        else { return .empty }
        return state
    }

    /// 목록에 없는 스페이스의 상태를 지운다 — 나간 스페이스의 모먼트가 위젯에 남지 않게
    public func removeSpaceStates(except keep: Set<UUID>) {
        for key in userDefaults.dictionaryRepresentation().keys where key.hasPrefix(Self.spaceStatePrefix) {
            let idString = String(key.dropFirst(Self.spaceStatePrefix.count))
            if let id = UUID(uuidString: idString), keep.contains(id) { continue }
            userDefaults.removeObject(forKey: key)
        }
    }

    /// 위젯이 실제로 그릴 상태. 로그인·연결 필요가 우선이고, 그다음 고른 스페이스(없으면 기본 스페이스)의 상태.
    /// 스페이스별 저장 이전 형식(전체 키에 모먼트 1건)이 남아 있으면 그 모먼트를 해당 스페이스 상태로 본다.
    public func resolvedState(selectedSpaceId: UUID?) -> WidgetMomentState {
        let global = loadState()
        switch global {
        case .needLogin, .needConnect:
            return global
        case .hasMoment(let legacy):
            let target = selectedSpaceId ?? defaultSpaceId() ?? legacy.spaceId
            return target == legacy.spaceId ? global : loadState(for: target)
        case .empty:
            guard let target = selectedSpaceId ?? defaultSpaceId() else { return .empty }
            return loadState(for: target)
        }
    }

    /// 로그아웃 — 모든 스페이스 데이터와 사진을 지우고 로그인 필요 상태로 둔다
    public func resetForLogout() {
        removeSpaceStates(except: [])
        userDefaults.removeObject(forKey: Self.spacesKey)
        saveState(.needLogin)
        clearCache()
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

    /// 스페이스별 위젯이 표시할 파일들만 남기고 캐시를 비운다.
    public func pruneImageCache(keeping fileNames: Set<String>) {
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

        for file in files where !fileNames.contains(file.lastPathComponent) {
            try? FileManager.default.removeItem(at: file)
        }
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
