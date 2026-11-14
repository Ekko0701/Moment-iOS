import Foundation
import Testing
@testable import ConnectFeature

@Test("초기 상태는 코드 탭이고 입력이 비어 있다")
func initialState() {
    let state = ConnectFeature.State()
    #expect(state.selectedTab == .code)
    #expect(state.codeInput.isEmpty)
    #expect(state.receivedInvitations.isEmpty)
}

@Test("코드 입력이 상태에 반영된다")
func codeInputChanges() {
    var state = ConnectFeature.State()
    _ = ConnectFeature().reduce(into: &state, action: .codeInputChanged("ABC123"))
    #expect(state.codeInput == "ABC123")
}

@Test("코드 입력은 대문자 영숫자 6자리로 맞춰진다")
func codeInputIsNormalized() {
    var state = ConnectFeature.State()
    _ = ConnectFeature().reduce(into: &state, action: .codeInputChanged(" abc-12 3xyz"))
    #expect(state.codeInput == "ABC123")
}

@Test("6자리가 아니거나 처리 중이면 연결 요청을 보낼 수 없다")
func submitRequiresFullCode() {
    var state = ConnectFeature.State()
    state.codeInput = "ABC12"
    #expect(state.canSubmitCode == false)
    state.codeInput = "ABC123"
    #expect(state.canSubmitCode == true)
    state.isLoading = true
    #expect(state.canSubmitCode == false)
}
