import Foundation
import Testing
@testable import CoreKit

@Test("방금 전 시각은 '방금'으로 표기한다")
func justNow() {
    #expect(Date().relativeFormatted == "방금")
}

@Test("과거 시각은 단위별 상대 표기를 따른다", arguments: [
    (-90.0, "1분 전"),
    (-3_700.0, "1시간 전"),
    (-90_000.0, "1일 전"),
])
func pastFormats(offset: Double, expected: String) {
    let date = Date(timeIntervalSinceNow: offset)
    #expect(date.relativeFormatted == expected)
}
