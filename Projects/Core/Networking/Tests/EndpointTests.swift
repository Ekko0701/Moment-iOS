import Foundation
import Testing
@testable import Networking

@Test("이메일 로그인 엔드포인트는 서버 계약 경로를 사용한다")
func emailLoginEndpoint() {
    let endpoint = AuthEndpoints.emailLogin(email: "a@b.com", password: "password123")
    #expect(endpoint.path == "/v1/auth/email/login")
    #expect(endpoint.method == .post)
    #expect(endpoint.requiresAuth == false)
}

@Test("리프레시 엔드포인트는 인증 없이 호출된다")
func refreshEndpoint() {
    let endpoint = AuthEndpoints.refresh(refreshToken: "token")
    #expect(endpoint.path == "/v1/auth/refresh")
    #expect(endpoint.requiresAuth == false)
}
