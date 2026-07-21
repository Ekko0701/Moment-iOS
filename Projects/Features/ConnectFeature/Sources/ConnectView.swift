import SwiftUI
import Domain
import MomentUIKit
import UIKit

/// 연결 — Final-MVP: 내 초대 코드 글래스 카드 + "또는" 구분선 + 코드 입력 + 다크 필 CTA.
/// 매크로 없는 TCA 구성에서 모듈 경계를 지키기 위해 store.scope 대신 (state, send) 주입을 사용.
public struct ConnectView: View {
    let state: ConnectFeature.State
    let send: (ConnectFeature.Action) -> Void
    let onRefresh: () -> Void

    public init(
        state: ConnectFeature.State,
        send: @escaping (ConnectFeature.Action) -> Void,
        onRefresh: @escaping () -> Void
    ) {
        self.state = state
        self.send = send
        self.onRefresh = onRefresh
    }

    public var body: some View {
        ZStack {
            MomentColor.canvas.ignoresSafeArea()
            OrbBackground.connect().ignoresSafeArea()

            ScrollView {
                VStack(spacing: Spacing.lg) {
                    if state.isLoading {
                        ProgressView()
                            .tint(MomentColor.ink)
                            .padding(.vertical, Spacing.sm)
                    }

                    // 내 초대 코드 카드
                    myCodeCard
                        .padding(.top, Spacing.xl)

                    // "또는" 구분선
                    orDivider
                        .padding(.vertical, Spacing.xs)

                    // 코드 입력 + 연결 요청
                    VStack(spacing: Spacing.sm) {
                        MomentTextField("초대 코드 입력", text: Binding(
                            get: { state.codeInput },
                            set: { send(.codeInputChanged($0)) }
                        ), disablesAutocapitalization: true)

                        Text("상대에게 받은 6자리 코드를 입력하면 연결 요청을 보낼 수 있어요")
                            .font(.system(size: 12))
                            .foregroundColor(MomentColor.ink.opacity(0.5))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, Spacing.xxs)

                        MomentPillButton("연결 요청 보내기", style: .primary) {
                            send(.submitCodeTapped)
                        }
                        .padding(.top, Spacing.xs)
                    }

                    // 보낸 요청 대기 안내
                    if state.sentInvitations.contains(where: { $0.status == .pending }) {
                        Text("요청을 보냈어요 — 상대방의 수락을 기다리는 중")
                            .font(.system(size: 12, design: .default))
                            .tracking(0.4)
                            .foregroundColor(MomentColor.ink.opacity(0.55))
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    // 받은 초대
                    if !state.receivedInvitations.isEmpty {
                        receivedInvitations
                    }

                    // 새로고침 — 초대 목록 갱신 + 스페이스 재확인(상대 수락 시 메인 전환)
                    Button(action: onRefresh) {
                        Text("연결 상태 새로고침")
                            .font(MomentTypography.bodySM)
                            .foregroundColor(MomentColor.ink.opacity(0.7))
                            .underline()
                    }
                    .padding(.vertical, Spacing.md)
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.vertical, Spacing.lg)
            }
        }
        .onAppear {
            send(.onAppear)
        }
        .alert(
            state.error?.errorDescription ?? "오류가 발생했어요",
            isPresented: Binding(
                get: { state.error != nil },
                set: { if !$0 { send(.dismissError) } }
            )
        ) {
            Button("확인", role: .cancel) {}
        }
    }

    // MARK: - 내 초대 코드 카드

