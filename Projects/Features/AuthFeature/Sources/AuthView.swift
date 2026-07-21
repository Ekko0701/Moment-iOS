import SwiftUI
import MomentUIKit
import UIKit

/// 로그인 — Final-MVP: 타이틀/포스터 없이 중앙 워드마크 + 서브타이틀, 하단 다크 필 CTA.
/// 매크로 없는 TCA 구성에서 모듈 경계를 지키기 위해 store.scope 대신 (state, send) 주입을 사용.
public struct AuthView: View {
    let state: AuthFeature.State
    let send: (AuthFeature.Action) -> Void

    public init(state: AuthFeature.State, send: @escaping (AuthFeature.Action) -> Void) {
        self.state = state
        self.send = send
    }

    public var body: some View {
        let isLoading = state.isLoading

        ZStack {
            MomentColor.canvas.ignoresSafeArea()
            OrbBackground.login().ignoresSafeArea()

            VStack(spacing: 0) {
                // 에러 배너
                if let error = state.error {
                    errorBanner(error.errorDescription ?? "로그인에 실패했어요")
                        .padding(.horizontal, Spacing.lg)
                        .padding(.top, Spacing.md)
                }

                Spacer()

                // 중앙 워드마크
                Text("Moment")
                    .font(MomentTypography.displayXL)
                    .tracking(-1.6)
                    .foregroundColor(MomentColor.ink)

                Text("두 사람만의 소중한 순간을\n함께 기록해보세요")
                    .font(MomentTypography.body)
                    .foregroundColor(MomentColor.ink.opacity(0.65))
                    .multilineTextAlignment(.center)
                    .lineSpacing(6)
                    .padding(.top, Spacing.md)

                Spacer()

                if state.mode == .apple {
                    appleAuthSection(isLoading: isLoading)
                } else {
                    emailAuthSection(isLoading: isLoading)
                }
            }
            .padding(.bottom, Spacing.xl)
        }
    }

    private func errorBanner(_ message: String) -> some View {
        HStack {
            Text(message)
                .font(MomentTypography.body)
                .foregroundColor(MomentColor.ink)
            Spacer()
            Image(systemName: "xmark.circle.fill")
                .foregroundColor(MomentColor.ink)
                .onTapGesture { send(.dismissError) }
        }
        .padding(Spacing.md)
        .background(MomentColor.blockCoral.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.6), lineWidth: 1)
        )
    }

    @ViewBuilder
    private func appleAuthSection(isLoading: Bool) -> some View {
        VStack(spacing: Spacing.md) {
            MomentPillButton(isLoading ? "로그인 중…" : " Apple로 시작하기", style: .primary) {
                guard !isLoading else { return }
                let deviceId = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
                send(.appleSignInCompleted(identityToken: "dev-\(deviceId)"))
            }
            .disabled(isLoading)
            .opacity(isLoading ? 0.6 : 1.0)

            Button("이메일로 계속하기") {
                send(.modeChanged(.emailLogin))
            }
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(MomentColor.ink.opacity(0.7))
        }
        .padding(.horizontal, Spacing.lg)
    }

    @ViewBuilder
    private func emailAuthSection(isLoading: Bool) -> some View {
        let isSignup = state.mode == .emailSignup
        let canSubmit = state.canSubmitEmail

        VStack(spacing: Spacing.md) {
            MomentTextField("이메일", text: Binding(
                get: { state.email },
                set: { send(.emailChanged($0)) }
            ), disablesAutocapitalization: true)

            MomentTextField("비밀번호 (8자 이상)", text: Binding(
                get: { state.password },
                set: { send(.passwordChanged($0)) }
            ), isSecure: true, disablesAutocapitalization: true)

            if isSignup {
                MomentTextField("닉네임 (2~12자)", text: Binding(
                    get: { state.nickname },
                    set: { send(.nicknameChanged($0)) }
                ))
            }

            MomentPillButton(isLoading ? "처리 중…" : (isSignup ? "가입하기" : "로그인"),
                             style: .primary) {
                send(.emailSubmitTapped)
            }
            .disabled(!canSubmit || isLoading)
            .opacity((!canSubmit || isLoading) ? 0.6 : 1.0)

            Button(isSignup ? "이미 계정이 있어요 — 로그인" : "계정이 없어요 — 가입하기") {
                send(.modeChanged(isSignup ? .emailLogin : .emailSignup))
            }
            .font(MomentTypography.bodySM)
            .foregroundColor(MomentColor.ink)

            Button("← Apple로 돌아가기") {
                send(.modeChanged(.apple))
            }
            .font(MomentTypography.caption)
            .foregroundColor(MomentColor.ink.opacity(0.6))
            .padding(.top, Spacing.xs)
        }
        .padding(.horizontal, Spacing.lg)
    }
}

// MARK: - Xcode Previews

#Preview("로그인 — Apple 기본") {
    AuthView(state: AuthFeature.State(), send: { _ in })
}

#Preview("로그인 — 이메일 가입 폼") {
    let state: AuthFeature.State = {
        var s = AuthFeature.State()
        s.mode = .emailSignup
        s.email = "moment@example.com"
        s.password = "password123"
        s.nickname = "동주"
        return s
    }()
    AuthView(state: state, send: { _ in })
}

#Preview("로그인 — 에러 배너") {
    let state: AuthFeature.State = {
        var s = AuthFeature.State()
        s.mode = .emailLogin
        s.error = .unknown(code: "UNAUTHORIZED", message: "이메일 또는 비밀번호가 올바르지 않아요.")
        return s
    }()
    AuthView(state: state, send: { _ in })
}
