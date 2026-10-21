import WidgetKit
import SwiftUI

@main
struct MomentWidgetBundle: WidgetBundle {
    var body: some Widget {
        MomentWidget()
    }
}

struct MomentWidget: Widget {
    let kind: String = "com.ekko.moment.widget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: SelectSpaceIntent.self,
            provider: MomentWidgetProvider()
        ) { entry in
            MomentWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Moment")
        .description("고른 스페이스의 최신 순간을 확인하세요")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct MomentWidgetEntryView: View {
    let entry: MomentWidgetProvider.Entry

    @Environment(\.widgetFamily) var widgetFamily

    var body: some View {
        switch widgetFamily {
        case .systemSmall:
            MomentSmallWidgetView(state: entry.state)
        case .systemMedium:
            MomentMediumWidgetView(state: entry.state)
        @unknown default:
            MomentSmallWidgetView(state: entry.state)
        }
    }
}
