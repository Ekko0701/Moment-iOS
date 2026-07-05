import WidgetKit
import SwiftUI
import CoreKit

// MARK: - Small Widget View (1x1)
struct MomentSmallWidgetView: View {
    let state: WidgetMomentState

    var body: some View {
        switch state {
        case .needLogin:
            VStack(spacing: 8) {
                Image(systemName: "person.crop.circle")
                    .font(.title2)
                Text("로그인이 필요해요")
                    .font(.caption)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .multilineTextAlignment(.center)
            .foregroundColor(.gray)
            .containerBackground(.fill.tertiary, for: .widget)
            .widgetURL(URL(string: "moment://login"))

        case .needConnect:
            VStack(spacing: 8) {
                Image(systemName: "person.2.fill")
                    .font(.title2)
                Text("상대방을 초대해 보세요")
                    .font(.caption)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .multilineTextAlignment(.center)
            .foregroundColor(.gray)
            .containerBackground(.fill.tertiary, for: .widget)
            .widgetURL(URL(string: "moment://connect"))

        case .empty:
            VStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.title2)
                Text("첫 순간을 기다리는 중")
                    .font(.caption)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .multilineTextAlignment(.center)
            .foregroundColor(.gray)
            .containerBackground(.fill.tertiary, for: .widget)

        case .hasMoment(let snapshot):
            momentSmallView(snapshot: snapshot)
        }
    }

    @ViewBuilder
    private func momentSmallView(snapshot: WidgetMomentSnapshot) -> some View {
        if let imageFileName = snapshot.imageFileName,
           let imageData = WidgetMomentStore().loadCachedImage(fileName: imageFileName),
           let uiImage = UIImage(data: imageData) {
            // Image background with text overlay
            ZStack(alignment: .bottomLeading) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()

                VStack(alignment: .leading, spacing: 4) {
                    Text(snapshot.text ?? "")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .lineLimit(2)
                        .foregroundColor(.white)
                        .shadow(radius: 1)

                    HStack(spacing: 4) {
                        Text(snapshot.authorNickname)
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.9))
                            .shadow(radius: 1)

                        Spacer()

                        Text(snapshot.createdAt.relativeTimeString)
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.7))
                            .shadow(radius: 1)
                    }
                }
                .padding(8)
            }
            .clipped()
            .widgetURL(URL(string: "moment://moment/\(snapshot.momentId)"))
        } else {
            // Text-only with gradient background
            ZStack(alignment: .center) {
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.blue.opacity(0.2),
                        Color.purple.opacity(0.2)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                VStack(alignment: .center, spacing: 4) {
                    Text(snapshot.text ?? "")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .lineLimit(2)
                        .foregroundColor(.primary)

                    HStack(spacing: 4) {
                        Text(snapshot.authorNickname)
                            .font(.caption2)
                            .foregroundColor(.secondary)

                        Spacer()

                        Text(snapshot.createdAt.relativeTimeString)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(8)
            }
            .containerBackground(.fill.tertiary, for: .widget)
            .widgetURL(URL(string: "moment://moment/\(snapshot.momentId)"))
        }
    }
}

// MARK: - Medium Widget View (2x1)
struct MomentMediumWidgetView: View {
    let state: WidgetMomentState

    var body: some View {
        switch state {
        case .needLogin:
            VStack(spacing: 12) {
                Image(systemName: "person.crop.circle")
                    .font(.title)
                VStack(spacing: 4) {
                    Text("로그인이 필요해요")
                        .font(.body)
                        .fontWeight(.semibold)
                    Text("Moment에 로그인하여 친구와 순간을 공유하세요")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .multilineTextAlignment(.center)
            .foregroundColor(.gray)
            .containerBackground(.fill.tertiary, for: .widget)
            .widgetURL(URL(string: "moment://login"))

        case .needConnect:
            VStack(spacing: 12) {
                Image(systemName: "person.2.fill")
                    .font(.title)
                VStack(spacing: 4) {
                    Text("상대방을 초대해 보세요")
                        .font(.body)
                        .fontWeight(.semibold)
                    Text("친구의 초대 코드를 입력하여 스페이스에 초대하세요")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .multilineTextAlignment(.center)
            .foregroundColor(.gray)
            .containerBackground(.fill.tertiary, for: .widget)
            .widgetURL(URL(string: "moment://connect"))

        case .empty:
            VStack(spacing: 12) {
                Image(systemName: "sparkles")
                    .font(.title)
                VStack(spacing: 4) {
                    Text("첫 순간을 기다리는 중")
                        .font(.body)
                        .fontWeight(.semibold)
                    Text("친구의 순간이 공유되면 여기에 나타납니다")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .multilineTextAlignment(.center)
            .foregroundColor(.gray)
            .containerBackground(.fill.tertiary, for: .widget)

        case .hasMoment(let snapshot):
            momentMediumView(snapshot: snapshot)
        }
    }

    @ViewBuilder
    private func momentMediumView(snapshot: WidgetMomentSnapshot) -> some View {
        if let imageFileName = snapshot.imageFileName,
           let imageData = WidgetMomentStore().loadCachedImage(fileName: imageFileName),
           let uiImage = UIImage(data: imageData) {
            // Image background with text overlay
            ZStack(alignment: .bottomLeading) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()

                VStack(alignment: .leading, spacing: 6) {
                    Text(snapshot.text ?? "")
                        .font(.callout)
                        .fontWeight(.medium)
                        .lineLimit(2)
                        .foregroundColor(.white)
                        .shadow(radius: 1)

                    HStack(spacing: 6) {
                        Text(snapshot.authorNickname)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.9))
                            .shadow(radius: 1)

                        Spacer()

                        Text(snapshot.createdAt.relativeTimeString)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                            .shadow(radius: 1)
                    }
                }
                .padding(12)
            }
            .clipped()
            .widgetURL(URL(string: "moment://moment/\(snapshot.momentId)"))
        } else {
            // Text-only with gradient background
            ZStack(alignment: .center) {
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.blue.opacity(0.2),
                        Color.purple.opacity(0.2)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                VStack(alignment: .center, spacing: 8) {
                    Text(snapshot.text ?? "")
                        .font(.callout)
                        .fontWeight(.medium)
                        .lineLimit(2)
                        .foregroundColor(.primary)

                    HStack(spacing: 8) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("By \(snapshot.authorNickname)")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)

                            Text(snapshot.createdAt.relativeTimeString)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }

                        Spacer()
                    }
                }
                .padding(12)
            }
            .containerBackground(.fill.tertiary, for: .widget)
            .widgetURL(URL(string: "moment://moment/\(snapshot.momentId)"))
        }
    }
}

// MARK: - Helper Extensions
extension Date {
    var relativeTimeString: String {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.minute, .hour, .day], from: self, to: now)

        if let day = components.day, day >= 1 {
            return "\(day)일 전"
        } else if let hour = components.hour, hour >= 1 {
            return "\(hour)시간 전"
        } else if let minute = components.minute, minute >= 1 {
            return "\(minute)분 전"
        } else {
            return "방금"
        }
    }
}

