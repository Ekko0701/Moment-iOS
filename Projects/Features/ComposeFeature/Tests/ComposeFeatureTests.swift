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

@Test("공백·줄바꿈만 있는 글은 공유할 수 없다")
func whitespaceOnlyCannotSubmit() {
    var state = ComposeFeature.State()
    state.text = "  \n\t "
    #expect(state.canSubmit == false)
    #expect(state.trimmedText.isEmpty)
}

@Test("500자를 넘는 입력은 넘는 부분만 잘린다")
func overflowIsTruncated() {
    var state = ComposeFeature.State()
    _ = ComposeFeature().reduce(into: &state, action: .textChanged(String(repeating: "가", count: 520)))
    #expect(state.characterCount == 500)
}

@Test("사진 위 글씨의 위치와 색을 고를 수 있고, 처음에는 왼쪽 위·흰색이다")
func textStyleSelection() {
    var state = ComposeFeature.State()
    #expect(state.textStyle == .standard)

    _ = ComposeFeature().reduce(into: &state, action: .textPositionSelected(.bottom))
    _ = ComposeFeature().reduce(into: &state, action: .textColorSelected(.butter))
    #expect(state.textStyle == MomentTextStyle(position: .bottom, color: .butter))
}

@Test("공유가 끝나면 사진·글·글씨 스타일이 모두 처음으로 돌아간다")
func successResetsTextStyle() {
    var state = ComposeFeature.State()
    state.selectedImage = Data([0xFF, 0xD8])
    state.text = "노을"
    state.textStyle = MomentTextStyle(position: .bottom, color: .lilac)
    state.isUploading = true

    let author = UserProfile(id: UUID(), handle: "m_a", nickname: "동주")
    let moment = Moment(id: UUID(), spaceId: UUID(), author: author, text: "노을", createdAt: Date())
    _ = ComposeFeature().reduce(into: &state, action: .submitResponse(.success(moment)))

    #expect(state.selectedImage == nil)
    #expect(state.text.isEmpty)
    #expect(state.textStyle == .standard)
    #expect(state.isUploading == false)
}

@Test("사진을 빼도 써 둔 글과 글씨 스타일은 남는다")
func clearImageKeepsText() {
    var state = ComposeFeature.State()
    state.selectedImage = Data([0xFF, 0xD8])
    state.text = "노을"
    state.textStyle = MomentTextStyle(position: .bottom, color: .peach)

    _ = ComposeFeature().reduce(into: &state, action: .clearImage)
    #expect(state.selectedImage == nil)
    #expect(state.text == "노을")
    #expect(state.textStyle.position == .bottom)
}
