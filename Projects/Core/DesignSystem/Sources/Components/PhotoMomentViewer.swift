import SwiftUI
import CoreKit

/// 사진 모먼트를 화면 가득 보는 뷰어. 사진 전체를 잘림 없이 보여 주고, 글씨는 올린 사람이 고른 모서리에 그린다.
/// 글씨가 사진을 가릴 때 잠시 숨길 수 있다. 아래쪽에는 화면마다 필요한 것(반응 등)을 footer로 넣는다.
public struct PhotoMomentViewer<Footer: View>: View {
    let imageURL: URL?
    let authorName: String
    let detailText: String
    let text: String?
    let position: PhotoTextPosition
    let color: PhotoTextColor
    let onClose: () -> Void
    let footer: Footer

    @State private var hidesText = false

    private static var background: Color { Color(red: 0.055, green: 0.051, blue: 0.055) }
    private static var chipFill: Color { Color.white.opacity(0.14) }

    public init(
        imageURL: URL?,
        authorName: String,
        detailText: String,
        text: String?,
        position: PhotoTextPosition,
        color: PhotoTextColor,
        onClose: @escaping () -> Void,
        @ViewBuilder footer: () -> Footer
    ) {
        self.imageURL = imageURL
        self.authorName = authorName
        self.detailText = detailText
        self.text = text
        self.position = position
        self.color = color
        self.onClose = onClose
        self.footer = footer()
    }

    public var body: some View {
        ZStack {
            Self.background.ignoresSafeArea()

            VStack(spacing: Spacing.md) {
                header
                Spacer(minLength: 0)
                photo
                Spacer(minLength: 0)
                bottomRow
            }
            .padding(.vertical, Spacing.sm)
        }
        // 뷰어는 화면 모드와 상관없이 어두운 바탕이라, 안쪽 색 토큰과 상태 표시줄을 다크로 맞춘다
        .environment(\.colorScheme, .dark)
        .preferredColorScheme(.dark)
    }

    private var header: some View {
        HStack(spacing: Spacing.xs) {
            Circle()
                .fill(MomentColor.orbLavender)
                .frame(width: 32, height: 32)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 1) {
                Text(authorName)
                    .font(.pretendard(size: 15, weight: .bold))
                    .foregroundColor(.white)
                Text(detailText)
                    .font(.pretendard(size: 12))
                    .foregroundColor(Color(white: 0.72))
                    .lineLimit(1)
            }
            .accessibilityElement(children: .combine)

            Spacer(minLength: Spacing.xs)

            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(Self.chipFill)
                    .clipShape(Circle())
            }
            .buttonStyle(MomentPressStyle())
            .accessibilityLabel("닫기")
        }
        .padding(.horizontal, Spacing.md)
    }

    private var photo: some View {
        AsyncImage(url: imageURL) { phase in
            if let image = phase.image {
                image
                    .resizable()
                    .scaledToFit()
                    .overlay { textOverlay }
                    .accessibilityLabel("사진")
            } else {
                // 사진을 받는 중이거나 받지 못했을 때도 글씨는 같은 자리에 보여 준다
                MomentSunsetGradient()
                    .aspectRatio(3.0 / 4.0, contentMode: .fit)
                    .overlay { textOverlay }
                    .overlay {
                        if phase.error == nil {
                            ProgressView().tint(.white)
                        } else {
                            Text("사진을 불러오지 못했어요")
                                .font(.pretendard(size: 13, weight: .medium))
                                .foregroundColor(.white)
                        }
                    }
            }
        }
        .animation(.easeOut(duration: 0.15), value: hidesText)
    }

    @ViewBuilder
    private var textOverlay: some View {
        if let text, !text.isEmpty, !hidesText {
            PhotoTextOverlay(text: text, position: position, color: color, lineLimit: 12)
                .transition(.opacity)
        }
    }

    private var bottomRow: some View {
        HStack(spacing: Spacing.xs) {
            footer
            Spacer(minLength: 0)
            if let text, !text.isEmpty {
                Button {
                    hidesText.toggle()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: hidesText ? "eye" : "eye.slash")
                            .font(.system(size: 13, weight: .medium))
                        Text(hidesText ? "글씨 보기" : "글씨 숨기기")
                            .font(.pretendard(size: 13, weight: .medium))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .frame(height: 44)
                    .background(Self.chipFill)
                    .clipShape(Capsule())
                }
                .buttonStyle(MomentPressStyle())
            }
        }
        .padding(.horizontal, Spacing.md)
        .frame(minHeight: 44)
    }
}

public extension PhotoMomentViewer where Footer == EmptyView {
    /// 아래쪽에 따로 넣을 것이 없는 뷰어
    init(
        imageURL: URL?,
        authorName: String,
        detailText: String,
        text: String?,
        position: PhotoTextPosition,
        color: PhotoTextColor,
        onClose: @escaping () -> Void
    ) {
        self.init(
            imageURL: imageURL,
            authorName: authorName,
            detailText: detailText,
            text: text,
            position: position,
            color: color,
            onClose: onClose,
            footer: { EmptyView() }
        )
    }
}
