import SwiftUI
import Domain
import MomentUIKit
import UIKit

/// 설정 — Final-MVP: 타이틀 없이 프로필 / MY SPACE / ACCOUNT 글래스 카드 3장.
/// 파괴적 액션(연결 해제, 계정 삭제)은 웜 레드로 구분한다.
/// 매크로 없는 TCA 구성에서 모듈 경계를 지키기 위해 store.scope 대신 (state, send) 주입을 사용.
public struct SettingsView: View {
    let state: SettingsFeature.State
    let send: (SettingsFeature.Action) -> Void
    let currentUser: UserProfile?
    let currentSpace: Space?

    public init(
        state: SettingsFeature.State,
        send: @escaping (SettingsFeature.Action) -> Void,
        currentUser: UserProfile?,
        currentSpace: Space?
    ) {
        self.state = state
        self.send = send
        self.currentUser = currentUser
        self.currentSpace = currentSpace
    }

    public var body: some View {
        ZStack {
            MomentColor.canvas.ignoresSafeArea()

            ScrollView {
                VStack(spacing: Spacing.md) {
                    if let profile = state.userProfile {
                        profileCard(profile)
                    }

                    if let space = currentSpace {
                        spaceCard(space)
                    }

                    accountCard

                    if state.isLoading {
                        ProgressView()
                            .tint(MomentColor.ink)
                            .padding(.vertical, Spacing.md)
                    }
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.vertical, Spacing.lg)
            }
        }
        .onAppear {
            send(.onAppear)
        }
        .alert(
            state.error?.errorDescription ?? "오류가 발생했어요",
            isPresented: Binding(
                get: { state.error != nil },
                set: { if !$0 { send(.dismissError) } }
            )
        ) {
            Button("확인", role: .cancel) {}
        }
        // 연결 해제 2단계 확인 (F-02-07) — Feature의 showDisconnectConfirm을 소비해야
        // confirmDisconnect가 발행되어 실제 해제가 실행된다.
        // alert를 쓰는 이유: iOS 26의 confirmationDialog는 출처에 앵커된 팝오버로 렌더되면서
        // 취소 버튼을 그리지 않는다(바깥 탭으로 대체). 파괴적이고 되돌리기 어려운 액션에는
        // 탈출구가 화면에 보여야 하므로 alert로 승격한다. 가벼운 액션(로그아웃)에는 쓰지 않는다.
        .alert(
            "연결을 해제할까요?",
            isPresented: Binding(
                get: { state.showDisconnectConfirm },
                set: { if !$0 { send(.cancelDisconnect) } }
            )
        ) {
            Button("연결 해제", role: .destructive) { send(.confirmDisconnect) }
            Button("취소", role: .cancel) { send(.cancelDisconnect) }
        } message: {
            Text("스페이스가 종료되고 상대방에게 알림이 가요. 모먼트는 각자 본인이 쓴 것만 남아요.")
        }
        // 계정 삭제 2단계 확인 (F-10)
        .alert(
            "정말 계정을 삭제할까요?",
            isPresented: Binding(
                get: { state.showDeleteAccountConfirm },
                set: { if !$0 { send(.cancelDeleteAccount) } }
            )
        ) {
            Button("계정 삭제", role: .destructive) { send(.confirmDeleteAccount) }
            Button("취소", role: .cancel) { send(.cancelDeleteAccount) }
        } message: {
            Text("연결이 종료되고 계정 정보가 삭제돼요. 되돌릴 수 없어요.")
        }
        // 닉네임 변경 시트
        .sheet(isPresented: Binding(
            get: { state.showNicknameSheet },
            set: { if !$0 { send(.hideNicknameEditSheet) } }
        )) {
            nicknameSheet
        }
        // 스페이스 이름 변경 시트
        .sheet(isPresented: Binding(
            get: { state.showSpaceNameSheet },
            set: { if !$0 { send(.hideSpaceNameEditSheet) } }
        )) {
            spaceNameSheet
        }
    }

    // MARK: - 닉네임 변경 시트

    private var nicknameSheet: some View {
        ZStack {
            MomentColor.canvas.ignoresSafeArea()

            VStack(spacing: Spacing.md) {
                Text("닉네임 변경")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(MomentColor.ink)
                    .padding(.top, Spacing.lg)

                MomentTextField("닉네임 (2~12자)", text: Binding(
                    get: { state.nicknameInput },
                    set: { send(.nicknameChanged($0)) }
                ))

                MomentPillButton(state.isLoading ? "저장 중…" : "저장", style: .primary) {
                    send(.nicknameSubmitTapped)
                }
                .disabled(state.isLoading)

                Spacer()
            }
            .padding(.horizontal, Spacing.lg)
        }
        .presentationDetents([.height(240)])
    }

    // MARK: - 프로필 카드

