import Foundation
import Testing
@testable import AuthFeature

@Test("이메일 로그인은 형식이 갖춰져야 제출 가능하다")
func emailLoginValidation() {
    var state = AuthFeature.State()
    state.mode = .emailLogin
    state.email = "a@b.com"
    state.password = "short"
    #expect(state.canSubmitEmail == false)  // 비밀번호 8자 미만

    state.password = "password123"
    #expect(state.canSubmitEmail == true)
}

@Test("가입 모드는 닉네임 2자 이상을 요구한다")
func signupRequiresNickname() {
    var state = AuthFeature.State()
    state.mode = .emailSignup
    state.email = "a@b.com"
    state.password = "password123"
    state.nickname = "동"
    #expect(state.canSubmitEmail == false)

    state.nickname = "동주"
    #expect(state.canSubmitEmail == true)
}

@Test("모드 전환 시 이전 에러가 사라진다")
func modeChangeClearsError() {
    var state = AuthFeature.State()
    state.error = .unknown(code: "X", message: "err")
    _ = AuthFeature().reduce(into: &state, action: .modeChanged(.emailLogin))
    #expect(state.mode == .emailLogin)
    #expect(state.error == nil)
}
