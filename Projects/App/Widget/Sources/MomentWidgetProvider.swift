import WidgetKit
import SwiftUI
import CoreKit

// MARK: - Timeline Entry
struct MomentWidgetEntry: TimelineEntry {
    let date: Date
    let state: WidgetMomentState
}

// MARK: - Widget Timeline Provider
/// 위젯 설정에서 고른 스페이스의 최신 모먼트를 App Group에서 읽는다. 네트워크는 쓰지 않는다.
struct MomentWidgetProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> MomentWidgetEntry {
        MomentWidgetEntry(date: Date(), state: .empty)
    }

    func snapshot(for configuration: SelectSpaceIntent, in context: Context) async -> MomentWidgetEntry {
        entry(for: configuration)
    }

    func timeline(for configuration: SelectSpaceIntent, in context: Context) async -> Timeline<MomentWidgetEntry> {
        // 앱이 새 모먼트를 받으면 즉시 갱신을 요청하므로, 여기서는 15분 주기로 캐시만 다시 읽는다
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date()) ?? Date()
        return Timeline(entries: [entry(for: configuration)], policy: .after(nextUpdate))
    }

    private func entry(for configuration: SelectSpaceIntent) -> MomentWidgetEntry {
        let state = WidgetMomentStore().resolvedState(selectedSpaceId: configuration.space?.id)
        return MomentWidgetEntry(date: Date(), state: state)
    }
}
