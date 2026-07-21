import SwiftUI

// MARK: - Space Pill (홈/스페이스 상단 중앙 — 아바타 + 스페이스명 + D+n)

public struct SpacePill: View {
    let title: String
    let days: Int?

    public init(title: String, days: Int? = nil) {
        self.title = title
        self.days = days
    }

    public var body: some View {
        HStack(spacing: Spacing.xs) {
            Circle()
                .fill(MomentColor.orbCoral.opacity(0.75))
                .frame(width: 24, height: 24)

            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(MomentColor.ink)

            if let days {
                Text("D+\(days)")
                    .font(.system(size: 12, design: .default))
                    .foregroundColor(MomentColor.ink.opacity(0.55))
            }
        }
        .padding(.leading, Spacing.sm)
        .padding(.trailing, Spacing.md)
        .padding(.vertical, Spacing.xs)
        .background(.ultraThinMaterial)
        .background(Color.white.opacity(0.35))
        .clipShape(Capsule())
        .overlay(Capsule().stroke(Color.white.opacity(0.75), lineWidth: 1))
        .shadow(color: MomentColor.ink.opacity(0.08), radius: 12, x: 0, y: 4)
    }
}

// MARK: - Sender Chip (사진/카드 위 발신자 — 반투명 다크 필)

public struct SenderChip: View {
    let name: String
    let timeText: String

    public init(name: String, timeText: String) {
        self.name = name
        self.timeText = timeText
    }

    public var body: some View {
        HStack(spacing: Spacing.xs) {
            Circle()
                .fill(Color.white.opacity(0.9))
                .frame(width: 22, height: 22)

            Text(name)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.white)

            Text(timeText)
                .font(.system(size: 11, design: .default))
                .foregroundColor(.white.opacity(0.75))
        }
        .padding(.leading, Spacing.xs)
        .padding(.trailing, 14)
        .padding(.vertical, 6)
        .background(MomentColor.ink.opacity(0.32))
        .clipShape(Capsule())
    }
}

// MARK: - Caption Pill (모먼트 카드 하단 캡션)

public struct CaptionPill: View {
    let text: String

    public init(_ text: String) {
        self.text = text
    }

    public var body: some View {
        Text(text)
            .font(.system(size: 15))
            .foregroundColor(MomentColor.ink)
            .lineLimit(1)
            .padding(.horizontal, 18)
            .padding(.vertical, 10)
            .background(Color.white.opacity(0.85))
            .clipShape(Capsule())
            .shadow(color: MomentColor.ink.opacity(0.10), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Date Divider Pill (피드 날짜 구분선 — 오늘/어제/M월 d일)

public struct DateDividerPill: View {
    let text: String

    public init(_ text: String) {
        self.text = text
    }

    public var body: some View {
        Text(text)
            .font(.system(size: 11, weight: .medium))
            .foregroundColor(MomentColor.ink.opacity(0.55))
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, 5)
            .background(MomentColor.ink.opacity(0.06))
            .clipShape(Capsule())
    }
}

// MARK: - Sunset Gradient (사진 없는 모먼트/플레이스홀더용)

public struct MomentSunsetGradient: View {
    public init() {}

    public var body: some View {
        LinearGradient(
            colors: [
                Color(red: 0.55, green: 0.62, blue: 0.85),
                Color(red: 0.95, green: 0.62, blue: 0.45),
                Color(red: 0.98, green: 0.80, blue: 0.50),
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

// MARK: - Bubble Corners (iMessage식 비대칭 말풍선 모서리)

extension View {
    /// 말풍선 모서리 — 발신 방향의 아래 모서리만 6px, 나머지는 24px.
    /// 벡터 꼬리 대신 정렬+모서리로 방향을 표현한다.
    public func bubbleCorners(isMine: Bool) -> some View {
        clipShape(
            .rect(
                topLeadingRadius: 24,
                bottomLeadingRadius: isMine ? 24 : 6,
                bottomTrailingRadius: isMine ? 6 : 24,
                topTrailingRadius: 24
            )
        )
    }
}

// MARK: - Xcode Previews

#Preview("카드 키트") {
    ZStack {
        MomentColor.canvas.ignoresSafeArea()
        VStack(spacing: 20) {
            SpacePill(title: "지은님과의 스페이스", days: 99)
            SenderChip(name: "지은", timeText: "1H AGO")
                .frame(maxWidth: .infinity)
                .padding()
                .background(MomentSunsetGradient())
            CaptionPill("퇴근길 하늘이 예뻐서 한 장 🌇")
            DateDividerPill("오늘")
        }
        .padding()
    }
}