    private func profileCard(_ profile: UserProfile) -> some View {
        SurfaceCard {
            HStack(spacing: Spacing.md) {
                Circle()
                    .fill(MomentColor.hairline)
                    .frame(width: 46, height: 46)

                VStack(alignment: .leading, spacing: 2) {
                    Text(profile.nickname)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(MomentColor.ink)

                    Text("@\(profile.handle)")
                        .font(.system(size: 11, design: .default))
                        .foregroundColor(MomentColor.ink.opacity(0.55))
                }

                Spacer()

                VStack(alignment: .trailing, spacing: Spacing.xs) {
                    Button {
                        send(.showNicknameEditSheet)
                    } label: {
                        Text("닉네임 변경")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(MomentColor.ink.opacity(0.6))
                    }
                    .buttonStyle(.plain)

                    Button {
                        UIPasteboard.general.string = profile.handle
                    } label: {
                        Text("ID 복사")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(MomentColor.ink.opacity(0.6))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(Spacing.md)
        }
    }

    // MARK: - MY SPACE 카드

    private func spaceCard(_ space: Space) -> some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("MY SPACE")
                    .font(.system(size: 11, design: .default))
                    .tracking(1.2)
                    .foregroundColor(MomentColor.ink.opacity(0.5))

                HStack {
                    // 사용자가 붙인 이름이 있으면 그것을, 없으면 상대 이름 기반 폴백
                    Text(spaceTitle(space))
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(MomentColor.ink)

                    Spacer()

                    let daysConnected = Calendar.current.dateComponents([.day], from: space.createdAt, to: Date()).day ?? 0
                    Text("D+\(daysConnected)")
                        .font(.system(size: 13, design: .default))
                        .foregroundColor(MomentColor.ink.opacity(0.55))
                }

                HStack(spacing: Spacing.md) {
                    Button {
                        send(.showSpaceNameEditSheet)
                    } label: {
                        Text("이름 변경")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(MomentColor.ink.opacity(0.7))
                    }
                    .buttonStyle(.plain)

                    Button {
                        send(.disconnectTapped)
                    } label: {
                        Text("연결 해제")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(MomentColor.destructive)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.top, Spacing.xxs)
            }
            .padding(Spacing.md)
        }
    }

    /// 공간 이름 표시 규칙 — 홈(HomeView.spaceTitle)과 동일하게 맞춘다
    private func spaceTitle(_ space: Space) -> String {
        if let name = space.name, !name.isEmpty { return name }
        if let partner = space.members.first(where: { $0.id != currentUser?.id }) {
            return "\(partner.nickname)님과의 스페이스"
        }
        return "우리 둘의 스페이스"
    }

    // MARK: - 스페이스 이름 변경 시트

    private var spaceNameSheet: some View {
        ZStack {
            MomentColor.canvas.ignoresSafeArea()

            VStack(spacing: Spacing.md) {
                Text("스페이스 이름")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(MomentColor.ink)
                    .padding(.top, Spacing.lg)

                MomentTextField("예: 우리들의 공간 (최대 10자)", text: Binding(
                    get: { state.spaceNameInput },
                    set: { send(.spaceNameChanged($0)) }
                ))

                MomentPillButton(state.isLoading ? "저장 중…" : "저장", style: .primary) {
                    send(.spaceNameSubmitTapped)
                }
                .disabled(state.isLoading)

                Text("비워두면 “OO님과의 스페이스”로 표시돼요.")
                    .font(.system(size: 12))
                    .foregroundColor(MomentColor.ink.opacity(0.55))

                Spacer()
            }
            .padding(.horizontal, Spacing.lg)
        }
        .presentationDetents([.height(280)])
    }

    // MARK: - ACCOUNT 카드

    private var accountCard: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("ACCOUNT")
                    .font(.system(size: 11, design: .default))
                    .tracking(1.2)
                    .foregroundColor(MomentColor.ink.opacity(0.5))

                Button {
                    send(.logoutTapped)
                } label: {
                    Text("로그아웃")
                        .font(MomentTypography.body)
                        .foregroundColor(MomentColor.ink)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.plain)
                .padding(.vertical, Spacing.xxs)

                Rectangle()
                    .fill(MomentColor.ink.opacity(0.1))
                    .frame(height: 1)

                Button {
                    send(.deleteAccountTapped)
                } label: {
                    Text("계정 삭제")
                        .font(MomentTypography.body)
                        .foregroundColor(MomentColor.destructive)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.plain)
                .padding(.vertical, Spacing.xxs)
            }
            .padding(Spacing.md)
        }
    }
}

// MARK: - Xcode Previews

#Preview("설정 — 연결된 상태") {
    let me = UserProfile(id: UUID(), handle: "moment_5678", nickname: "동주")
    let partner = UserProfile(id: UUID(), handle: "moment_1234", nickname: "지은")
    let space = Space(
        id: UUID(),
        type: .oneToOne,
        maxMembers: 2,
        status: "ACTIVE",
        members: [me, partner],
        createdAt: Calendar.current.date(byAdding: .day, value: -99, to: Date()) ?? Date()
    )
    let state: SettingsFeature.State = {
        var s = SettingsFeature.State()
        s.userProfile = me
        s.currentSpace = space
        return s
    }()
    SettingsView(state: state, send: { _ in }, currentUser: me, currentSpace: space)
}
