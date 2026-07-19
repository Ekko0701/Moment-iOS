import SwiftUI
import Domain
import MomentUIKit
import CoreKit

// 매크로 없는 TCA 구성에서 모듈 경계를 지키기 위해 store.scope 대신 (state, send) 주입을 사용
public struct FeedView: View {
    let state: FeedFeature.State
    let send: (FeedFeature.Action) -> Void

    public init(state: FeedFeature.State, send: @escaping (FeedFeature.Action) -> Void) {
        self.state = state
        self.send = send
    }

    public var body: some View {
        ZStack {
            MomentColor.canvas.ignoresSafeArea()
            OrbBackground.feed().ignoresSafeArea()

            VStack(spacing: 0) {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    EyebrowText("피드")
                        .padding(.horizontal, Spacing.lg)
                        .padding(.top, Spacing.lg)

                    Text("우리 둘의 순간")
                        .font(MomentTypography.headline)
                        .foregroundColor(MomentColor.ink)
                        .padding(.horizontal, Spacing.lg)
                }

                if state.moments.isEmpty {
                    Spacer()

                    ColorBlock(color: .cream) {
                        VStack(alignment: .center, spacing: Spacing.md) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 32, weight: .semibold))
                                .foregroundColor(MomentColor.ink)

                            Text("첫 순간을 기다리는 중")
                                .font(MomentTypography.body)
                                .foregroundColor(MomentColor.ink)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .padding(.horizontal, Spacing.lg)
                    .padding(.vertical, Spacing.xxl)

                    Spacer()
                } else {
                    ScrollView {
                        VStack(spacing: Spacing.lg) {
                            momentsList(state.moments)
                        }
                        .padding(.horizontal, Spacing.lg)
                        .padding(.vertical, Spacing.lg)
                    }
                }

                if state.isLoading {
                    ProgressView()
                        .padding(.vertical, Spacing.lg)
                }
            }
        }
    }

    private func momentsList(_ moments: [Moment]) -> some View {
        VStack(spacing: Spacing.lg) {
            ForEach(moments.enumerated().map({ $0 }), id: \.element.id) { index, moment in
                momentCard(moment, index: index)
            }
        }
    }

    private func momentCard(_ moment: Moment, index: Int) -> some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                // Author header
                HStack(spacing: Spacing.sm) {
                    Circle()
                        .fill(MomentColor.hairline)
                        .frame(width: 34, height: 34)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(moment.author.nickname)
                            .font(.system(.body, design: .default).bold())
                            .foregroundColor(MomentColor.ink)

                        Text(moment.createdAt.relativeTimeString)
                            .font(MomentTypography.caption)
                            .foregroundColor(MomentColor.muted)
                    }

                    Spacer()
                }

                // Content
                if moment.imageURL == nil {
                    if let text = moment.text {
                        Text(text)
                            .font(MomentTypography.body)
                            .foregroundColor(MomentColor.ink)
                            .lineLimit(5)
                    }
                } else {
                    AsyncImage(url: moment.imageURL) { phase in
                        if let image = phase.image {
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(maxHeight: 200)
                                .clipped()
                        } else if phase.error != nil {
                            Color.gray.opacity(0.2)
                                .frame(maxHeight: 200)
                        } else {
                            Color.gray.opacity(0.2)
                                .frame(maxHeight: 200)
                        }
                    }
                    .cornerRadius(Spacing.Radius.md)

                    if let text = moment.text {
                        Text(text)
                            .font(MomentTypography.body)
                            .foregroundColor(MomentColor.ink)
                            .lineLimit(3)
                    }
                }

                // Reactions
                if !moment.reactions.isEmpty {
                    HStack(spacing: Spacing.xs) {
                        ForEach(moment.reactions, id: \.emoji) { reaction in
                            HStack(spacing: 4) {
                                Text(reaction.emoji)
                                    .font(.system(size: 14))

                                Text("\(reaction.count)")
                                    .font(MomentTypography.bodySM)
                            }
                            .padding(.horizontal, Spacing.sm)
                            .padding(.vertical, Spacing.xxs)
                            .background(moment.myReaction == reaction.emoji ? MomentColor.accent : MomentColor.hairline)
                            .foregroundColor(moment.myReaction == reaction.emoji ? MomentColor.inverseInk : MomentColor.ink)
                            .cornerRadius(Spacing.Radius.full)
                        }

                        Spacer()
                    }
                }
            }
            .padding(Spacing.lg)
        }
    }
}

extension Date {
    fileprivate var relativeTimeString: String {
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

// MARK: - Xcode Previews

#Preview("피드 — 모먼트 목록") {
    let state: FeedFeature.State = {
        var s = FeedFeature.State()
        let author = UserProfile(id: UUID(), handle: "moment_1234", nickname: "지은")
        s.moments = [
            Moment(
                id: UUID(),
                spaceId: UUID(),
                author: author,
                text: "오늘 점심 진짜 맛있었어! 다음엔 같이 가자",
                createdAt: Date().addingTimeInterval(-3600),
                myReaction: "❤️",
                reactions: [ReactionCount(emoji: "❤️", count: 1)]
            ),
            Moment(
                id: UUID(),
                spaceId: UUID(),
                author: author,
                text: "퇴근길 하늘이 예뻐서 한 장",
                createdAt: Date().addingTimeInterval(-86400)
            ),
        ]
        return s
    }()
    FeedView(state: state, send: { _ in })
}

#Preview("피드 — 빈 상태") {
    FeedView(state: FeedFeature.State(), send: { _ in })
}
