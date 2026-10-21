import Foundation
import Testing
@testable import CoreKit

/// 스페이스별 위젯 저장 규칙 — 앱이 쓰고 위젯 확장이 읽는다.
private func makeStore() -> WidgetMomentStore {
    let suite = "widget-space-tests-\(UUID().uuidString)"
    return WidgetMomentStore(userDefaults: UserDefaults(suiteName: suite)!)
}

private func snapshot(spaceId: UUID, text: String) -> WidgetMomentSnapshot {
    WidgetMomentSnapshot(momentId: UUID(), spaceId: spaceId, authorNickname: "지수", text: text,
                         imageFileName: nil, createdAt: Date(timeIntervalSince1970: 1_757_000_000), hasImage: false)
}

@Test("스페이스를 고르지 않으면 1:1 스페이스를, 1:1이 없으면 첫 스페이스를 보여준다")
func defaultSpacePrefersOneToOne() {
    let store = makeStore()
    let group = WidgetSpaceInfo(id: UUID(), name: "가족", isGroup: true)
    let pair = WidgetSpaceInfo(id: UUID(), name: "지은님과의 스페이스", isGroup: false)

    store.saveSpaces([group, pair])
    #expect(store.defaultSpaceId() == pair.id)

    store.saveSpaces([group])
    #expect(store.defaultSpaceId() == group.id)
}

@Test("고른 스페이스의 상태를 보여주고, 로그인·연결 필요가 그보다 우선한다")
func resolvedStatePerSpace() {
    let store = makeStore()
    let pair = WidgetSpaceInfo(id: UUID(), name: "1:1", isGroup: false)
    let group = WidgetSpaceInfo(id: UUID(), name: "가족", isGroup: true)
    store.saveSpaces([pair, group])
    store.saveState(.empty)
    store.saveState(.hasMoment(snapshot(spaceId: pair.id, text: "연인")), for: pair.id)
    store.saveState(.hasMoment(snapshot(spaceId: group.id, text: "가족")), for: group.id)

    guard case .hasMoment(let defaultShown) = store.resolvedState(selectedSpaceId: nil) else {
        Issue.record("기본 스페이스 모먼트가 있어야 한다"); return
    }
    #expect(defaultShown.text == "연인")

    guard case .hasMoment(let groupShown) = store.resolvedState(selectedSpaceId: group.id) else {
        Issue.record("그룹 모먼트가 있어야 한다"); return
    }
    #expect(groupShown.text == "가족")

    store.saveState(.needLogin)
    guard case .needLogin = store.resolvedState(selectedSpaceId: group.id) else {
        Issue.record("로그인 필요가 우선해야 한다"); return
    }
}

@Test("이전 형식(전체 키에 모먼트 1건)은 그 모먼트의 스페이스를 고른 위젯에 그대로 보인다")
func legacyGlobalMomentStillShows() {
    let store = makeStore()
    let spaceId = UUID()
    store.saveState(.hasMoment(snapshot(spaceId: spaceId, text: "예전")))

    guard case .hasMoment(let shown) = store.resolvedState(selectedSpaceId: nil) else {
        Issue.record("이전 모먼트가 보여야 한다"); return
    }
    #expect(shown.text == "예전")
}

@Test("목록에서 빠진 스페이스의 상태는 지워진다")
func removesStatesOfLeftSpaces() {
    let store = makeStore()
    let kept = UUID()
    let left = UUID()
    store.saveState(.hasMoment(snapshot(spaceId: kept, text: "남음")), for: kept)
    store.saveState(.hasMoment(snapshot(spaceId: left, text: "나감")), for: left)

    store.removeSpaceStates(except: [kept])

    #expect(store.loadState(for: kept).isMoment)
    #expect(store.loadState(for: left).isMoment == false)
}

@Test("로그아웃하면 스페이스 목록과 상태를 지우고 로그인 필요로 둔다")
func logoutResetsEverything() {
    let store = makeStore()
    let id = UUID()
    store.saveSpaces([WidgetSpaceInfo(id: id, name: "1:1", isGroup: false)])
    store.saveState(.hasMoment(snapshot(spaceId: id, text: "x")), for: id)

    store.resetForLogout()

    #expect(store.loadSpaces().isEmpty)
    #expect(store.loadState(for: id).isMoment == false)
    guard case .needLogin = store.resolvedState(selectedSpaceId: id) else {
        Issue.record("로그인 필요여야 한다"); return
    }
}
