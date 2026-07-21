import SwiftUI
import Domain
import MomentUIKit

/// 로그인 직후 진입하는 홈 — Locket 스타일. 파트너의 최신 모먼트 카드가 화면 중앙을 크게 차지하고,
/// 상단에는 스페이스 필, 하단에는 히스토리 진입 힌트만 둔다 (타이틀 없음).
/// 매크로 없는 TCA 구성에서 모듈 경계를 지키기 위해 store.scope 대신 (state, send) 주입을 사용.
public struct HomeView: View {
    let state: HomeFeature.State
    let send: (HomeFeature.Action) -> Void

    public init(state: HomeFeature.State, send: @escaping (HomeFeature.Action) -> Void) {
        self.state = state
        self.send = send
    }

    public var body: some View {
        ZStack {
            MomentColor.canvas.ignoresSafeArea()
            OrbBackground.home().ignoresSafeArea()

            VStack(spacing: 0) {
                SpacePill(title: spaceTitle, days: state.daysTogether)
                    .padding(.top, Spacing.md)

                Spacer(minLength: Spacing.lg)

                if state.space != nil {
                    momentCard
                        .padding(.horizontal, Spacing.lg)
                } else {
                    // 이론상 홈 진입 시 스페이스가 항상 있지만, 방어적으로 안내를 남긴다
                    Text("아직 연결된 스페이스가 없어요")
                        .font(MomentTypography.body)
                        .foregroundColor(MomentColor.ink.opacity(0.6))
                }

                Spacer(minLength: Spacing.lg)

                historyHint
                    .padding(.bottom, Spacing.md)
            }
        }
        .onAppear { send(.onAppear) }
    }

    private var spaceTitle: String {
        if let partner = state.partner {
            return "\(partner.nickname)님과의 스페이스"
        }
        return "우리 둘의 스페이스"
    }

    // MARK: - 메인 모먼트 카드 (Locket 스타일 대형 카드)

    private var momentCard: some View {
        Button {
            send(.spaceCardTapped)
        } label: {
            ZStack {
                cardBackground

                if state.isLoading && state.latestMoment == nil {
                    ProgressView()
                        .tint(.white)
                }
            }
            .frame(maxWidth: .infinity)
            .aspectRatio(345.0 / 430.0, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: 32))
            .overlay(alignment: .topLeading) { senderChip.padding(Spacing.md) }
            .overlay(alignment: .bottom) { captionPill.padding(.bottom, 20) }
            .shadow(color: MomentColor.ink.opacity(0.16), radius: 24, x: 0, y: 14)
            .shadow(color: MomentColor.ink.opacity(0.05), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var cardBackground: some View {
        if let imageURL = state.latestMoment?.imageURL {
            AsyncImage(url: imageURL) { phase in
                if let image = phase.image {
                    image
                        .resizable()
                        .scaledToFill()
                } else {
                    MomentSunsetGradient()
                }
            }
        } else {
            // 텍스트 모먼트(또는 빈 상태)는 선셋 그라디언트가 사진 자리를 대신한다
            MomentSunsetGradient()
        }
    }

    @ViewBuilder
    private var senderChip: some View {
        if let moment = state.latestMoment {
            SenderChip(
                name: moment.author.nickname,
                timeText: moment.createdAt.homeRelativeTimeString
            )
        }
    }

    @ViewBuilder
    private var captionPill: some View {
        if let moment = state.latestMoment {
            if let text = moment.text, !text.isEmpty {
                CaptionPill(text)
                    .padding(.horizontal, Spacing.lg)
            }
        } else if !state.isLoading {
            CaptionPill("아직 상대방의 모먼트가 없어요")
                .padding(.horizontal, Spacing.lg)
        }
    }

    // MARK: - 히스토리 진입 힌트

    private var historyHint: some View {
        Button {
            send(.spaceCardTapped)
        } label: {
            Text("↑ 지난 순간 모아보기")
                .font(.system(size: 12, design: .monospaced))
                .tracking(0.8)
                .foregroundColor(MomentColor.ink.opacity(0.45))
        }
        .buttonStyle(.plain)
    }
}

extension Date {
    fileprivate var homeRelativeTimeString: String {
        let components = Calendar.current.dateComponents([.minute, .hour, .day], from: self, to: Date())
        if let day = components.day, day >= 1 {
            return "\(day)D AGO"
        } else if let hour = components.hour, hour >= 1 {
            return "\(hour)H AGO"
        } else if let minute = components.minute, minute >= 1 {
            return "\(minute)M AGO"
        }
        return "JUST NOW"
    }
}

// MARK: - Xcode Previews

#Preview("홈 — 연결된 스페이스") {
    let me = UserProfile(id: UUID(), handle: "moment_5678", nickname: "동주")
    let partner = UserProfile(id: UUID(), handle: "moment_1234", nickname: "지은")
    let state: HomeFeature.State = {
        var s = HomeFeature.State()
        s.currentUser = me
        s.space = Space(
            id: UUID(),
            type: .oneToOne,
            maxMembers: 2,
            status: "ACTIVE",
            members: [me, partner],
            createdAt: Calendar.current.date(byAdding: .day, value: -99, to: Date()) ?? Date()
        )
        s.latestMoment = Moment(
            id: UUID(),
            spaceId: UUID(),
            author: partner,
            text: "퇴근길 하늘이 예뻐서 한 장 🌇",
            createdAt: Date().addingTimeInterval(-3600)
        )
        return s
    }()
    HomeView(state: state, send: { _ in })
}

#Preview("홈 — 모먼트 없음") {
    let me = UserProfile(id: UUID(), handle: "moment_5678", nickname: "동주")
    let partner = UserProfile(id: UUID(), handle: "moment_1234", nickname: "지은")
    let state: HomeFeature.State = {
        var s = HomeFeature.State()
        s.currentUser = me
        s.space = Space(
            id: UUID(),
            type: .oneToOne,
            maxMembers: 2,
            status: "ACTIVE",
            members: [me, partner],
            createdAt: Date()
        )
        return s
    }()
    HomeView(state: state, send: { _ in })
}
