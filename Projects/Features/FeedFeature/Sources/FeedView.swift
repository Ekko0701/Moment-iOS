import SwiftUI
import Domain
import MomentUIKit
import CoreKit

/// 스페이스 히스토리 — 날짜 구분선 + iMessage식 말풍선 타임라인.
/// 상대의 모먼트는 왼쪽 정렬(왼쪽 아래 모서리 6px), 내 모먼트는 오른쪽 정렬(오른쪽 아래 6px).
/// 매크로 없는 TCA 구성에서 모듈 경계를 지키기 위해 store.scope 대신 (state, send) 주입을 사용.
public struct FeedView: View {
    let state: FeedFeature.State
    let send: (FeedFeature.Action) -> Void
    let currentUserId: UUID?

    public init(
        state: FeedFeature.State,
        send: @escaping (FeedFeature.Action) -> Void,
        currentUserId: UUID? = nil
    ) {
        self.state = state
        self.send = send
        self.currentUserId = currentUserId
    }

    public var body: some View {
        ZStack {
            MomentColor.canvas.ignoresSafeArea()
            OrbBackground.feed().ignoresSafeArea()

            if state.moments.isEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVStack(spacing: Spacing.md) {
                        ForEach(daySections, id: \.label) { section in
                            DateDividerPill(section.label)
                                .frame(maxWidth: .infinity)
                                .padding(.top, Spacing.xs)

                            ForEach(section.moments, id: \.id) { moment in
                                bubbleRow(moment)
                            }
                        }

                        if state.nextCursor != nil {
                            ProgressView()
                                .padding(.vertical, Spacing.md)
                                .onAppear { send(.loadMore) }
                        }
                    }
                    .padding(.horizontal, Spacing.lg)
                    .padding(.vertical, Spacing.md)
                }
            }

            if state.isLoading && state.moments.isEmpty {
                ProgressView()
                    .tint(MomentColor.ink)
            }
        }
    }

    // MARK: - 날짜 그룹핑

    private var daySections: [(label: String, moments: [Moment])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: state.moments) { calendar.startOfDay(for: $0.createdAt) }
        return grouped.keys.sorted(by: >).map { day in
            (
                label: day.feedDividerLabel,
                moments: (grouped[day] ?? []).sorted { $0.createdAt > $1.createdAt }
            )
        }
    }

    // MARK: - 말풍선

    private func bubbleRow(_ moment: Moment) -> some View {
        let isMine = moment.author.id == currentUserId
        return HStack(spacing: 0) {
            if isMine { Spacer(minLength: Spacing.xxl) }
            bubble(moment, isMine: isMine)
            if !isMine { Spacer(minLength: Spacing.xxl) }
        }
    }

    private func bubble(_ moment: Moment, isMine: Bool) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            // 발신자 헤더
            HStack(spacing: Spacing.xs) {
                Circle()
                    .fill(isMine ? MomentColor.hairline : MomentColor.orbCoral.opacity(0.6))
                    .frame(width: 26, height: 26)

                Text(moment.author.nickname)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(MomentColor.ink)

                Text(moment.createdAt.feedRelativeTimeString)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(MomentColor.ink.opacity(0.5))
            }

            // 사진
            if let imageURL = moment.imageURL {
                AsyncImage(url: imageURL) { phase in
                    if let image = phase.image {
                        image
                            .resizable()
                            .scaledToFill()
                    } else {
                        MomentSunsetGradient()
                    }
                }
                .frame(maxHeight: 200)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }

            // 텍스트
            if let text = moment.text, !text.isEmpty {
                Text(text)
                    .font(MomentTypography.body)
                    .foregroundColor(MomentColor.ink)
                    .multilineTextAlignment(.leading)
            }

            // 리액션 칩
            if !moment.reactions.isEmpty {
                HStack(spacing: Spacing.xs) {
                    ForEach(moment.reactions, id: \.emoji) { reaction in
                        Button {
                            send(.reactionTapped(momentId: moment.id, emoji: reaction.emoji))
                        } label: {
                            HStack(spacing: 4) {
                                Text(reaction.emoji)
                                    .font(.system(size: 13))
                                Text("\(reaction.count)")
                                    .font(.system(size: 12, weight: .medium))
                            }
                            .padding(.horizontal, Spacing.sm)
                            .padding(.vertical, 6)
                            .background(
                                moment.myReaction == reaction.emoji
                                    ? MomentColor.ink.opacity(0.85)
                                    : MomentColor.ink.opacity(0.06)
                            )
                            .foregroundColor(
                                moment.myReaction == reaction.emoji
                                    ? MomentColor.inverseInk
                                    : MomentColor.ink
                            )
                            .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial)
        .background(Color.white.opacity(0.35))
        .bubbleCorners(isMine: isMine)
        .shadow(color: MomentColor.ink.opacity(0.08), radius: 10, x: 0, y: 6)
    }

    // MARK: - 빈 상태

    private var emptyState: some View {
        SurfaceCard {
            VStack(spacing: Spacing.md) {
                Image(systemName: "sparkles")
                    .font(.system(size: 32, weight: .semibold))
                    .foregroundColor(MomentColor.ink)

                Text("첫 순간을 기다리는 중")
                    .font(MomentTypography.body)
                    .foregroundColor(MomentColor.ink)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.xl)
        }
        .padding(.horizontal, Spacing.lg)
    }
}

extension Date {
    fileprivate var feedDividerLabel: String {
        let calendar = Calendar.current
        if calendar.isDateInToday(self) { return "오늘" }
        if calendar.isDateInYesterday(self) { return "어제" }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        let sameYear = calendar.component(.year, from: self) == calendar.component(.year, from: Date())
        formatter.dateFormat = sameYear ? "M월 d일" : "yyyy년 M월 d일"
        return formatter.string(from: self)
    }

    fileprivate var feedRelativeTimeString: String {
        let components = Calendar.current.dateComponents([.minute, .hour, .day], from: self, to: Date())
        if let day = components.day, day >= 1 {
            return "\(day)일 전"
        } else if let hour = components.hour, hour >= 1 {
            return "\(hour)시간 전"
        } else if let minute = components.minute, minute >= 1 {
            return "\(minute)분 전"
        }
        return "방금"
    }
}

// MARK: - Xcode Previews

#Preview("피드 — 말풍선 타임라인") {
    let me = UserProfile(id: UUID(), handle: "moment_5678", nickname: "동주")
    let partner = UserProfile(id: UUID(), handle: "moment_1234", nickname: "지은")
    let state: FeedFeature.State = {
        var s = FeedFeature.State()
        s.moments = [
            Moment(
                id: UUID(),
                spaceId: UUID(),
                author: partner,
                text: "퇴근길 하늘이 예뻐서 한 장 🌇",
                createdAt: Date().addingTimeInterval(-3600),
                myReaction: "❤️",
                reactions: [ReactionCount(emoji: "❤️", count: 1)]
            ),
            Moment(
                id: UUID(),
                spaceId: UUID(),
                author: me,
                text: "오늘 점심 진짜 맛있었어! 다음엔 같이 가자",
                createdAt: Date().addingTimeInterval(-90000),
                reactions: [ReactionCount(emoji: "😂", count: 1)]
            ),
        ]
        return s
    }()
    FeedView(state: state, send: { _ in }, currentUserId: me.id)
}

#Preview("피드 — 빈 상태") {
    FeedView(state: FeedFeature.State(), send: { _ in })
}
