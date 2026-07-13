import Foundation
import Testing
@testable import ComposeFeature

@Test("빈 입력은 공유할 수 없다")
func emptyCannotSubmit() {
    let state = ComposeFeature.State()
    #expect(state.canSubmit == false)
}

@Test("텍스트가 있으면 공유 가능하고 글자 수를 센다")
func textEnablesSubmit() {
    var state = ComposeFeature.State()
    state.text = "오늘의 순간"
    #expect(state.canSubmit == true)
    #expect(state.characterCount == 6)
}
