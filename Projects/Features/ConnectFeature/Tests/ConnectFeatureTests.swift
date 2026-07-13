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
