import SwiftUI
import Domain
import MomentUIKit
import UIKit

// 매크로 없는 TCA 구성에서 모듈 경계를 지키기 위해 store.scope 대신 (state, send) 주입을 사용
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

            VStack(spacing: Spacing.lg) {
                // Error banner
                if let error = state.error {
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        HStack {
                            VStack(alignment: .leading, spacing: Spacing.xs) {
                                Text(error.errorDescription ?? "오류가 발생했습니다")
                                    .font(MomentTypography.body)
                                    .foregroundColor(MomentColor.ink)
                            }
                            Spacer()
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(MomentColor.ink)
                                .onTapGesture {
                                    send(.dismissError)
                                }
                        }
                        .padding(Spacing.md)
                        .background(MomentColor.blockCoral.opacity(0.4))
                        .cornerRadius(Spacing.Radius.sm)
                    }
                    .padding(.horizontal, Spacing.lg)
                }

                // Loading indicator
                if state.isLoading {
                    ProgressView()
                        .tint(MomentColor.ink)
                        .padding(.vertical, Spacing.lg)
                }

                // Issue code section
                EyebrowText("초대 코드")
                    .padding(.top, Spacing.lg)

                Text("상대방을 초대해 보세요")
                    .font(MomentTypography.headline)
                    .foregroundColor(MomentColor.ink)

                Spacer()
                    .frame(height: Spacing.md)

                ColorBlock(color: .lime) {
                    VStack(alignment: .center, spacing: Spacing.md) {
                        if let code = state.issuedCode {
                            Text(code)
                                .font(MomentTypography.displayLG)
                                .tracking(-0.9)
                                .foregroundColor(MomentColor.ink)
                                .textSelection(.enabled)

                            Text("24시간 동안 유효합니다")
                                .font(MomentTypography.caption)
                                .tracking(0.8)
                                .foregroundColor(MomentColor.ink.opacity(0.6))

                            MomentIconCircleButton(systemName: "square.on.square") {
                                UIPasteboard.general.string = code
                            }
                            .padding(.top, Spacing.sm)
                        } else {
                            Text("코드를 발급해 보세요")
                                .font(MomentTypography.body)
                                .foregroundColor(MomentColor.ink)
                        }
                    }
                }
                .padding(.horizontal, Spacing.lg)

                if state.issuedCode == nil {
                    MomentPillButton("새 코드 발급", style: .primary) {
                        send(.issueCodeTapped)
                    }
                    .padding(.horizontal, Spacing.lg)
                }

                Spacer()

                // Send/receive invitations
                EyebrowText("상대방 초대하기")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, Spacing.lg)

                VStack(spacing: Spacing.md) {
                    MomentTextField("초대 코드 입력", text: Binding(
                        get: { state.codeInput },
                        set: { send(.codeInputChanged($0)) }
                    ))
                    .padding(.horizontal, Spacing.lg)

                    MomentPillButton("연결 요청 보내기", style: .primary) {
                        send(.submitCodeTapped)
                    }
                    .padding(.horizontal, Spacing.lg)
                }

                // Show pending sent invitations
                if state.sentInvitations.contains(where: { $0.status == .pending }) {
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("요청을 보냈어요 — 상대방의 수락을 기다리는 중")
                            .font(MomentTypography.caption)
                            .tracking(0.8)
                            .foregroundColor(MomentColor.ink.opacity(0.6))
                    }
                    .padding(.horizontal, Spacing.lg)
                }

                // Received invitations
                if !state.receivedInvitations.isEmpty {
                    EyebrowText("받은 초대")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, Spacing.lg)

                    VStack(spacing: Spacing.md) {
                        ForEach(state.receivedInvitations.filter { $0.status == .pending }, id: \.id) { invitation in
                            HStack(spacing: Spacing.md) {
                                VStack(alignment: .leading, spacing: Spacing.xs) {
                                    Text(invitation.counterpart.nickname)
                                        .font(MomentTypography.body)
                                        .foregroundColor(MomentColor.ink)

                                    Text("@\(invitation.counterpart.handle)")
                                        .font(MomentTypography.caption)
                                        .tracking(0.8)
                                        .foregroundColor(MomentColor.ink.opacity(0.6))
                                }

                                Spacer()

                                HStack(spacing: Spacing.sm) {
                                    MomentPillButton("수락", style: .primary) {
                                        send(.respondTapped(id: invitation.id, action: .accept))
                                    }
                                    .frame(maxWidth: .infinity)

                                    MomentSecondaryPillButton("거절") {
                                        send(.respondTapped(id: invitation.id, action: .decline))
                                    }
                                    .frame(maxWidth: .infinity)
                                }
                            }
                            .padding(Spacing.md)
                            .background(MomentColor.surfaceSoft)
                            .cornerRadius(Spacing.Radius.sm)
                        }
                    }
                    .padding(.horizontal, Spacing.lg)
                }

                // Refresh button — 초대 목록 갱신 + 스페이스 재확인(상대 수락 시 메인 전환)
                Button(action: onRefresh) {
                    Text("연결 상태 새로고침")
                        .font(MomentTypography.bodySM)
                        .foregroundColor(MomentColor.ink)
                        .underline()
                }
                .padding(.vertical, Spacing.md)

                Spacer()
                    .frame(height: Spacing.xl)
            }
            .padding(.vertical, Spacing.lg)
        }
        .onAppear {
            send(.onAppear)
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
