import SwiftUI
import Domain
import MomentUIKit

/// 로그인 직후 진입하는 홈 — 참여한 스페이스를 카드(박스)로 보여주는 현관 화면.
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

            VStack(alignment: .leading, spacing: Spacing.lg) {
                EyebrowText("HOME — 우리의 공간")
                    .padding(.top, Spacing.xl)

                Text(greeting)
                    .font(MomentTypography.displayLG)
                    .tracking(-1.0)
                    .foregroundColor(MomentColor.ink)

                if state.space != nil {
                    spaceCard
                } else {
                    // 이론상 홈 진입 시 스페이스가 항상 있지만, 방어적으로 안내를 남긴다
                    Text("아직 연결된 스페이스가 없어요")
                        .font(MomentTypography.body)
                        .foregroundColor(MomentColor.ink.opacity(0.6))
                }

                Spacer()
            }
            .padding(.horizontal, Spacing.lg)
        }
        .onAppear { send(.onAppear) }
    }

    private var greeting: String {
        if let nickname = state.currentUser?.nickname {
            return "\(nickname)님, 안녕하세요"
        }
        return "안녕하세요"
    }

    // MARK: - 스페이스 카드 (박스)

    private var spaceCard: some View {
        Button {
            send(.spaceCardTapped)
        } label: {
            ColorBlock(color: .lilac) {
                VStack(alignment: .leading, spacing: Spacing.md) {
                    HStack(alignment: .firstTextBaseline) {
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            if let partner = state.partner {
                                Text("\(partner.nickname)님과의 공간")
                                    .font(MomentTypography.headline)
                                    .foregroundColor(MomentColor.ink)
                                Text("@\(partner.handle)")
                                    .font(MomentTypography.caption)
                                    .foregroundColor(MomentColor.ink.opacity(0.6))
                            } else {
                                Text("우리 둘의 공간")
                                    .font(MomentTypography.headline)
                                    .foregroundColor(MomentColor.ink)
                            }
                        }
                        Spacer()
                        if let days = state.daysTogether {
                            Text("D+\(days)")
                                .font(MomentTypography.headline)
                                .foregroundColor(MomentColor.ink)
                        }
                    }

                    Divider()
                        .overlay(MomentColor.ink.opacity(0.15))

                    // 최신 모먼트 미리보기
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        EyebrowText("최근 모먼트")
                        if let moment = state.latestMoment {
                            Text(moment.text ?? "사진 모먼트")
                                .font(MomentTypography.body)
                                .foregroundColor(MomentColor.ink)
                                .lineLimit(2)
                                .multilineTextAlignment(.leading)
                        } else if state.isLoading {
                            Text("불러오는 중…")
                                .font(MomentTypography.body)
                                .foregroundColor(MomentColor.ink.opacity(0.5))
                        } else {
                            Text("아직 상대방의 모먼트가 없어요")
                                .font(MomentTypography.body)
                                .foregroundColor(MomentColor.ink.opacity(0.5))
                        }
                    }

                    HStack {
                        Spacer()
                        Text("피드 보기 →")
                            .font(MomentTypography.bodySM)
                            .foregroundColor(MomentColor.ink)
                    }
                }
                .padding(Spacing.lg)
            }
        }
        .buttonStyle(.plain)
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
            text: "퇴근길 하늘이 예뻐서 한 장",
            createdAt: Date()
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
