import Foundation
import Testing
@testable import CoreKit

/// 위젯 상태는 앱이 인코딩해 App Group에 쓰고, 위젯 확장이 별도 프로세스에서 디코딩한다.
/// 두 프로세스가 같은 JSON 계약을 공유하므로 라운드트립을 테스트로 고정한다.
/// (imageFileName이 유실되면 위젯이 사진 대신 텍스트 폴백으로 조용히 떨어진다 — F-06)

private func roundTrip(_ state: WidgetMomentState) throws -> WidgetMomentState {
    let data = try JSONEncoder().encode(state)
    return try JSONDecoder().decode(WidgetMomentState.self, from: data)
}

@Test("사진 모먼트 스냅샷이 imageFileName까지 라운드트립된다")
func hasMomentWithImageRoundTrips() throws {
    let momentId = UUID()
    let spaceId = UUID()
    let createdAt = Date(timeIntervalSince1970: 1_757_000_000)
    let snapshot = WidgetMomentSnapshot(
        momentId: momentId,
        spaceId: spaceId,
        authorNickname: "지수",
        text: "노을이 예뻐서 한 장",
        imageFileName: "\(momentId.uuidString).jpg",
        createdAt: createdAt,
        hasImage: true
    )

    let decoded = try roundTrip(.hasMoment(snapshot))

    guard case .hasMoment(let result) = decoded else {
        Issue.record("hasMoment로 디코딩되지 않았다: \(decoded)")
        return
    }
    #expect(result.momentId == momentId)
    #expect(result.spaceId == spaceId)
    #expect(result.authorNickname == "지수")
    #expect(result.text == "노을이 예뻐서 한 장")
    #expect(result.imageFileName == "\(momentId.uuidString).jpg")
    #expect(result.createdAt == createdAt)
    #expect(result.hasImage == true)
}

@Test("사진 없는 모먼트는 imageFileName이 nil로 유지된다 — 위젯이 텍스트 폴백을 고르는 근거")
func textOnlyMomentKeepsNilFileName() throws {
    let snapshot = WidgetMomentSnapshot(
        momentId: UUID(),
        spaceId: UUID(),
        authorNickname: "지수",
        text: "오늘 하루도 수고했어",
        imageFileName: nil,
        createdAt: Date(timeIntervalSince1970: 1_757_000_000),
        hasImage: false
    )

    let decoded = try roundTrip(.hasMoment(snapshot))

    guard case .hasMoment(let result) = decoded else {
        Issue.record("hasMoment로 디코딩되지 않았다: \(decoded)")
        return
    }
    #expect(result.imageFileName == nil)
    #expect(result.hasImage == false)
}

@Test("연결·로그인 상태 케이스도 라운드트립된다", arguments: [
    WidgetMomentState.needLogin,
    WidgetMomentState.needConnect,
    WidgetMomentState.empty,
])
func stateCasesRoundTrip(state: WidgetMomentState) throws {
    let decoded = try roundTrip(state)
    #expect(decoded.isMoment == false)
    // 케이스 식별자가 유지되는지 — 인코딩 결과의 키로 확인한다
    let originalKey = try JSONSerialization.jsonObject(
        with: JSONEncoder().encode(state)) as? [String: Any]
    let decodedKey = try JSONSerialization.jsonObject(
        with: JSONEncoder().encode(decoded)) as? [String: Any]
    #expect(originalKey?.keys.first == decodedKey?.keys.first)
}
