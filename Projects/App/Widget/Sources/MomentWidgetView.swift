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
                Text("연결하고 순간을 나눠 보세요")
                    .font(.caption)
                    .lineLimit(2)
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

                    Text(snapshot.createdAt.relativeFormatted)
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.7))
                        .shadow(radius: 1)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
            .containerBackground(for: .widget) {
                WidgetPhotoBackground(image: uiImage)
            }
            .widgetURL(URL(string: "moment://moment/\(snapshot.spaceId)/\(snapshot.momentId)"))
        } else {
            // Text-only with pastel color block background based on hash
            let blockColor = getBlockColor(for: snapshot.momentId)
            VStack(alignment: .center, spacing: 4) {
                Text(snapshot.text ?? "")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .lineLimit(2)
                    .foregroundColor(.black)

                HStack(spacing: 4) {
                    Text(snapshot.authorNickname)
                        .font(.caption2)
                        .foregroundColor(.black.opacity(0.7))

                    Spacer()

                    Text(snapshot.createdAt.relativeFormatted)
                        .font(.caption2)
                        .foregroundColor(.black.opacity(0.6))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .containerBackground(blockColor, for: .widget)
            .widgetURL(URL(string: "moment://moment/\(snapshot.spaceId)/\(snapshot.momentId)"))
        }
    }

    private func getBlockColor(for momentId: UUID) -> Color {
        let colors: [Color] = [
            Color(red: 0.863, green: 0.933, blue: 0.694),     // lime
            Color(red: 0.957, green: 0.933, blue: 0.839),     // cream
            Color(red: 0.784, green: 0.902, blue: 0.804),     // mint
            Color(red: 0.937, green: 0.835, blue: 0.835),     // pink
            Color(red: 0.773, green: 0.690, blue: 0.957)      // lilac
        ]
        let index = Int(momentId.uuid.0) % colors.count
        return colors[index]
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
                    Text("로그인하면 함께하는 사람의 순간이 여기 보여요")
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
                    Text("연결하고 순간을 나눠 보세요")
                        .font(.body)
                        .fontWeight(.semibold)
                    Text("1:1로 연결하거나 코드로 그룹에 참여해 보세요")
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
                    Text("새 순간이 공유되면 여기에 보여요")
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

                    Text(snapshot.createdAt.relativeFormatted)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                        .shadow(radius: 1)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
            .containerBackground(for: .widget) {
                WidgetPhotoBackground(image: uiImage)
            }
            .widgetURL(URL(string: "moment://moment/\(snapshot.spaceId)/\(snapshot.momentId)"))
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
                            Text(snapshot.authorNickname)
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)

                            Text(snapshot.createdAt.relativeFormatted)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }

                        Spacer()
                    }
                }
                .padding(12)
            }
            .containerBackground(.fill.tertiary, for: .widget)
            .widgetURL(URL(string: "moment://moment/\(snapshot.spaceId)/\(snapshot.momentId)"))
        }
    }
}

/// 사진 모먼트 위젯의 배경. 아래쪽을 어둡게 깔아 흰 글자가 읽히게 한다.
private struct WidgetPhotoBackground: View {
    let image: UIImage

    var body: some View {
        ZStack {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
            LinearGradient(
                colors: [.clear, .black.opacity(0.45)],
                startPoint: .center,
                endPoint: .bottom
            )
        }
    }
}
