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
            OrbBackground.settings().ignoresSafeArea()

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

                Button {
                    UIPasteboard.general.string = profile.handle
                } label: {
                    Text("ID 복사")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(MomentColor.ink.opacity(0.6))
                }
                .buttonStyle(.plain)
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
                    if let partner = space.members.first(where: { $0.id != currentUser?.id }) {
                        Text("\(partner.nickname)님과의 스페이스")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(MomentColor.ink)
                    } else {
                        Text("우리 둘의 스페이스")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(MomentColor.ink)
                    }

                    Spacer()

                    let daysConnected = Calendar.current.dateComponents([.day], from: space.createdAt, to: Date()).day ?? 0
                    Text("D+\(daysConnected)")
                        .font(.system(size: 13, design: .default))
                        .foregroundColor(MomentColor.ink.opacity(0.55))
                }

                Button {
                    send(.disconnectTapped)
                } label: {
                    Text("연결 해제")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(MomentColor.destructive)
                }
                .buttonStyle(.plain)
                .padding(.top, Spacing.xxs)
            }
            .padding(Spacing.md)
        }
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
