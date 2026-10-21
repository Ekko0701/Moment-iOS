import SwiftUI
import Domain
import MomentUIKit

// 매크로 없는 TCA 구성에서 모듈 경계를 지키기 위해 store.scope 대신 (state, send) 주입을 사용한다.

// MARK: - 그룹 만들기

public struct GroupCreateView: View {
    let state: GroupCreateFeature.State
    let send: (GroupCreateFeature.Action) -> Void

    public init(state: GroupCreateFeature.State, send: @escaping (GroupCreateFeature.Action) -> Void) {
        self.state = state
        self.send = send
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                MomentColor.canvas.ignoresSafeArea()
                VStack(spacing: Spacing.lg) {
                    if let created = state.created {
                        GroupCodeCard(
                            title: "\(created.space.name ?? "그룹")을 만들었어요",
                            message: "아래 코드를 함께할 사람에게 보내 주세요.",
                            code: created.inviteCode
                        )
                        MomentPillButton("완료", style: .primary, minHeight: 54) { send(.doneTapped) }
                    } else {
                        SurfaceCard {
                            VStack(alignment: .leading, spacing: Spacing.sm) {
                                Text("그룹 이름")
                                    .font(MomentTypography.bodySM)
                                    .foregroundColor(MomentColor.ink.opacity(0.6))
                                TextField("예: 주말 산책", text: Binding(
                                    get: { state.name },
                                    set: { send(.nameChanged($0)) }
                                ))
                                .font(MomentTypography.bodyLG)
                                .submitLabel(.done)
                                .onSubmit { send(.submitTapped) }
                                Text("\(state.name.count) / \(GroupCreateFeature.nameMaxLength)")
                                    .font(MomentTypography.caption)
                                    .foregroundColor(MomentColor.ink.opacity(0.5))
                                    .frame(maxWidth: .infinity, alignment: .trailing)
                            }
                        }
                        MomentPillButton("만들기", style: .primary, minHeight: 54) { send(.submitTapped) }
                            .disabled(!state.canSubmit)
                            .opacity(state.canSubmit ? 1 : 0.6)
                        if state.isSubmitting { ProgressView().tint(MomentColor.ink) }
                    }
                    Spacer()
                }
                .padding(Spacing.lg)
            }
            .navigationTitle("그룹 만들기")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if state.created == nil {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("취소") { send(.cancelTapped) }
                    }
                }
            }
            .errorAlert(state.error) { send(.dismissError) }
        }
    }
}

// MARK: - 코드로 참여

public struct GroupJoinView: View {
    let state: GroupJoinFeature.State
    let send: (GroupJoinFeature.Action) -> Void

    public init(state: GroupJoinFeature.State, send: @escaping (GroupJoinFeature.Action) -> Void) {
        self.state = state
        self.send = send
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                MomentColor.canvas.ignoresSafeArea()
                VStack(spacing: Spacing.lg) {
                    SurfaceCard {
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            Text("초대 코드 6자리")
                                .font(MomentTypography.bodySM)
                                .foregroundColor(MomentColor.ink.opacity(0.6))
                            TextField("ABC123", text: Binding(
                                get: { state.code },
                                set: { send(.codeChanged($0)) }
                            ))
                            .font(.system(size: 28, weight: .semibold, design: .monospaced))
                            .textInputAutocapitalization(.characters)
                            .autocorrectionDisabled()
                            .submitLabel(.join)
                            .onSubmit { send(.submitTapped) }
                        }
                    }
                    MomentPillButton("참여하기", style: .primary, minHeight: 54) { send(.submitTapped) }
                        .disabled(!state.canSubmit)
                        .opacity(state.canSubmit ? 1 : 0.6)
                    if state.isSubmitting { ProgressView().tint(MomentColor.ink) }
                    Spacer()
                }
                .padding(Spacing.lg)
            }
            .navigationTitle("코드로 그룹 참여")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") { send(.cancelTapped) }
                }
            }
            .errorAlert(state.error) { send(.dismissError) }
        }
    }
}

// MARK: - 그룹 상세 상단 멤버 스트립

