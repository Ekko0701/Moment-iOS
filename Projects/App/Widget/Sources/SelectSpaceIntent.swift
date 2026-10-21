import AppIntents
import WidgetKit
import CoreKit

/// 위젯 설정에서 고르는 스페이스. 목록은 앱이 App Group에 써 둔 스페이스에서 온다.
struct SpaceEntity: AppEntity {
    let id: UUID
    let name: String

    static let typeDisplayRepresentation: TypeDisplayRepresentation = "스페이스"
    static let defaultQuery = SpaceQuery()

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)")
    }

    init(_ info: WidgetSpaceInfo) {
        self.id = info.id
        self.name = info.name
    }
}

struct SpaceQuery: EntityQuery {
    func entities(for identifiers: [UUID]) async throws -> [SpaceEntity] {
        WidgetMomentStore().loadSpaces()
            .filter { identifiers.contains($0.id) }
            .map(SpaceEntity.init)
    }

    func suggestedEntities() async throws -> [SpaceEntity] {
        WidgetMomentStore().loadSpaces().map(SpaceEntity.init)
    }

    func defaultResult() async -> SpaceEntity? {
        let store = WidgetMomentStore()
        guard let id = store.defaultSpaceId() else { return nil }
        return store.loadSpaces().first { $0.id == id }.map(SpaceEntity.init)
    }
}

struct SelectSpaceIntent: WidgetConfigurationIntent {
    static let title: LocalizedStringResource = "스페이스 선택"
    static let description = IntentDescription("위젯에 보여줄 스페이스를 고르세요.")

    /// 고르지 않으면 1:1 스페이스(없으면 첫 스페이스)를 보여준다
    @Parameter(title: "스페이스")
    var space: SpaceEntity?
}
