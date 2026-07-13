import SwiftUI
import MomentUIKit
import UIKit

// 매크로 없는 TCA 구성에서 모듈 경계를 지키기 위해 store.scope 대신 (state, send) 주입을 사용
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

            VStack(spacing: Spacing.lg) {
                EyebrowText("MOMENT — 우리 둘의 순간")
                    .padding(.top, Spacing.xxl)

                Text("Moment")
                    .font(MomentTypography.displayXL)
                    .tracking(-1.6)
                    .foregroundColor(MomentColor.ink)

                Text("두 사람만의 소중한 순간을 함께 기록해보세요")
                    .font(MomentTypography.subhead)
                    .foregroundColor(MomentColor.ink)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.xl)

                // 에러 배너
                if let error = state.error {
                    HStack {
                        Text(error.errorDescription ?? "로그인에 실패했어요")
                            .font(MomentTypography.body)
                            .foregroundColor(MomentColor.ink)
                        Spacer()
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(MomentColor.ink)
                            .onTapGesture { send(.dismissError) }
                    }
                    .padding(Spacing.md)
                    .background(MomentColor.blockCoral.opacity(0.4))
                    .cornerRadius(Spacing.Radius.sm)
                    .padding(.horizontal, Spacing.lg)
                }

                Spacer()

                if state.mode == .apple {
                    appleAuthSection(isLoading: isLoading)
                } else {
                    emailAuthSection(isLoading: isLoading)
                }

                Spacer()
                    .frame(height: Spacing.lg)
            }
            .padding(.vertical, Spacing.lg)
        }
    }

    @ViewBuilder
    private func appleAuthSection(isLoading: Bool) -> some View {
        // 포스터 카피 — CTA와 중복되지 않는 서비스 서사 (여백 넉넉히, 문서의 poster 원칙)
        ColorBlock(color: .lilac) {
            VStack(alignment: .center, spacing: Spacing.sm) {
                Text("사진 한 장, 짧은 글 하나로")
                    .font(MomentTypography.subhead)
                    .foregroundColor(MomentColor.ink)
                    .multilineTextAlignment(.center)
                Text("서로의 홈 화면에 스며들어요")
                    .font(MomentTypography.headline)
                    .foregroundColor(MomentColor.ink)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.xl)
        }
        .padding(.horizontal, Spacing.lg)

        Spacer()

        MomentPillButton(isLoading ? "로그인 중…" : "Apple로 시작하기", style: .primary) {
            guard !isLoading else { return }
            let deviceId = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
            send(.appleSignInCompleted(identityToken: "dev-\(deviceId)"))
        }
        .disabled(isLoading)
        .opacity(isLoading ? 0.6 : 1.0)
        .padding(.horizontal, Spacing.lg)

        Button("이메일로 계속하기") {
            send(.modeChanged(.emailLogin))
        }
        .font(MomentTypography.bodySM)
        .foregroundColor(MomentColor.ink)
        .padding(.top, Spacing.xs)
    }

    @ViewBuilder
    private func emailAuthSection(isLoading: Bool) -> some View {
        let isSignup = state.mode == .emailSignup
        let canSubmit = state.canSubmitEmail

        VStack(spacing: Spacing.md) {
            EyebrowText(isSignup ? "이메일로 가입" : "이메일로 로그인")
                .frame(maxWidth: .infinity, alignment: .leading)

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
