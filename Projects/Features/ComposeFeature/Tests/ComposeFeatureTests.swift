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

@Test("사진만 있어도 공유할 수 있다 — 서버 계약(사진 또는 글 중 1개)과 일치")
func imageOnlyEnablesSubmit() {
    var state = ComposeFeature.State()
    state.selectedImage = Data([0xFF, 0xD8])
    #expect(state.canSubmit == true)
}

@Test("사진 처리 중에는 공유할 수 없다 — 미완성 이미지로 전송되는 경합 차단")
func processingPhotoBlocksSubmit() {
    var state = ComposeFeature.State()
    state.text = "글"
    state.isProcessingPhoto = true
    #expect(state.canSubmit == false)
}

@Test("사진 제거 후에는 텍스트가 없으면 다시 공유 불가")
func clearImageRestoresEmptyRule() {
    var state = ComposeFeature.State()
    state.selectedImage = Data([0xFF])
    state.selectedImage = nil
    #expect(state.canSubmit == false)
}