/// 멤버별 최신 모먼트를 가로로 보여준다. 아래 타임라인은 앱 셸이 붙인다.
public struct GroupMemberStripView: View {
    let state: GroupDetailFeature.State
    let send: (GroupDetailFeature.Action) -> Void

    public init(state: GroupDetailFeature.State, send: @escaping (GroupDetailFeature.Action) -> Void) {
        self.state = state
        self.send = send
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack {
                Text("\(state.space.memberCount) / \(state.space.maxMembers)명")
                    .font(MomentTypography.bodySM)
                    .foregroundColor(MomentColor.ink.opacity(0.6))
                Spacer()
                if state.isLoading { ProgressView().scaleEffect(0.7) }
            }
            .padding(.horizontal, Spacing.lg)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.sm) {
                    ForEach(state.orderedMembers) { member in
                        MemberMomentTile(member: member)
                    }
                }
                .padding(.horizontal, Spacing.lg)
            }
        }
        .padding(.vertical, Spacing.sm)
        .onAppear { send(.onAppear) }
        .errorAlert(state.error) { send(.dismissError) }
    }
}

struct MemberMomentTile: View {
    let member: SpaceMember

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                RoundedRectangle(cornerRadius: 18)
                    .fill(MomentColor.surfaceSoft)
                if let moment = member.latestMoment {
                    if let url = moment.imageURL {
                        AsyncImage(url: url) { phase in
                            if let image = phase.image {
                                image.resizable().scaledToFill()
                            } else {
                                MomentSunsetGradient()
                            }
                        }
                    } else {
                        Text(moment.text ?? "")
                            .font(MomentTypography.bodySM)
                            .foregroundColor(MomentColor.ink)
                            .multilineTextAlignment(.center)
                            .lineLimit(4)
                            .padding(Spacing.xs)
                    }
                } else {
                    Image(systemName: "moon.zzz")
                        .foregroundColor(MomentColor.ink.opacity(0.35))
                }
            }
            .frame(width: 96, height: 96)
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(MomentColor.hairline, lineWidth: 1))

            HStack(spacing: 3) {
                if member.role == .owner {
                    Image(systemName: "crown.fill").font(.system(size: 9)).foregroundColor(MomentColor.accent)
                }
                Text(member.user.nickname)
                    .font(.caption.weight(.medium))
                    .foregroundColor(MomentColor.ink)
                    .lineLimit(1)
            }
            .frame(width: 96)
        }
    }
}

// MARK: - 그룹 설정

public struct GroupSettingsView: View {
    let state: GroupSettingsFeature.State
    let send: (GroupSettingsFeature.Action) -> Void

    public init(state: GroupSettingsFeature.State, send: @escaping (GroupSettingsFeature.Action) -> Void) {
        self.state = state
        self.send = send
    }

