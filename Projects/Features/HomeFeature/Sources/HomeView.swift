import SwiftUI
import Domain
import MomentUIKit

/// 로그인 직후 진입하는 홈 — Locket 스타일.
/// 사진 모먼트는 대형 그라디언트/사진 카드, 텍스트 모먼트는 높이가 내용에 맞는 글래스 카드로 보여준다.
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
            // GlassMinimal 시안: 홈은 순백 캔버스 — 사진(히어로)이 유일한 색이 되도록 오브 제거
            MomentColor.canvas.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer(minLength: Spacing.lg)

                if state.space != nil {
                    // 관계 정보는 내비 상단이 아니라 카드 바로 위 — 콘텐츠와 한 덩어리로 읽히도록
                    spaceLabel
                        .padding(.bottom, Spacing.sm)

                    momentContent
                        .padding(.horizontal, Spacing.lg)
                        // 비동기 모먼트가 도착할 때 스냅 교체 대신 부드럽게 안착
                        .animation(.easeOut(duration: 0.25), value: state.latestMoment)
                } else {
                    // 이론상 홈 진입 시 스페이스가 항상 있지만, 방어적으로 안내를 남긴다
                    Text("아직 연결된 스페이스가 없어요")
                        .font(MomentTypography.body)
                        .foregroundColor(MomentColor.ink.opacity(0.6))
                }

                // 시안 02b: 히스토리 진입은 카드 바로 아래 — 카드와 한 묶음으로 읽히도록
                historyHint
                    .padding(.top, Spacing.sm)

                Spacer(minLength: Spacing.lg)
            }
        }
        .onAppear { send(.onAppear) }
        // 내비는 앱 정체성만 — 관계 정보(스페이스 · D+n)는 카드 위 spaceLabel이 담당한다
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Moment")
                    .font(.subheadline.weight(.bold))
                    .foregroundColor(MomentColor.ink)
            }
        }
    }

    // MARK: - 스페이스 라벨 (카드 바로 위)

    private var spaceLabel: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(MomentColor.orbCoral.opacity(0.75))
                .frame(width: 18, height: 18)

            Text(spaceTitle)
                .font(.footnote.weight(.medium))
                .foregroundColor(MomentColor.ink)

            if let days = state.daysTogether {
                Text("D+\(days)")
                    .font(.caption.weight(.medium))
                    .foregroundColor(MomentColor.accent)
            }
        }
    }

    private var spaceTitle: String {
        if let partner = state.partner {
            return "\(partner.nickname)님과의 스페이스"
        }
        return "우리 둘의 스페이스"
    }

    // MARK: - 모먼트 콘텐츠 (사진 / 텍스트 / 빈 상태 분기)

    @ViewBuilder
    private var momentContent: some View {
        if let moment = state.latestMoment {
            if moment.imageURL != nil {
                photoMomentCard(moment)
            } else {
                textMomentCard(moment)
            }
        } else if state.isLoading {
            glassCard {
                ProgressView()
                    .tint(MomentColor.ink)
                    .padding(.vertical, Spacing.md)
            }
        } else {
            glassCard {
                Text("아직 상대방의 모먼트가 없어요")
                    .font(MomentTypography.body)
                    .foregroundColor(MomentColor.ink.opacity(0.65))
            }
        }
    }

    // MARK: - 사진 모먼트 카드 (Locket 스타일 대형 카드)

    private func photoMomentCard(_ moment: Moment) -> some View {
        Button {
            send(.spaceCardTapped)
        } label: {
            AsyncImage(url: moment.imageURL) { phase in
                if let image = phase.image {
                    image
                        .resizable()
                        .scaledToFill()
                } else {
                    MomentSunsetGradient()
                }
            }
            .frame(maxWidth: .infinity)
            // 시안: 모든 모먼트가 같은 자리·같은 크기 — 사진도 텍스트·빈 상태와 동일한 정사각형.
            // scaledToFill과 결합해 중앙 크롭되며, 사진↔글 전환 시 레이아웃이 출렁이지 않는다.
            .aspectRatio(1, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: 26))
            .overlay(alignment: .topLeading) {
                SenderChip(
                    name: moment.author.nickname,
                    timeText: moment.createdAt.homeRelativeTimeString
                )
                .padding(Spacing.md)
            }
            .overlay(alignment: .bottom) {
                if let text = moment.text, !text.isEmpty {
                    CaptionPill(text)
                        .padding(.horizontal, Spacing.lg)
                        .padding(.bottom, 20)
                }
            }
        }
        .buttonStyle(MomentPressStyle(scale: 0.98))
    }

    // MARK: - 텍스트 모먼트 카드 (높이가 내용에 맞는 글래스 카드)

    private func textMomentCard(_ moment: Moment) -> some View {
        Button {
            send(.spaceCardTapped)
        } label: {
            glassCard {
                // 시안 02b: 문장이 정중앙의 주인공 — 큰 타이포(Dynamic Type 대응), 여유로운 행간
                Text(moment.text ?? "")
                    .font(.title2.weight(.medium))
                    .foregroundColor(MomentColor.ink)
                    .multilineTextAlignment(.center)
                    .lineSpacing(8)
            }
            // 발신자 칩은 좌상단 코너 오버레이 (사진 히어로의 SenderChip과 같은 위치 문법)
            .overlay(alignment: .topLeading) {
                senderBadge(moment)
                    .padding(Spacing.md)
            }
        }
        .buttonStyle(MomentPressStyle(scale: 0.98))
    }

    // 밝은 서피스 위 발신자 칩 — 그레이 캡슐 (시안 02b)
    private func senderBadge(_ moment: Moment) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(MomentColor.orbCoral.opacity(0.75))
                .frame(width: 20, height: 20)

            Text(moment.author.nickname)
                .font(.footnote.weight(.bold))
                .foregroundColor(MomentColor.ink)

            Text(moment.createdAt.homeRelativeTimeString)
                .font(.caption2)
                .foregroundColor(MomentColor.ink.opacity(0.6)) // 그레이 칩 위 AA 대비 확보
        }
        .padding(.leading, 8)
        .padding(.trailing, 12)
        .padding(.vertical, 6)
        .background(MomentColor.surfaceSoft)
        .clipShape(Capsule())
    }

    // 정사각형 서피스 카드 공통 래퍼 — 시안: 텍스트 모먼트·로딩·빈 상태가 히어로 자리에서
    // 1:1 형태 언어를 공유한다 (사진 = 세로 히어로 ↔ 글·안내 = 정사각형). 콘텐츠는 중앙 배치.
    private func glassCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .padding(.vertical, 28)
            .padding(.horizontal, Spacing.lg)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .aspectRatio(1, contentMode: .fit)
            .background(MomentColor.surface)
            .clipShape(RoundedRectangle(cornerRadius: 26))
            .overlay(
                RoundedRectangle(cornerRadius: 26)
                    .stroke(MomentColor.hairline, lineWidth: 1)
            )
    }

    // MARK: - 히스토리 진입 힌트

    private var historyHint: some View {
        Button {
            send(.spaceCardTapped)
        } label: {
            Text("지난 순간 모아보기")
                .font(.footnote.weight(.medium))
                .foregroundColor(MomentColor.ink)
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, 10)
                .background(MomentColor.surfaceSoft)
                .clipShape(Capsule())
                .overlay(Capsule().stroke(MomentColor.surfaceStroke, lineWidth: 1))
        }
        .buttonStyle(MomentPressStyle())
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

#Preview("홈 — 텍스트 모먼트") {
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
            text: "오늘 하루도 수고했어, 저녁에 산책 어때? 🌙",
            createdAt: Date().addingTimeInterval(-3600)
        )
        return s
    }()
    HomeView(state: state, send: { _ in })
}

#Preview("홈 — 사진 모먼트") {
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
            imageURL: URL(string: "https://example.com/sunset.jpg"),
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
