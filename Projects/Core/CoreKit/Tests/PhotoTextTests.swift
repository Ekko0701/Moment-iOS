import Foundation
import Testing
@testable import CoreKit

@Test("위치와 색 이름은 없거나 모르는 값이면 왼쪽 위·흰색")
func photoTextNamesFallBack() {
    #expect(PhotoTextPosition(name: "BOTTOM") == .bottom)
    #expect(PhotoTextPosition(name: nil) == .top)
    #expect(PhotoTextPosition(name: "CENTER") == .top)
    #expect(PhotoTextColor(name: "BUTTER") == .butter)
    #expect(PhotoTextColor(name: nil) == .white)
    #expect(PhotoTextColor(name: "NEON") == .white)
}

@Test("보낸 사람 표시는 글씨 반대쪽 모서리")
func photoTextOppositeCorner() {
    #expect(PhotoTextPosition.top.opposite == .bottom)
    #expect(PhotoTextPosition.bottom.opposite == .top)
}

@Test("글씨 크기는 사진 폭에 비례하고 너무 작거나 크지 않게 맞춘다")
func photoTextMetricsScale() {
    #expect(abs(PhotoTextMetrics(photoWidth: 370).fontSize - 25.9) < 0.01)
    #expect(PhotoTextMetrics(photoWidth: 96).fontSize == 12)
    #expect(PhotoTextMetrics(photoWidth: 1000).fontSize == 30)
    #expect(PhotoTextMetrics(photoWidth: 170, fontSize: 13).fontSize == 13)
}

@Test("위젯 스냅샷은 글씨 위치·색을 보존하고, 그 값이 없는 예전 저장분도 읽는다")
func widgetSnapshotTextStyle() throws {
    let snapshot = WidgetMomentSnapshot(
        momentId: UUID(), spaceId: UUID(), authorNickname: "지은", text: "노을",
        imageFileName: "a.jpg", createdAt: Date(timeIntervalSince1970: 1_757_000_000), hasImage: true,
        textPosition: "BOTTOM", textColor: "PEACH")
    let decoded = try JSONDecoder().decode(WidgetMomentSnapshot.self, from: JSONEncoder().encode(snapshot))
    #expect(decoded.textPosition == "BOTTOM")
    #expect(decoded.textColor == "PEACH")

    var legacy = try #require(
        try JSONSerialization.jsonObject(with: JSONEncoder().encode(snapshot)) as? [String: Any])
    legacy.removeValue(forKey: "textPosition")
    legacy.removeValue(forKey: "textColor")
    let old = try JSONDecoder().decode(
        WidgetMomentSnapshot.self, from: JSONSerialization.data(withJSONObject: legacy))
    #expect(old.textPosition == nil)
    #expect(PhotoTextPosition(name: old.textPosition) == .top)
}
