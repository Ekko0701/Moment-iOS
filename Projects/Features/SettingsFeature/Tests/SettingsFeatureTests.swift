import Foundation
import Testing
import Domain
@testable import SettingsFeature

@Test("초기 설정 상태는 확인 다이얼로그가 모두 닫혀 있다")
func initialState() {
    let state = SettingsFeature.State()
    #expect(state.showDisconnectConfirm == false)
    #expect(state.showDeleteAccountConfirm == false)
    #expect(state.userProfile == nil)
}

@Test("닉네임은 2~12자이고 지금과 다를 때만 저장할 수 있다")
func nicknameSubmitRules() {
    var state = SettingsFeature.State()
    state.userProfile = UserProfile(id: UUID(), handle: "moment_1", nickname: "동주")

    state.nicknameInput = "동"
    #expect(state.canSubmitNickname == false)

    state.nicknameInput = " 동주 "
    #expect(state.canSubmitNickname == false)

    state.nicknameInput = "동주2"
    #expect(state.canSubmitNickname == true)

    state.isLoading = true
    #expect(state.canSubmitNickname == false)
}

@Test("닉네임 입력은 12자에서 잘린다")
func nicknameInputIsCapped() {
    var state = SettingsFeature.State()
    _ = SettingsFeature().reduce(into: &state, action: .nicknameChanged(String(repeating: "가", count: 15)))
    #expect(state.nicknameInput.count == 12)
}

@Test("스페이스 이름은 10자까지, 비우기도 저장할 수 있다")
func spaceNameSubmitRules() {
    var state = SettingsFeature.State()
    state.currentSpace = Space(id: UUID(), type: .oneToOne, name: "우리집", maxMembers: 2, status: "ACTIVE",
                               members: [], createdAt: Date())

    state.spaceNameInput = "우리집"
    #expect(state.canSubmitSpaceName == false)

    state.spaceNameInput = ""
    #expect(state.canSubmitSpaceName == true)

    _ = SettingsFeature().reduce(into: &state, action: .spaceNameChanged(String(repeating: "나", count: 14)))
    #expect(state.spaceNameInput.count == 10)
    #expect(state.canSubmitSpaceName == true)
}