    private var myCodeCard: some View {
        SurfaceCard {
            VStack(spacing: Spacing.sm) {
                Text("MY CODE")
                    .font(.system(size: 11, design: .default))
                    .tracking(1.2)
                    .foregroundColor(MomentColor.ink.opacity(0.5))

                if let code = state.issuedCode {
                    Text(code)
                        .font(.system(size: 40, weight: .bold, design: .default))
                        .tracking(-1)
                        .foregroundColor(MomentColor.ink)
                        .textSelection(.enabled)

                    Text("VALID FOR 24H")
                        .font(.system(size: 11, design: .default))
                        .tracking(1.0)
                        .foregroundColor(MomentColor.ink.opacity(0.5))

                    Button {
                        UIPasteboard.general.string = code
                    } label: {
                        Text("⧉ 코드 복사")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(MomentColor.ink)
                            .padding(.horizontal, Spacing.md)
                            .padding(.vertical, Spacing.xs)
                            .background(MomentColor.ink.opacity(0.07))
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .padding(.top, Spacing.xs)
                } else {
                    Text("상대방에게 전달할 코드를 발급해 보세요")
                        .font(MomentTypography.body)
                        .foregroundColor(MomentColor.ink.opacity(0.7))
                        .padding(.vertical, Spacing.xs)

                    MomentPillButton("새 코드 발급", style: .primary) {
                        send(.issueCodeTapped)
                    }
                    .padding(.horizontal, Spacing.xl)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.lg)
            .padding(.horizontal, Spacing.md)
        }
    }

    // MARK: - "또는" 구분선

    private var orDivider: some View {
        HStack(spacing: Spacing.sm) {
            Rectangle()
                .fill(MomentColor.ink.opacity(0.15))
                .frame(height: 1)
            Text("또는")
                .font(.system(size: 12))
                .foregroundColor(MomentColor.ink.opacity(0.5))
            Rectangle()
                .fill(MomentColor.ink.opacity(0.15))
                .frame(height: 1)
        }
    }

    // MARK: - 받은 초대

    private var receivedInvitations: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("RECEIVED")
                .font(.system(size: 11, design: .default))
                .tracking(1.2)
                .foregroundColor(MomentColor.ink.opacity(0.5))

            ForEach(state.receivedInvitations.filter { $0.status == .pending }, id: \.id) { invitation in
                SurfaceCard {
                    HStack(spacing: Spacing.md) {
                        Circle()
                            .fill(MomentColor.orbCoral.opacity(0.6))
                            .frame(width: 38, height: 38)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(invitation.counterpart.nickname)
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(MomentColor.ink)

                            Text("@\(invitation.counterpart.handle)")
                                .font(.system(size: 11, design: .default))
                                .foregroundColor(MomentColor.ink.opacity(0.55))
                        }

                        Spacer()

                        Button("수락") {
                            send(.respondTapped(id: invitation.id, action: .accept))
                        }
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(MomentColor.inverseInk)
                        .padding(.horizontal, Spacing.md)
                        .padding(.vertical, Spacing.xs)
                        .background(MomentColor.ink)
                        .clipShape(Capsule())

                        Button("거절") {
                            send(.respondTapped(id: invitation.id, action: .decline))
                        }
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(MomentColor.ink)
                        .padding(.horizontal, Spacing.md)
                        .padding(.vertical, Spacing.xs)
                        .background(MomentColor.ink.opacity(0.07))
                        .clipShape(Capsule())
                    }
                    .padding(Spacing.md)
                }
            }
        }
    }

}

// MARK: - Xcode Previews

#Preview("연결 — 코드 발급됨") {
    let state: ConnectFeature.State = {
        var s = ConnectFeature.State()
        s.issuedCode = "YUTLGA"
        return s
    }()
    ConnectView(state: state, send: { _ in }, onRefresh: {})
}

#Preview("연결 — 받은 초대 있음") {
    let state: ConnectFeature.State = {
        var s = ConnectFeature.State()
        s.receivedInvitations = [
            Invitation(
                id: UUID(),
                via: .code,
                status: .pending,
                counterpart: UserProfile(id: UUID(), handle: "moment_1234", nickname: "지은"),
                createdAt: Date()
            )
        ]
        return s
    }()
    ConnectView(state: state, send: { _ in }, onRefresh: {})
}
