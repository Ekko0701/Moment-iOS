import SwiftUI
import Domain
import MomentUIKit

// 매크로 없는 TCA 구성에서 모듈 경계를 지키기 위해 store.scope 대신 (state, send) 주입을 사용
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

            VStack(spacing: 0) {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    EyebrowText("설정")
                        .padding(.horizontal, Spacing.lg)
                        .padding(.top, Spacing.lg)

                    Text("프로필 및 설정")
                        .font(MomentTypography.headline)
                        .foregroundColor(MomentColor.ink)
                        .padding(.horizontal, Spacing.lg)
                }

                ScrollView {
                    VStack(spacing: Spacing.lg) {
                        if let profile = state.userProfile {
                            VStack(alignment: .leading, spacing: Spacing.md) {
                                EyebrowText("프로필")

                                HStack(spacing: Spacing.md) {
                                    VStack(alignment: .leading, spacing: Spacing.xs) {
                                        Text(profile.nickname)
                                            .font(MomentTypography.cardTitle)
                                            .foregroundColor(MomentColor.ink)

                                        Text("@\(profile.handle)")
                                            .font(MomentTypography.caption)
                                            .tracking(0.8)
                                            .foregroundColor(MomentColor.ink.opacity(0.6))
                                    }

                                    Spacer()

                                    MomentIconCircleButton(systemName: "square.on.square") {
                                        UIPasteboard.general.string = profile.handle
                                    }
                                }
                            }
                            .padding(.horizontal, Spacing.lg)
                            .padding(.vertical, Spacing.lg)

                            HairlineDivider()
                                .padding(.horizontal, Spacing.lg)
                        }

                        if let space = currentSpace {
                            ColorBlock(color: .mint) {
                                VStack(alignment: .leading, spacing: Spacing.md) {
                                    EyebrowText("연결 정보")

                                    if let partner = space.members.first(where: { $0.id != currentUser?.id }) {
                                        VStack(alignment: .leading, spacing: Spacing.xs) {
                                            Text("함께하는 사람")
                                                .font(MomentTypography.bodySM)
                                                .foregroundColor(MomentColor.ink.opacity(0.7))

                                            Text(partner.nickname)
                                                .font(MomentTypography.cardTitle)
                                                .foregroundColor(MomentColor.ink)

                                            let daysConnected = Calendar.current.dateComponents([.day], from: space.createdAt, to: Date()).day ?? 0
                                            Text("D+\(daysConnected)")
                                                .font(MomentTypography.bodySM)
                                                .foregroundColor(MomentColor.ink.opacity(0.6))
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, Spacing.lg)
                        }

                        VStack(alignment: .leading, spacing: Spacing.md) {
                            EyebrowText("위험한 작업")

                            VStack(spacing: Spacing.sm) {
                                Button {
                                    send(.disconnectTapped)
                                } label: {
                                    Text("연결 해제")
                                        .font(MomentTypography.button)
                                        .foregroundColor(MomentColor.ink)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }

                                HairlineDivider()

                                Button {
                                    send(.logoutTapped)
                                } label: {
                                    Text("로그아웃")
                                        .font(MomentTypography.button)
                                        .foregroundColor(MomentColor.ink)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }

                                HairlineDivider()

                                Button {
                                    send(.deleteAccountTapped)
                                } label: {
                                    Text("계정 삭제")
                                        .font(MomentTypography.button)
                                        .foregroundColor(MomentColor.accentMagenta)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                            }
                        }
                        .padding(.horizontal, Spacing.lg)
                        .padding(.vertical, Spacing.lg)
                    }
                    .padding(.vertical, Spacing.lg)
                }

                if state.isLoading {
                    ProgressView()
                        .padding(.vertical, Spacing.lg)
                }
            }
        }
        .onAppear {
            send(.onAppear)
        }
    }
}
