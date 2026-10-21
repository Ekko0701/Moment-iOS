import Foundation
import Testing
import Domain
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

@Test("보낼 곳은 보낼 수 있는 스페이스 중에서만 바꿀 수 있다")
func spaceSelectionLimitedToAvailable() {
    let pair = Space(id: UUID(), type: .oneToOne, maxMembers: 2, status: "ACTIVE", members: [], createdAt: Date())
    let group = Space(id: UUID(), type: .group, name: "가족", maxMembers: 6, status: "ACTIVE", members: [],
                      createdAt: Date())
    var state = ComposeFeature.State()
    state.availableSpaces = [pair, group]
    state.selectedSpaceId = pair.id

    _ = ComposeFeature().reduce(into: &state, action: .spaceSelected(group.id))
    #expect(state.selectedSpaceId == group.id)
    #expect(state.selectedSpace?.name == "가족")

    _ = ComposeFeature().reduce(into: &state, action: .spaceSelected(UUID()))
    #expect(state.selectedSpaceId == group.id)
}
