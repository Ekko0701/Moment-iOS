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
                    .font(.pretendard(.caption))
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
                    .font(.pretendard(.caption))
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
                    .font(.pretendard(.caption))
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
            WidgetPhotoMoment(snapshot: snapshot, image: uiImage, textSize: 13, metaSize: 11, lineLimit: 3)
        } else {
            // Text-only with pastel color block background based on hash
            let blockColor = getBlockColor(for: snapshot.momentId)
            VStack(alignment: .center, spacing: 4) {
                Text(snapshot.text ?? "")
                    .font(.pretendard(.caption2, weight: .medium))
                    .lineLimit(2)
                    .foregroundColor(.black)

                HStack(spacing: 4) {
                    Text(snapshot.authorNickname)
                        .font(.pretendard(.caption2))
                        .foregroundColor(.black.opacity(0.7))

                    Spacer()

                    Text(snapshot.createdAt.relativeFormatted)
                        .font(.pretendard(.caption2))
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
                        .font(.pretendard(.body, weight: .semibold))
                    Text("로그인하면 함께하는 사람의 순간이 여기 보여요")
                        .font(.pretendard(.caption))
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
                        .font(.pretendard(.body, weight: .semibold))
                    Text("1:1로 연결하거나 코드로 그룹에 참여해 보세요")
                        .font(.pretendard(.caption))
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
                        .font(.pretendard(.body, weight: .semibold))
                    Text("새 순간이 공유되면 여기에 보여요")
                        .font(.pretendard(.caption))
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
            WidgetPhotoMoment(snapshot: snapshot, image: uiImage, textSize: 20, metaSize: 12, lineLimit: 3)
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
                        .font(.pretendard(.callout, weight: .medium))
                        .lineLimit(2)
                        .foregroundColor(.primary)

                    HStack(spacing: 8) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(snapshot.authorNickname)
                                .font(.pretendard(.caption, weight: .semibold))
                                .foregroundColor(.primary)

                            Text(snapshot.createdAt.relativeFormatted)
                                .font(.pretendard(.caption2))
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

/// 사진 모먼트 위젯. 글씨는 보낸 사람이 고른 모서리(왼쪽 위 또는 왼쪽 아래)에서 시작하고,
/// 보낸 사람·시간은 반대쪽 모서리에 둔다. 글씨 없이 사진만 올린 모먼트는 보낸 사람·시간을 왼쪽 아래에 둔다.
private struct WidgetPhotoMoment: View {
    let snapshot: WidgetMomentSnapshot
    let image: UIImage
    let textSize: CGFloat
    let metaSize: CGFloat
    let lineLimit: Int

    private var position: PhotoTextPosition { PhotoTextPosition(name: snapshot.textPosition) }
    private var color: PhotoTextColor { PhotoTextColor(name: snapshot.textColor) }

    private var text: String? {
        guard let text = snapshot.text, !text.isEmpty else { return nil }
        return text
    }

    private var metaPosition: PhotoTextPosition { text == nil ? .bottom : position.opposite }

    var body: some View {
        ZStack {
            if let text {
                Text(text)
                    .photoTextStyle(color: color, fontSize: textSize)
                    .lineLimit(lineLimit)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: position.alignment)
            }

            Text("\(snapshot.authorNickname) · \(snapshot.createdAt.relativeFormatted)")
                .font(.pretendard(size: metaSize, weight: .semibold))
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.5), radius: 1.5, x: 0, y: 1)
                .lineLimit(1)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: metaPosition.alignment)
        }
        .containerBackground(for: .widget) {
            ZStack {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                if text != nil {
                    PhotoTextScrim(position: position, color: color)
                }
                // 보낸 사람·시간 쪽도 옅게 어둡게 해 밝은 사진에서 읽히게 한다
                LinearGradient(
                    stops: [
                        .init(color: .black.opacity(0.32), location: 0),
                        .init(color: .clear, location: 0.3),
                    ],
                    startPoint: metaPosition == .top ? .top : .bottom,
                    endPoint: metaPosition == .top ? .bottom : .top
                )
            }
        }
        .widgetURL(URL(string: "moment://moment/\(snapshot.spaceId)/\(snapshot.momentId)"))
        .accessibilityElement(children: .combine)
    }
}
