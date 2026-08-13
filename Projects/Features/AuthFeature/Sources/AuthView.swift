import SwiftUI
import MomentUIKit
import AuthenticationServices
import CryptoKit
import Domain

/// 인증 — Final-MVP v2 (Pinterest 레퍼런스 플로우):
/// 웰컴(브랜드 + 버튼 스택) → 로그인 / 회원가입(중앙 타이틀 + 폼) 상호 전환.
/// 비밀번호 재설정은 백엔드 API 준비 전까지 안내 알럿으로 스텁 처리한다.
/// 매크로 없는 TCA 구성에서 모듈 경계를 지키기 위해 store.scope 대신 (state, send) 주입을 사용.
public struct AuthView: View {
    let state: AuthFeature.State
    let send: (AuthFeature.Action) -> Void

    @State private var showsResetNotice = false
    @State private var currentAppleNonce: String?

    public init(state: AuthFeature.State, send: @escaping (AuthFeature.Action) -> Void) {
        self.state = state
        self.send = send
    }

    public var body: some View {
        // GlassMinimal 시안: 웰컴을 루트로 두고 로그인/회원가입을 내비게이션 푸시로 전환 —
        // 시스템 Back 버튼과 엣지 스와이프 백을 그대로 얻는다 (웨이파인딩: 돌아갈 길 보장).
        NavigationStack {
            authBackground { welcomeSection }
                .navigationDestination(isPresented: Binding(
                    get: { state.mode != .apple },
                    set: { if !$0 { send(.modeChanged(.apple)) } }
                )) {
                    authBackground {
                        // 푸시된 화면 안에서 로그인↔가입 전환은 콘텐츠 스왑 (Back은 웰컴으로)
                        if state.mode == .emailLogin {
                            loginSection
                        } else {
                            signupSection
                        }
                    }
                }
        }
        .alert("비밀번호 재설정은 준비 중이에요", isPresented: $showsResetNotice) {
            Button("확인", role: .cancel) {}
        } message: {
            Text("곧 이메일로 재설정 링크를 보내드릴 수 있게 준비하고 있어요.")
        }
        .alert(
            state.error?.errorDescription ?? "로그인에 실패했어요",
            isPresented: Binding(
                get: { state.error != nil },
                set: { if !$0 { send(.dismissError) } }
            )
        ) {
            Button("확인", role: .cancel) {}
        }
    }

    private var isLoading: Bool { state.isLoading }

    /// 인증 화면 CTA 공통 높이 — Apple 버튼과 이메일 버튼이 같은 스택에서 같은 크기로 보이도록 통일.
    private static let ctaHeight: CGFloat = 54

