import SwiftUI
import CoreKit
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
        // 시트가 떠 있는 동안의 오류는 시트 쪽 alert가 보여 준다
        .modifier(ErrorAlert(
            error: state.error,
            isActive: !state.showNicknameSheet && !state.showSpaceNameSheet,
            dismiss: { send(.dismissError) }
        ))
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
        EditSheet(
            title: "닉네임 변경",
            placeholder: "닉네임",
            text: Binding(
                get: { state.nicknameInput },
                set: { send(.nicknameChanged($0)) }
            ),
            contentType: .nickname,
            countText: "\(state.trimmedNickname.count) / \(SettingsFeature.nicknameLength.upperBound)",
            hint: "2~12자로 입력해 주세요.",
            isLoading: state.isLoading,
            canSubmit: state.canSubmitNickname,
            error: state.error,
            onCancel: { send(.hideNicknameEditSheet) },
            onSubmit: { send(.nicknameSubmitTapped) },
            onDismissError: { send(.dismissError) }
        )
        .presentationDetents([.height(280)])
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
                        .font(.pretendard(size: 15, weight: .bold))
                        .foregroundColor(MomentColor.ink)

                    Text("@\(profile.handle)")
                        .font(.pretendard(size: 11))
                        .foregroundColor(MomentColor.ink.opacity(0.55))
                }

                Spacer()

                VStack(alignment: .trailing, spacing: Spacing.xs) {
                    Button {
                        send(.showNicknameEditSheet)
                    } label: {
                        Text("닉네임 변경")
                            .font(.pretendard(size: 12, weight: .medium))
                            .foregroundColor(MomentColor.ink.opacity(0.6))
                    }
                    .buttonStyle(.plain)

                    MomentCopyButton(value: profile.handle, announcement: "ID를 복사했어요") { copied in
                        Text(copied ? "복사됨 ✓" : "ID 복사")
                            .font(.pretendard(size: 12, weight: .medium))
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
                Text("내 스페이스")
                    .font(.pretendard(size: 12, weight: .semibold))
                    .foregroundColor(MomentColor.ink.opacity(0.65))

                HStack {
                    // 사용자가 붙인 이름이 있으면 그것을, 없으면 상대 이름 기반 폴백
                    Text(spaceTitle(space))
                        .font(.pretendard(size: 15, weight: .bold))
                        .foregroundColor(MomentColor.ink)

                    Spacer()

                    Text("D+\(space.daysTogether())")
                        .font(.pretendard(size: 13))
                        .foregroundColor(MomentColor.ink.opacity(0.55))
                }

                HStack(spacing: Spacing.md) {
                    Button {
                        send(.showSpaceNameEditSheet)
                    } label: {
                        Text("이름 변경")
                            .font(.pretendard(size: 13, weight: .medium))
                            .foregroundColor(MomentColor.ink.opacity(0.7))
                    }
                    .buttonStyle(.plain)

                    Button {
                        send(.disconnectTapped)
                    } label: {
                        Text("연결 해제")
                            .font(.pretendard(size: 13, weight: .medium))
                            .foregroundColor(MomentColor.destructive)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.top, Spacing.xxs)
            }
            .padding(Spacing.md)
        }
    }

    private func spaceTitle(_ space: Space) -> String {
        space.displayName(myUserId: currentUser?.id)
    }

    // MARK: - 스페이스 이름 변경 시트

    private var spaceNameSheet: some View {
        EditSheet(
            title: "스페이스 이름",
            placeholder: "예: 우리들의 공간",
            text: Binding(
                get: { state.spaceNameInput },
                set: { send(.spaceNameChanged($0)) }
            ),
            contentType: nil,
            countText: "\(state.trimmedSpaceName.count) / \(SettingsFeature.spaceNameMaxLength)",
            hint: "비워두면 “OO님과의 스페이스”로 표시돼요.",
            isLoading: state.isLoading,
            canSubmit: state.canSubmitSpaceName,
            error: state.error,
            onCancel: { send(.hideSpaceNameEditSheet) },
            onSubmit: { send(.spaceNameSubmitTapped) },
            onDismissError: { send(.dismissError) }
        )
        .presentationDetents([.height(280)])
    }

    // MARK: - ACCOUNT 카드

    private var accountCard: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("계정")
                    .font(.pretendard(size: 12, weight: .semibold))
                    .foregroundColor(MomentColor.ink.opacity(0.65))

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

// MARK: - 편집 시트

/// 한 줄 이름을 고치는 하프 시트. 취소 버튼, 글자 수, 저장 가능 여부를 함께 보여 준다.
private struct EditSheet: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    let contentType: UITextContentType?
    let countText: String
    let hint: String
    let isLoading: Bool
    let canSubmit: Bool
    let error: DomainError?
    let onCancel: () -> Void
    let onSubmit: () -> Void
    let onDismissError: () -> Void

    var body: some View {
        ZStack {
            MomentColor.canvas.ignoresSafeArea()

            VStack(spacing: Spacing.md) {
                ZStack {
                    Text(title)
                        .font(.pretendard(size: 17, weight: .bold))
                        .foregroundColor(MomentColor.ink)
                    HStack {
                        Button("취소", action: onCancel)
                            .font(.pretendard(size: 15))
                            .foregroundColor(MomentColor.ink.opacity(0.7))
                            .disabled(isLoading)
                        Spacer()
                    }
                }
                .padding(.top, Spacing.lg)

                VStack(alignment: .trailing, spacing: Spacing.xxs) {
                    MomentTextField(placeholder, text: $text, contentType: contentType)
                    Text(countText)
                        .font(.pretendard(size: 11))
                        .foregroundColor(MomentColor.ink.opacity(0.45))
                        .accessibilityLabel("글자 수 \(countText)")
                }

                MomentPillButton(isLoading ? "저장 중…" : "저장", style: .primary) {
                    onSubmit()
                }
                .disabled(!canSubmit)
                .opacity(canSubmit ? 1.0 : 0.6)
                .animation(.easeOut(duration: 0.15), value: canSubmit)

                Text(hint)
                    .font(.pretendard(size: 12))
                    .foregroundColor(MomentColor.ink.opacity(0.55))

                Spacer()
            }
            .padding(.horizontal, Spacing.lg)
        }
        .interactiveDismissDisabled(isLoading)
        .modifier(ErrorAlert(error: error, isActive: true, dismiss: onDismissError))
    }
}

/// 오류 alert. 시트가 떠 있으면 시트 쪽에서 띄워야 보이므로 isActive로 어느 쪽이 띄울지 고른다.
private struct ErrorAlert: ViewModifier {
    let error: DomainError?
    let isActive: Bool
    let dismiss: () -> Void

    func body(content: Content) -> some View {
        content.alert(
            error?.errorDescription ?? "오류가 발생했어요",
            isPresented: Binding(
                get: { isActive && error != nil },
                set: { if !$0 { dismiss() } }
            )
        ) {
            Button("확인", role: .cancel) {}
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