    public var body: some View {
        List {
            Section("초대 코드") {
                if let code = state.inviteCode {
                    HStack {
                        Text(code.code)
                            .font(.system(size: 22, weight: .semibold, design: .monospaced))
                        Spacer()
                        ShareLink(item: inviteMessage(code)) {
                            Image(systemName: "square.and.arrow.up")
                        }
                    }
                    Text(code.isExpired() ? "만료된 코드예요" : "\(code.expiresAt.formatted(date: .abbreviated, time: .shortened))까지 사용할 수 있어요")
                        .font(MomentTypography.bodySM)
                        .foregroundColor(MomentColor.ink.opacity(0.6))
                } else {
                    Text("사용할 수 있는 코드가 없어요")
                        .foregroundColor(MomentColor.ink.opacity(0.6))
                }
                if state.isOwner {
                    Button("새 코드 발급") { send(.reissueCodeTapped) }
                        .disabled(state.isWorking)
                }
            }

            Section {
                Toggle("새 모먼트 알림", isOn: Binding(
                    get: { state.notificationsEnabled },
                    set: { send(.notificationsToggled($0)) }
                ))
            }

            if state.isOwner {
                Section("그룹 이름") {
                    TextField("그룹 이름", text: Binding(
                        get: { state.nameInput },
                        set: { send(.nameChanged($0)) }
                    ))
                    Button("이름 저장") { send(.renameTapped) }
                        .disabled(!state.canRename)
                }
            }

            Section("멤버 \(state.members.count) / \(state.space.maxMembers)") {
                ForEach(state.members) { member in
                    HStack {
                        Text(member.user.nickname)
                        if member.role == .owner {
                            Text("방장").font(.caption).foregroundColor(MomentColor.accent)
                        }
                        if member.user.id == state.currentUserId {
                            Text("나").font(.caption).foregroundColor(MomentColor.ink.opacity(0.5))
                        }
                        Spacer()
                        if state.isOwner && member.user.id != state.currentUserId {
                            Button("내보내기", role: .destructive) { send(.removeMemberTapped(member)) }
                                .font(MomentTypography.bodySM)
                        }
                    }
                }
            }

            Section {
                Button("그룹 나가기", role: .destructive) { send(.leaveTapped) }
                if state.isOwner {
                    Button("그룹 종료", role: .destructive) { send(.deleteTapped) }
                }
            } footer: {
                Text(state.isOwner
                     ? "방장이 나가면 가장 먼저 들어온 멤버가 방장이 돼요. 그룹을 종료하면 모든 멤버가 나가요."
                     : "나가도 내가 올린 모먼트는 그룹에 남아요.")
            }
        }
        .navigationTitle(state.space.name ?? "그룹 설정")
        .navigationBarTitleDisplayMode(.inline)
        .disabled(state.isWorking)
        .onAppear { send(.onAppear) }
        .confirmationDialog("그룹에서 나갈까요?", isPresented: Binding(
            get: { state.showLeaveConfirm }, set: { if !$0 { send(.cancelConfirm) } }
        ), titleVisibility: .visible) {
            Button("나가기", role: .destructive) { send(.confirmLeave) }
        }
        .confirmationDialog("그룹을 종료할까요? 모든 멤버가 나가요.", isPresented: Binding(
            get: { state.showDeleteConfirm }, set: { if !$0 { send(.cancelConfirm) } }
        ), titleVisibility: .visible) {
            Button("그룹 종료", role: .destructive) { send(.confirmDelete) }
        }
        .confirmationDialog(
            "\(state.memberToRemove?.user.nickname ?? "")님을 내보낼까요?",
            isPresented: Binding(
                get: { state.memberToRemove != nil }, set: { if !$0 { send(.cancelRemoveMember) } }
            ),
            titleVisibility: .visible
        ) {
            Button("내보내기", role: .destructive) { send(.confirmRemoveMember) }
        }
        .errorAlert(state.error) { send(.dismissError) }
    }

    private func inviteMessage(_ code: GroupInviteCode) -> String {
        "Moment 그룹 \"\(state.space.name ?? "")\"에 초대할게요. 앱의 '코드로 그룹 참여'에 \(code.code)를 입력해 주세요."
    }
}

// MARK: - 공통

struct GroupCodeCard: View {
    let title: String
    let message: String
    let code: GroupInviteCode

    var body: some View {
        SurfaceCard {
            VStack(spacing: Spacing.sm) {
                Text(title)
                    .font(MomentTypography.cardTitle)
                    .foregroundColor(MomentColor.ink)
                Text(message)
                    .font(MomentTypography.bodySM)
                    .foregroundColor(MomentColor.ink.opacity(0.6))
                Text(code.code)
                    .font(.system(size: 34, weight: .bold, design: .monospaced))
                    .foregroundColor(MomentColor.ink)
                    .padding(.vertical, Spacing.xs)
                    .textSelection(.enabled)
                ShareLink(item: "Moment 그룹 초대 코드: \(code.code)") {
                    Label("코드 보내기", systemImage: "square.and.arrow.up")
                        .font(.footnote.weight(.medium))
                }
                Text("7일 동안 여러 명이 같은 코드로 참여할 수 있어요")
                    .font(MomentTypography.caption)
                    .foregroundColor(MomentColor.ink.opacity(0.5))
            }
            .frame(maxWidth: .infinity)
        }
    }
}

extension View {
    func errorAlert(_ error: DomainError?, dismiss: @escaping () -> Void) -> some View {
        alert(
            error?.errorDescription ?? "오류가 발생했어요",
            isPresented: Binding(get: { error != nil }, set: { if !$0 { dismiss() } })
        ) {
            Button("확인", role: .cancel) {}
        }
    }
}