    /// 캔버스 + 오브 배경 공통 래퍼 (웰컴·푸시 화면 동일 배경)
    private func authBackground<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        ZStack {
            MomentColor.canvas.ignoresSafeArea()
            OrbBackground.login().ignoresSafeArea()
            content()
        }
    }

    // MARK: - 웰컴 (브랜드 + 버튼 스택)

    private var welcomeSection: some View {
        VStack(spacing: 0) {
            Spacer()

            // 시안 01: 워드마크는 40pt Bold + tracking -1.2.
            // (displayXL 토큰의 Thin은 크림 톤 시절 값 — 순백 위에서는 획이 흐려진다)
            Text("Moment")
                .font(.system(size: 40, weight: .bold))
                .tracking(-1.2)
                .foregroundColor(MomentColor.ink)

            Text("두 사람만의 소중한 순간을\n함께 기록해보세요")
                .font(MomentTypography.body)
                .foregroundColor(MomentColor.ink.opacity(0.65))
                .multilineTextAlignment(.center)
                .lineSpacing(6)
                .padding(.top, Spacing.md)

            Spacer()

            VStack(spacing: Spacing.sm) {
                appleLoginButton(isGlass: false)

                // 시안 01: 보조 CTA는 그레이 서피스 캡슐 (글래스는 순백 위에서 흐릿하게 뜬다)
                MomentSecondaryPillButton("이메일로 계속하기", minHeight: Self.ctaHeight) {
                    send(.modeChanged(.emailSignup))
                }
                .disabled(isLoading)
            }
            .padding(.horizontal, Spacing.lg)

            modeSwitchLink(prompt: "이미 계정이 있어요?", action: "로그인", target: .emailLogin)
                .padding(.top, Spacing.xl)   // 시안: CTA 스택과 링크 사이 약 50pt
                .padding(.bottom, Spacing.lg)
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

                MomentPillButton(isLoading ? "처리 중…" : "로그인", style: .primary,
                        minHeight: Self.ctaHeight) {
                    send(.emailSubmitTapped)
                }
                .disabled(!state.canSubmitEmail || isLoading)
                .opacity((!state.canSubmitEmail || isLoading) ? 0.6 : 1.0)
                .padding(.top, Spacing.sm)

                orDivider
                    .padding(.vertical, Spacing.md)

                appleLoginButton(isGlass: true)
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

                MomentPillButton(isLoading ? "처리 중…" : "가입하기", style: .primary,
                        minHeight: Self.ctaHeight) {
                    send(.emailSubmitTapped)
                }
                .disabled(!state.canSubmitEmail || isLoading)
                .opacity((!state.canSubmitEmail || isLoading) ? 0.6 : 1.0)
                .padding(.top, Spacing.xl) // 시안: 필드 묶음과 CTA 사이 32pt
            }
            .padding(.horizontal, Spacing.lg)

            Spacer()

            modeSwitchLink(prompt: "이미 계정이 있어요?", action: "로그인", target: .emailLogin)
                .padding(.bottom, Spacing.xl)
        }
    }

    // MARK: - 공용 컴포넌트

    private func appleLoginButton(isGlass: Bool) -> some View {
        // 캡슐은 clipShape가 아니라 버튼 자체의 cornerRadius로 만든다 —
        // 네이티브 버튼을 밖에서 잘라내면 로고·테두리가 깨져 보일 수 있다 (AppleSignInButton 참고)
        AppleSignInButton(
            style: isGlass ? .whiteOutline : .black,
            cornerRadius: Self.ctaHeight / 2
        ) { request in
            let nonce = Self.makeNonce()
            currentAppleNonce = nonce
            request.nonce = Self.sha256(nonce)
            send(.appleSignInTapped)
        } onCompletion: { result in
            handleAppleAuthorization(result)
        }
        .frame(height: Self.ctaHeight)
        .disabled(isLoading)
        .opacity(isLoading ? 0.6 : 1.0)
    }

    private func handleAppleAuthorization(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            guard
                let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
                let identityTokenData = credential.identityToken,
                let authorizationCodeData = credential.authorizationCode,
                let identityToken = String(data: identityTokenData, encoding: .utf8),
                let authorizationCode = String(data: authorizationCodeData, encoding: .utf8),
                let nonce = currentAppleNonce
            else {
                currentAppleNonce = nil
                send(.appleSignInFailed("Apple 인증 정보를 확인할 수 없어요."))
                return
            }

            currentAppleNonce = nil
            send(.appleSignInCompleted(AppleLoginCredential(
                identityToken: identityToken,
                authorizationCode: authorizationCode,
                nonce: nonce
            )))

        case .failure(let error):
            currentAppleNonce = nil
            let nsError = error as NSError
            if nsError.domain == ASAuthorizationError.errorDomain,
               nsError.code == ASAuthorizationError.canceled.rawValue {
                send(.appleSignInCancelled)
            } else {
                send(.appleSignInFailed("Apple 로그인에 실패했어요. 잠시 후 다시 시도해 주세요."))
            }
        }
    }

    private static func makeNonce() -> String {
        UUID().uuidString.replacingOccurrences(of: "-", with: "")
            + UUID().uuidString.replacingOccurrences(of: "-", with: "")
    }

    private static func sha256(_ value: String) -> String {
        SHA256.hash(data: Data(value.utf8)).map { String(format: "%02x", $0) }.joined()
    }

    private func modeSwitchLink(prompt: String, action: String, target: AuthFeature.Mode) -> some View {
        Button {
            send(.modeChanged(target))
        } label: {
            HStack(spacing: 4) {
                Text(prompt)
                    .foregroundColor(MomentColor.ink.opacity(0.55))
                Text(action)
                    .fontWeight(.bold)
                    .foregroundColor(MomentColor.ink.opacity(0.95))
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
