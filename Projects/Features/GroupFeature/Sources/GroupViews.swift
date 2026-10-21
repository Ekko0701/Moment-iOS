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
                        if state.isSubmitting {
                            ProgressView().tint(MomentColor.ink).accessibilityLabel("그룹을 만드는 중")
                        }
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
                            .disabled(state.isSubmitting)
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
                    if let request = state.sentRequest {
                        SurfaceCard {
                            VStack(spacing: Spacing.sm) {
                                Image(systemName: "hourglass")
                                    .font(.title2)
                                    .foregroundColor(MomentColor.ink.opacity(0.6))
                                    .accessibilityHidden(true)
                                Text("참여를 요청했어요")
                                    .font(MomentTypography.cardTitle)
                                    .foregroundColor(MomentColor.ink)
                                Text("‘\(request.spaceName)’ 방장이 수락하면 홈에 그룹이 나타나요.")
                                    .font(MomentTypography.bodySM)
                                    .foregroundColor(MomentColor.ink.opacity(0.6))
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity)
                        }
                        MomentPillButton("확인", style: .primary, minHeight: 54) { send(.doneTapped) }
                    } else {
                        SurfaceCard {
                            VStack(alignment: .leading, spacing: Spacing.sm) {
                                Text("초대 코드 6자리")
                                    .font(MomentTypography.bodySM)
                                    .foregroundColor(MomentColor.ink.opacity(0.6))
                                TextField("ABC123", text: Binding(
                                    get: { state.code },
                                    set: { send(.codeChanged($0)) }
                                ))
                                .font(.system(.title, design: .monospaced).weight(.semibold))
                                .textInputAutocapitalization(.characters)
                                .autocorrectionDisabled()
                                .submitLabel(.join)
                                .onSubmit { send(.submitTapped) }
                                .accessibilityLabel("초대 코드")
                                Text("방장이 수락하면 그룹에 들어가요.")
                                    .font(MomentTypography.caption)
                                    .foregroundColor(MomentColor.ink.opacity(0.5))
                            }
                        }
                        MomentPillButton("참여 요청", style: .primary, minHeight: 54) { send(.submitTapped) }
                            .disabled(!state.canSubmit)
                            .opacity(state.canSubmit ? 1 : 0.6)
                        if state.isSubmitting {
                            ProgressView().tint(MomentColor.ink).accessibilityLabel("참여를 요청하는 중")
                        }
                    }
                    Spacer()
                }
                .padding(Spacing.lg)
            }
            .navigationTitle("코드로 그룹 참여")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(state.sentRequest == nil ? "취소" : "닫기") { send(.cancelTapped) }
                        .disabled(state.isSubmitting)
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
                if state.isLoading { ProgressView().scaleEffect(0.7).accessibilityLabel("멤버를 불러오는 중") }
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

            // 실패는 알림 창 대신 이 자리에 보여준다. 위에 설정 화면이 열려 있어도 알림이 겹치지 않는다
            if state.error != nil {
                HStack(spacing: Spacing.xs) {
                    Text("멤버를 불러오지 못했어요")
                        .font(MomentTypography.bodySM)
                        .foregroundColor(MomentColor.ink.opacity(0.6))
                    Button("다시 시도") { send(.onAppear) }
                        .font(MomentTypography.bodySM.weight(.semibold))
                }
                .padding(.horizontal, Spacing.lg)
            }
        }
        .padding(.vertical, Spacing.sm)
        // 화면이 열려 있는 채로 다른 그룹으로 바뀌어도 그 그룹의 멤버를 다시 불러온다
        .task(id: state.space.id) { send(.onAppear) }
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
                    Image(systemName: "crown.fill").font(.caption2).foregroundColor(MomentColor.accent)
                }
                Text(member.user.nickname)
                    .font(.caption.weight(.medium))
                    .foregroundColor(MomentColor.ink)
                    .lineLimit(1)
            }
            .frame(width: 96)
        }
        // 타일 하나를 "닉네임, 방장, 최신 모먼트" 한 문장으로 읽는다
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText)
    }

    private var accessibilityText: String {
        var parts = [member.user.nickname]
        if member.role == .owner { parts.append("방장") }
        if let moment = member.latestMoment {
            if moment.imageURL != nil { parts.append("사진 모먼트") }
            if let text = moment.text, !text.isEmpty { parts.append(text) }
        } else {
            parts.append("아직 모먼트 없음")
        }
        return parts.joined(separator: ", ")
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
                            .font(.system(.title2, design: .monospaced).weight(.semibold))
                            .accessibilityLabel(spelledCode(code.code))
                        Spacer()
                        ShareLink(item: inviteMessage(code)) {
                            Image(systemName: "square.and.arrow.up")
                        }
                        .accessibilityLabel("초대 코드 보내기")
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

            if state.isOwner && !state.joinRequests.isEmpty {
                Section {
                    ForEach(state.joinRequests) { request in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(request.user.nickname)
                                Text("@\(request.user.handle)")
                                    .font(.caption)
                                    .foregroundColor(MomentColor.ink.opacity(0.5))
                            }
                            Spacer()
                            if state.decidingRequestIds.contains(request.id) {
                                ProgressView().accessibilityLabel("처리하는 중")
                            } else {
                                Button("거절") { send(.decideJoinRequestTapped(request, approve: false)) }
                                    .buttonStyle(.borderless)
                                    .foregroundColor(MomentColor.ink.opacity(0.6))
                                    .accessibilityLabel("\(request.user.nickname)님 요청 거절")
                                Button("수락") { send(.decideJoinRequestTapped(request, approve: true)) }
                                    .buttonStyle(.borderless)
                                    .fontWeight(.semibold)
                                    .disabled(state.members.count >= state.space.maxMembers)
                                    .accessibilityLabel("\(request.user.nickname)님 요청 수락")
                            }
                        }
                    }
                } header: {
                    Text("참여 요청 \(state.joinRequests.count)")
                } footer: {
                    if state.members.count >= state.space.maxMembers {
                        Text("정원이 찼어요. 멤버가 나가면 수락할 수 있어요.")
                    }
                }
            }

            Section {
                Toggle("새 모먼트 알림", isOn: Binding(
                    get: { state.notificationsEnabled },
                    set: { send(.notificationsToggled($0)) }
                ))
                .disabled(state.isUpdatingNotifications)
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
                                .buttonStyle(.borderless)
                                .accessibilityLabel("\(member.user.nickname)님 내보내기")
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
        // 나가기·종료·내보내기 처리 중에는 뒤로 가지 못하게 해 결과가 버려지지 않게 한다
        .navigationBarBackButtonHidden(state.isWorking)
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
        "Moment 그룹 \"\(state.space.name ?? "")\"에 초대할게요. 앱의 '코드로 그룹 참여'에 \(code.code)를 입력하면 제가 수락할게요."
    }
}

// MARK: - 공통

/// VoiceOver가 코드를 한 단어가 아니라 글자 단위로 읽도록 띄어 쓴다
func spelledCode(_ code: String) -> String {
    "초대 코드 " + code.map(String.init).joined(separator: " ")
}

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
                    .font(.system(.largeTitle, design: .monospaced).weight(.bold))
                    .foregroundColor(MomentColor.ink)
                    .padding(.vertical, Spacing.xs)
                    .textSelection(.enabled)
                    .accessibilityLabel(spelledCode(code.code))
                ShareLink(item: "Moment 그룹 초대 코드: \(code.code)") {
                    Label("코드 보내기", systemImage: "square.and.arrow.up")
                        .font(.footnote.weight(.medium))
                }
                Text("7일 동안 쓸 수 있어요. 코드로 요청하면 방장이 수락해야 들어와요")
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
