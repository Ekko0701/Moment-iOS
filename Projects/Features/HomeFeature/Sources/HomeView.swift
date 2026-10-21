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
    /// 당겨서 새로고침. 앱 셸이 목록을 다 받을 때까지 기다려, 스피너가 로딩과 함께 사라지게 한다
    let refresh: (() async -> Void)?

    public init(
        state: HomeFeature.State,
        send: @escaping (HomeFeature.Action) -> Void,
        refresh: (() async -> Void)? = nil
    ) {
        self.state = state
        self.send = send
        self.refresh = refresh
    }

    public var body: some View {
        ZStack {
            // GlassMinimal 시안: 홈은 순백 캔버스 — 사진(히어로)이 유일한 색이 되도록 오브 제거
            MomentColor.canvas.ignoresSafeArea()

            ScrollView {
                VStack(spacing: Spacing.xl) {
                    ForEach(state.spaces) { space in
                        spaceSection(space)
                    }
                    PendingJoinRequestsView(requests: state.pendingJoinRequests) {
                        send(.cancelJoinRequestTapped($0))
                    }
                    groupActions
                }
                .padding(.vertical, Spacing.lg)
            }
            .refreshable {
                if let refresh {
                    await refresh()
                } else {
                    send(.refreshPulled)
                }
            }
        }
        .onAppear { send(.onAppear) }
        // 내비는 앱 정체성만 — 관계 정보는 카드 위 라벨이 담당한다
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Moment")
                    .font(.subheadline.weight(.bold))
                    .foregroundColor(MomentColor.ink)
            }
        }
    }

    // MARK: - 스페이스 한 장 (라벨 + 히어로 카드 + 진입 힌트)

    private func spaceSection(_ space: Space) -> some View {
        VStack(spacing: Spacing.sm) {
            spaceLabel(space)

            momentContent(space)
                .padding(.horizontal, Spacing.lg)
                // 비동기 모먼트가 도착할 때 스냅 교체 대신 부드럽게 안착
                .animation(.easeOut(duration: 0.25), value: space.latestMoment)

            enterHint(space)
        }
    }

    // 카드·진입 버튼이 어느 스페이스를 여는지 VoiceOver가 알 수 있게 한다
    private func openLabel(_ space: Space) -> String {
        "\(spaceTitle(space)) 열기"
    }

    private func momentAccessibilityText(_ moment: Moment) -> String {
        var parts = ["\(moment.author.nickname)님의 모먼트"]
        if moment.imageURL != nil { parts.append("사진") }
        if let text = moment.text, !text.isEmpty { parts.append(text) }
        return parts.joined(separator: ", ")
    }

    private func spaceLabel(_ space: Space) -> some View {
        HStack(spacing: 6) {
            if space.isGroup {
                Image(systemName: "person.3.fill")
                    .font(.caption2)
                    .foregroundColor(MomentColor.ink.opacity(0.7))
                    .accessibilityHidden(true)
            } else {
                Circle()
                    .fill(MomentColor.orbCoral.opacity(0.75))
                    .frame(width: 18, height: 18)
                    .accessibilityHidden(true)
            }

            Text(spaceTitle(space))
                .font(.footnote.weight(.medium))
                .foregroundColor(MomentColor.ink)

            if space.isGroup {
                Text("\(space.memberCount)명")
                    .font(.caption.weight(.medium))
                    .foregroundColor(MomentColor.ink.opacity(0.55))
                if space.pendingJoinRequestCount > 0 {
                    Text("참여 요청 \(space.pendingJoinRequestCount)")
                        .font(.caption2.weight(.semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(MomentColor.accent)
                        .clipShape(Capsule())
                }
            } else {
                Text("D+\(state.daysTogether(in: space))")
                    .font(.caption.weight(.medium))
                    .foregroundColor(MomentColor.accent)
            }
        }
    }

    private func spaceTitle(_ space: Space) -> String {
        // 사용자가 붙인 이름이 우선 — 1:1은 없으면 상대 이름 기반 폴백
        if let name = space.name, !name.isEmpty {
            return name
        }
        if let partner = state.partner(in: space) {
            return "\(partner.nickname)님과의 스페이스"
        }
        return space.isGroup ? "그룹" : "우리 둘의 스페이스"
    }

    // MARK: - 모먼트 콘텐츠 (사진 / 텍스트 / 빈 상태 분기)

    @ViewBuilder
    private func momentContent(_ space: Space) -> some View {
        if let moment = space.latestMoment {
            if moment.imageURL != nil {
                photoMomentCard(moment, spaceId: space.id)
                    .accessibilityLabel(momentAccessibilityText(moment))
                    .accessibilityHint(openLabel(space))
            } else {
                textMomentCard(moment, spaceId: space.id)
                    .accessibilityLabel(momentAccessibilityText(moment))
                    .accessibilityHint(openLabel(space))
            }
        } else if state.isRefreshing && state.spaces.isEmpty {
            glassCard {
                ProgressView()
                    .tint(MomentColor.ink)
                    .padding(.vertical, Spacing.md)
                    .accessibilityLabel("불러오는 중")
            }
        } else {
            Button {
                send(.spaceTapped(space.id))
            } label: {
                glassCard {
                    Text(space.isGroup ? "아직 다른 멤버의 모먼트가 없어요" : "아직 상대방의 모먼트가 없어요")
                        .font(MomentTypography.body)
                        .foregroundColor(MomentColor.ink.opacity(0.65))
                }
            }
            .buttonStyle(MomentPressStyle(scale: 0.98))
            .accessibilityHint(openLabel(space))
        }
    }

    // MARK: - 사진 모먼트 카드 (Locket 스타일 대형 카드)

    private func photoMomentCard(_ moment: Moment, spaceId: UUID) -> some View {
        Button {
            send(.spaceTapped(spaceId))
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
            // 모든 모먼트가 같은 자리·같은 크기 — 사진도 텍스트·빈 상태와 동일한 정사각형.
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

    // MARK: - 텍스트 모먼트 카드

    private func textMomentCard(_ moment: Moment, spaceId: UUID) -> some View {
        Button {
            send(.spaceTapped(spaceId))
        } label: {
            glassCard {
                // 문장이 정중앙의 주인공 — 큰 타이포(Dynamic Type 대응), 여유로운 행간
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

    // 밝은 서피스 위 발신자 칩 — 그레이 캡슐
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

    // 정사각형 서피스 카드 공통 래퍼 — 텍스트 모먼트·로딩·빈 상태가 히어로 자리에서 1:1 형태를 공유한다
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

    // MARK: - 진입 힌트 (카드 바로 아래)

    private func enterHint(_ space: Space) -> some View {
        Button {
            send(.spaceTapped(space.id))
        } label: {
            Text(space.isGroup ? "그룹 들어가기" : "지난 순간 모아보기")
                .font(.footnote.weight(.medium))
                .foregroundColor(MomentColor.ink)
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, 10)
                .background(MomentColor.surfaceSoft)
                .clipShape(Capsule())
                .overlay(Capsule().stroke(MomentColor.surfaceStroke, lineWidth: 1))
        }
        .buttonStyle(MomentPressStyle())
        .accessibilityLabel(openLabel(space))
    }

    // MARK: - 그룹·연결 진입

    private var groupActions: some View {
        VStack(spacing: Spacing.sm) {
            if state.oneToOneSpace == nil {
                MomentSecondaryPillButton("1:1로 연결하기") { send(.connectTapped) }
            }
            HStack(spacing: Spacing.sm) {
                MomentSecondaryPillButton("그룹 만들기") { send(.createGroupTapped) }
                MomentSecondaryPillButton("코드로 참여") { send(.joinGroupTapped) }
            }
        }
        .padding(.horizontal, Spacing.lg)
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

private let previewMe = UserProfile(id: UUID(), handle: "moment_5678", nickname: "동주")
private let previewPartner = UserProfile(id: UUID(), handle: "moment_1234", nickname: "지은")

#Preview("홈 — 1:1 텍스트 + 그룹 사진") {
    let state: HomeFeature.State = {
        var s = HomeFeature.State()
        s.currentUser = previewMe
        s.spaces = [
            Space(
                id: UUID(), type: .oneToOne, maxMembers: 2, status: "ACTIVE",
                members: [previewMe, previewPartner],
                createdAt: Calendar.current.date(byAdding: .day, value: -99, to: Date()) ?? Date(),
                latestMoment: Moment(id: UUID(), spaceId: UUID(), author: previewPartner,
                                     text: "오늘 하루도 수고했어, 저녁에 산책 어때? 🌙",
                                     createdAt: Date().addingTimeInterval(-3600))
            ),
            Space(
                id: UUID(), type: .group, name: "주말 산책", maxMembers: 6, status: "ACTIVE",
                members: [previewMe, previewPartner], createdAt: Date(), myRole: .owner,
                latestMoment: Moment(id: UUID(), spaceId: UUID(), author: previewPartner,
                                     imageURL: URL(string: "https://example.com/sunset.jpg"),
                                     text: "퇴근길 하늘 🌇", createdAt: Date().addingTimeInterval(-600))
            ),
        ]
        return s
    }()
    HomeView(state: state, send: { _ in })
}

#Preview("홈 — 그룹만, 모먼트 없음") {
    let state: HomeFeature.State = {
        var s = HomeFeature.State()
        s.currentUser = previewMe
        s.spaces = [
            Space(id: UUID(), type: .group, name: "가족", maxMembers: 6, status: "ACTIVE",
                  members: [previewMe], createdAt: Date(), myRole: .owner)
        ]
        return s
    }()
    HomeView(state: state, send: { _ in })
}
