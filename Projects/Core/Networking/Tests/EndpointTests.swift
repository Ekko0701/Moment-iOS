import Foundation
import Testing
import Domain
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

private func encodedBody(_ endpoint: Endpoint) throws -> [String: Any] {
    let body = try #require(endpoint.body)
    let data = try JSONEncoder().encode(body)
    return try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])
}

@Test("모먼트 생성 요청은 사진 위 글씨의 위치와 색을 함께 보낸다")
func createMomentSendsTextStyle() throws {
    let endpoint = MomentEndpoints.createMoment(
        spaceId: "s", imageUrl: "moments/u/a.jpg", text: "노을", textPosition: "BOTTOM", textColor: "BUTTER")
    let body = try encodedBody(endpoint)
    #expect(body["textPosition"] as? String == "BOTTOM")
    #expect(body["textColor"] as? String == "BUTTER")
}

@Test("글만 보내는 모먼트 생성 요청에는 위치와 색 키가 없다")
func createMomentOmitsTextStyleWhenAbsent() throws {
    let body = try encodedBody(MomentEndpoints.createMoment(spaceId: "s", imageUrl: nil, text: "글만"))
    #expect(body["textPosition"] == nil)
    #expect(body["textColor"] == nil)
    #expect(body["imageUrl"] == nil)
}

private func momentJSON(extra: String) -> Data {
    Data("""
    {"id":"\(UUID().uuidString)","spaceId":"\(UUID().uuidString)",
     "author":{"userId":"\(UUID().uuidString)","handle":"b","nickname":"비비","profileImageUrl":null},
     "imageUrl":"https://example.com/a.jpg","text":"노을",\(extra)
     "createdAtMs":1700000000000,"reactions":[],"myReaction":null}
    """.utf8)
}

@Test("모먼트 응답의 글씨 위치와 색을 읽는다")
func momentDTODecodesTextStyle() throws {
    let dto = try JSONDecoder().decode(
        MomentDTO.self, from: momentJSON(extra: #""textPosition":"BOTTOM","textColor":"LILAC","#))
    let moment = dto.toDomainModel()
    #expect(moment.textStyle?.position == .bottom)
    #expect(moment.textStyle?.color == .lilac)
}

@Test("위치·색이 없는 예전 응답과 모르는 색은 기본값으로 읽는다")
func momentDTOTextStyleFallbacks() throws {
    let legacy = try JSONDecoder().decode(MomentDTO.self, from: momentJSON(extra: "")).toDomainModel()
    #expect(legacy.textStyle == nil)
    #expect(legacy.photoTextStyle.position == .top)

    let unknown = try JSONDecoder().decode(
        MomentDTO.self, from: momentJSON(extra: #""textPosition":"TOP","textColor":"NEON","#)).toDomainModel()
    #expect(unknown.textStyle?.color == .white)
}
