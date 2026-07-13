import Foundation
import Testing
@testable import SettingsFeature

@Test("초기 설정 상태는 확인 다이얼로그가 모두 닫혀 있다")
func initialState() {
    let state = SettingsFeature.State()
    #expect(state.showDisconnectConfirm == false)
    #expect(state.showDeleteAccountConfirm == false)
    #expect(state.userProfile == nil)
}
