import WidgetKit
import SwiftUI
import CoreKit

// MARK: - Timeline Entry
struct MomentWidgetEntry: TimelineEntry {
    let date: Date
    let state: WidgetMomentState
}

// MARK: - Widget Timeline Provider
struct MomentWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> MomentWidgetEntry {
        MomentWidgetEntry(date: Date(), state: .empty)
    }

    func getSnapshot(in context: Context, completion: @escaping (MomentWidgetEntry) -> Void) {
        let store = WidgetMomentStore()
        let state = store.loadState()
        let entry = MomentWidgetEntry(date: Date(), state: state)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping @Sendable (Timeline<MomentWidgetEntry>) -> Void) {
        let store = WidgetMomentStore()
        let state = store.loadState()
        let entry = MomentWidgetEntry(date: Date(), state: state)

        // Refresh every 15 minutes
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date()) ?? Date()
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))

        completion(timeline)
    }
}
