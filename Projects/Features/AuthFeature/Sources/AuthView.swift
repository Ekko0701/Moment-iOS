import SwiftUI
import MomentUIKit
import UIKit

/// 인증 — Final-MVP v2 (Pinterest 레퍼런스 플로우):
/// 웰컴(브랜드 + 버튼 스택) → 로그인 / 회원가입(중앙 타이틀 + 폼) 상호 전환.
/// 비밀번호 재설정은 백엔드 API 준비 전까지 안내 알럿으로 스텁 처리한다.
/// 매크로 없는 TCA 구성에서 모듈 경계를 지키기 위해 store.scope 대신 (state, send) 주입을 사용.
public struct AuthView: View {
    let state: AuthFeature.State
    let send: (AuthFeature.Action) -> Void

    @State private var showsResetNotice = false

    public init(state: AuthFeature.State, send: @escaping (AuthFeature.Action) -> Void) {
        self.state = state
        self.send = send
    }

    public var body: some View {
        ZStack {
            MomentColor.canvas.ignoresSafeArea()
            OrbBackground.login().ignoresSafeArea()

            VStack(spacing: 0) {
                if let error = state.error {
                    errorBanner(error.errorDescription ?? "로그인에 실패했어요")
                        .padding(.horizontal, Spacing.lg)
                        .padding(.top, Spacing.md)
                }

                switch state.mode {
                case .apple:
                    welcomeSection
                case .emailLogin:
                    loginSection
                case .emailSignup:
                    signupSection
                }
            }
        }
        .alert("비밀번호 재설정은 준비 중이에요", isPresented: $showsResetNotice) {
            Button("확인", role: .cancel) {}
        } message: {
            Text("곧 이메일로 재설정 링크를 보내드릴 수 있게 준비하고 있어요.")
        }
    }

    private var isLoading: Bool { state.isLoading }

    // MARK: - 웰컴 (브랜드 + 버튼 스택)

    private var welcomeSection: some View {
        VStack(spacing: 0) {
            Spacer()

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

            VStack(spacing: Spacing.sm) {
                appleLoginButton(title: isLoading ? "로그인 중…" : " Apple로 시작하기")

                MomentGlassPillButton("✉ 이메일로 시작하기") {
                    send(.modeChanged(.emailSignup))
                }
                .disabled(isLoading)
            }
            .padding(.horizontal, Spacing.lg)

            modeSwitchLink(prompt: "이미 계정이 있어요?", action: "로그인", target: .emailLogin)
                .padding(.top, Spacing.lg)
                .padding(.bottom, Spacing.xl)
        }
    }

    // MARK: - 로그인

    private var loginSection: some View {
        VStack(spacing: 0) {
            Text("로그인")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(MomentColor.ink)
                .padding(.top, Spacing.xxl)
                .padding(.bottom, Spacing.xl)

            VStack(spacing: Spacing.sm) {
                MomentTextField("이메일", text: Binding(
                    get: { state.email },
                    set: { send(.emailChanged($0)) }
                ), disablesAutocapitalization: true)

                MomentTextField("비밀번호", text: Binding(
                    get: { state.password },
                    set: { send(.passwordChanged($0)) }
                ), isSecure: true, disablesAutocapitalization: true)

                Button("비밀번호를 잊으셨나요?") {
                    showsResetNotice = true
                }
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(MomentColor.ink.opacity(0.6))
                .padding(.top, Spacing.xs)

                MomentPillButton(isLoading ? "처리 중…" : "로그인", style: .primary) {
                    send(.emailSubmitTapped)
                }
                .disabled(!state.canSubmitEmail || isLoading)
                .opacity((!state.canSubmitEmail || isLoading) ? 0.6 : 1.0)
                .padding(.top, Spacing.sm)

                orDivider
                    .padding(.vertical, Spacing.md)

                appleLoginButton(title: " Apple로 계속하기", isGlass: true)
            }
            .padding(.horizontal, Spacing.lg)

            Spacer()

            modeSwitchLink(prompt: "계정이 없으세요?", action: "가입하기", target: .emailSignup)
                .padding(.bottom, Spacing.xl)
        }
    }

    // MARK: - 회원가입

    private var signupSection: some View {
        VStack(spacing: 0) {
            Text("회원가입")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(MomentColor.ink)
                .padding(.top, Spacing.xxl)
                .padding(.bottom, Spacing.xl)

            VStack(spacing: Spacing.sm) {
                MomentTextField("이메일", text: Binding(
                    get: { state.email },
                    set: { send(.emailChanged($0)) }
                ), disablesAutocapitalization: true)

                MomentTextField("비밀번호 (8자 이상)", text: Binding(
                    get: { state.password },
                    set: { send(.passwordChanged($0)) }
                ), isSecure: true, disablesAutocapitalization: true)

                MomentTextField("닉네임 (2~12자)", text: Binding(
                    get: { state.nickname },
                    set: { send(.nicknameChanged($0)) }
                ))

                MomentPillButton(isLoading ? "처리 중…" : "가입하기", style: .primary) {
                    send(.emailSubmitTapped)
                }
                .disabled(!state.canSubmitEmail || isLoading)
                .opacity((!state.canSubmitEmail || isLoading) ? 0.6 : 1.0)
                .padding(.top, Spacing.sm)
            }
            .padding(.horizontal, Spacing.lg)

            Spacer()

            modeSwitchLink(prompt: "이미 계정이 있어요?", action: "로그인", target: .emailLogin)
                .padding(.bottom, Spacing.xl)
        }
    }

    // MARK: - 공용 컴포넌트

    private func appleLoginButton(title: String, isGlass: Bool = false) -> some View {
        Group {
            if isGlass {
                MomentGlassPillButton(title) { performAppleLogin() }
            } else {
                MomentPillButton(title, style: .primary) { performAppleLogin() }
            }
        }
        .disabled(isLoading)
        .opacity(isLoading ? 0.6 : 1.0)
    }

    private func performAppleLogin() {
        guard !isLoading else { return }
        let deviceId = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
        send(.appleSignInCompleted(identityToken: "dev-\(deviceId)"))
    }

    private func modeSwitchLink(prompt: String, action: String, target: AuthFeature.Mode) -> some View {
        Button {
            send(.modeChanged(target))
        } label: {
            HStack(spacing: 4) {
                Text(prompt)
                    .foregroundColor(MomentColor.ink.opacity(0.65))
                Text(action)
                    .fontWeight(.bold)
                    .foregroundColor(MomentColor.ink)
            }
            .font(.system(size: 13))
        }
        .buttonStyle(.plain)
    }

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
}

// MARK: - Xcode Previews

#Preview("웰컴") {
    AuthView(state: AuthFeature.State(), send: { _ in })
}

#Preview("이메일 로그인") {
    let state: AuthFeature.State = {
        var s = AuthFeature.State()
        s.mode = .emailLogin
        return s
    }()
    AuthView(state: state, send: { _ in })
}

#Preview("회원가입") {
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

#Preview("에러 배너") {
    let state: AuthFeature.State = {
        var s = AuthFeature.State()
        s.mode = .emailLogin
        s.error = .unknown(code: "UNAUTHORIZED", message: "이메일 또는 비밀번호가 올바르지 않아요.")
        return s
    }()
    AuthView(state: state, send: { _ in })
}
