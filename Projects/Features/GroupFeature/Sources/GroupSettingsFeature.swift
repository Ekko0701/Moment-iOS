import Foundation
import ComposableArchitecture
import Domain
import Dependencies

/// 그룹 설정 — 초대 코드, 참여 요청, 알림, 멤버, 이름, 나가기·종료.
/// 방장 전용 항목(참여 요청 수락·거절, 이름 변경, 코드 재발급, 내보내기, 종료)은 방장일 때만 노출하고 서버도 같은 규칙으로 막는다.
public struct GroupSettingsFeature {
    public struct State: Equatable {
        public var space: Space
        public var currentUserId: UUID?
        public var members: [SpaceMember] = []
        /// 방장에게 보이는 대기 중 참여 요청
        public var joinRequests: [PendingJoinRequest] = []
        /// 수락·거절 응답을 기다리는 요청. 같은 요청을 두 번 누르지 못하게 한다
        public var decidingRequestIds: Set<UUID> = []
        /// 알림 설정 저장 중. 끝날 때까지 토글을 막아 요청 순서가 뒤집히지 않게 한다
        public var isUpdatingNotifications = false
        public var inviteCode: GroupInviteCode? = nil
        public var notificationsEnabled: Bool
        public var nameInput: String
        public var isWorking = false
        public var error: DomainError? = nil
        public var showLeaveConfirm = false
        public var showDeleteConfirm = false
        public var memberToRemove: SpaceMember? = nil

        public init(space: Space, currentUserId: UUID?) {
            self.space = space
            self.currentUserId = currentUserId
            self.notificationsEnabled = space.notificationsEnabled
            self.nameInput = space.name ?? ""
        }

        public var isOwner: Bool { space.isOwner }
        public var canRename: Bool {
            let trimmed = nameInput.trimmingCharacters(in: .whitespacesAndNewlines)
            return isOwner && !trimmed.isEmpty && trimmed != space.name && !isWorking
        }
    }

    public enum Action {
        case onAppear
        case codeLoaded(Result<GroupInviteCode, DomainError>)
        case membersLoaded(Result<[SpaceMember], DomainError>)
        case joinRequestsLoaded(Result<[PendingJoinRequest], DomainError>)
        case decideJoinRequestTapped(PendingJoinRequest, approve: Bool)
        case decideJoinRequestResponse(requestId: UUID, approve: Bool, Result<Void, DomainError>)
        case reissueCodeTapped
        case reissueResponse(Result<GroupInviteCode, DomainError>)
        case notificationsToggled(Bool)
        case notificationsResponse(Result<Bool, DomainError>)
        case nameChanged(String)
        case renameTapped
        case renameResponse(Result<String, DomainError>)
        case removeMemberTapped(SpaceMember)
        case confirmRemoveMember
        case cancelRemoveMember
        case removeMemberResponse(Result<UUID, DomainError>)
        case leaveTapped
        case confirmLeave
        case deleteTapped
        case confirmDelete
        case cancelConfirm
        case exitResponse(Result<Void, DomainError>)
        case dismissError
        case delegate(Delegate)

        public enum Delegate: Equatable {
            /// 이름·멤버·참여 요청이 바뀌어 상위 화면의 스페이스 정보를 다시 읽어야 한다
            case spaceChanged
            /// 내 알림 설정만 바뀌었다. 상위 화면은 목록을 다시 받지 않고 이 값만 반영한다
            case notificationsChanged(Bool)
            /// 내가 나갔거나 그룹을 종료해 더 이상 이 그룹에 속하지 않는다
            case exited
        }
    }

    private static func loadMembers(spaceId: UUID) -> Effect<Action> {
        .run { send in
            @Dependency(\.groupUseCase) var groupUseCase
            await send(.membersLoaded(Result { try await groupUseCase.members(spaceId: spaceId) }
                .mapError { $0.asDomainError }))
        }
    }

    private static func loadJoinRequests(spaceId: UUID) -> Effect<Action> {
        .run { send in
            @Dependency(\.groupUseCase) var groupUseCase
            await send(.joinRequestsLoaded(Result { try await groupUseCase.joinRequests(spaceId: spaceId) }
                .mapError { $0.asDomainError }))
        }
    }

    public var body: some ReducerOf<Self> {
        Reduce<State, Action> { state, action in
            switch action {
            case .onAppear:
                let loadRequests: Effect<Action> = state.isOwner ? Self.loadJoinRequests(spaceId: state.space.id) : .none
                return .merge(
                    loadRequests,
                    .run { [spaceId = state.space.id] send in
                        @Dependency(\.groupUseCase) var groupUseCase
                        do {
                            await send(.codeLoaded(.success(try await groupUseCase.inviteCode(spaceId: spaceId))))
                        } catch {
                            await send(.codeLoaded(.failure(error.asDomainError)))
                        }
                    },
                    Self.loadMembers(spaceId: state.space.id)
                )

            case .codeLoaded(.success(let code)):
                state.isWorking = false
                state.inviteCode = code
                return .none

            case .codeLoaded(.failure(let error)):
                // 코드가 없는 경우(notFound)는 방장이 재발급 버튼으로 해결하므로 오류를 띄우지 않는다.
                // 네트워크·서버 오류는 "코드 없음"으로 오해하지 않도록 알린다
                state.inviteCode = nil
                if case .notFound = error { return .none }
                state.error = error
                return .none

            case .membersLoaded(.success(let members)):
                state.members = members
                return .none

            case .membersLoaded(.failure(let error)):
                state.error = error
                return .none

            case .joinRequestsLoaded(.success(let requests)):
                state.joinRequests = requests
                return .none

            case .joinRequestsLoaded(.failure(let error)):
                state.error = error
                return .none

            case .decideJoinRequestTapped(let request, let approve):
                guard state.isOwner, !state.decidingRequestIds.contains(request.id) else { return .none }
                state.decidingRequestIds.insert(request.id)
                return .run { [spaceId = state.space.id, requestId = request.id] send in
                    @Dependency(\.groupUseCase) var groupUseCase
                    let result = await Result {
                        try await groupUseCase.decideJoinRequest(spaceId: spaceId, requestId: requestId, approve: approve)
                    }.mapError { $0.asDomainError }
                    await send(.decideJoinRequestResponse(requestId: requestId, approve: approve, result))
                }

            case .decideJoinRequestResponse(let requestId, let approve, .success):
                state.decidingRequestIds.remove(requestId)
                state.joinRequests.removeAll { $0.id == requestId }
                state.space.pendingJoinRequestCount = state.joinRequests.count
                let reloadMembers: Effect<Action> = approve ? Self.loadMembers(spaceId: state.space.id) : .none
                return .merge(reloadMembers, .send(.delegate(.spaceChanged)))

            case .decideJoinRequestResponse(let requestId, _, .failure(let error)):
                // 정원 초과·이미 처리됨 등. 목록을 서버 기준으로 다시 맞춘다
                state.decidingRequestIds.remove(requestId)
                state.error = error
                return Self.loadJoinRequests(spaceId: state.space.id)

            case .reissueCodeTapped:
                guard state.isOwner, !state.isWorking else { return .none }
                state.isWorking = true
                return .run { [spaceId = state.space.id] send in
                    @Dependency(\.groupUseCase) var groupUseCase
                    await send(.reissueResponse(Result { try await groupUseCase.reissueInviteCode(spaceId: spaceId) }
                        .mapError { $0.asDomainError }))
                }

            case .reissueResponse(.success(let code)):
                state.isWorking = false
                state.inviteCode = code
                return .none

            case .reissueResponse(.failure(let error)):
                state.isWorking = false
                state.error = error
                return .none

            case .notificationsToggled(let enabled):
                // 토글은 즉시 반영하고, 실패하면 서버에 저장된 값(space.notificationsEnabled)으로 되돌린다.
                // 저장이 끝날 때까지 다음 토글은 받지 않는다
                guard !state.isUpdatingNotifications, enabled != state.notificationsEnabled else { return .none }
                state.isUpdatingNotifications = true
                state.notificationsEnabled = enabled
                return .run { [spaceId = state.space.id] send in
                    @Dependency(\.groupUseCase) var groupUseCase
                    do {
                        try await groupUseCase.setNotifications(spaceId: spaceId, enabled: enabled)
                        await send(.notificationsResponse(.success(enabled)))
                    } catch {
                        await send(.notificationsResponse(.failure(error.asDomainError)))
                    }
                }

            case .notificationsResponse(.success(let enabled)):
                state.isUpdatingNotifications = false
                state.space.notificationsEnabled = enabled
                return .send(.delegate(.notificationsChanged(enabled)))

            case .notificationsResponse(.failure(let error)):
                state.isUpdatingNotifications = false
                state.notificationsEnabled = state.space.notificationsEnabled
                state.error = error
                return .none

            case .nameChanged(let name):
                state.nameInput = String(name.prefix(GroupCreateFeature.nameMaxLength))
                return .none

            case .renameTapped:
                guard state.canRename else { return .none }
                state.isWorking = true
                let name = state.nameInput.trimmingCharacters(in: .whitespacesAndNewlines)
                return .run { [spaceId = state.space.id] send in
                    @Dependency(\.groupUseCase) var groupUseCase
                    do {
                        try await groupUseCase.rename(spaceId: spaceId, name: name)
                        await send(.renameResponse(.success(name)))
                    } catch {
                        await send(.renameResponse(.failure(error.asDomainError)))
                    }
                }

            case .renameResponse(.success(let name)):
                state.isWorking = false
                state.space.name = name
                return .send(.delegate(.spaceChanged))

            case .renameResponse(.failure(let error)):
                state.isWorking = false
                state.error = error
                return .none

            case .removeMemberTapped(let member):
                guard state.isOwner, member.user.id != state.currentUserId else { return .none }
                state.memberToRemove = member
                return .none

            case .confirmRemoveMember:
                guard let member = state.memberToRemove else { return .none }
                state.memberToRemove = nil
                state.isWorking = true
                return .run { [spaceId = state.space.id, userId = member.user.id] send in
                    @Dependency(\.groupUseCase) var groupUseCase
                    do {
                        try await groupUseCase.removeMember(spaceId: spaceId, userId: userId)
                        await send(.removeMemberResponse(.success(userId)))
                    } catch {
                        await send(.removeMemberResponse(.failure(error.asDomainError)))
                    }
                }

            case .cancelRemoveMember:
                state.memberToRemove = nil
                return .none

            case .removeMemberResponse(.success(let userId)):
                state.isWorking = false
                state.members.removeAll { $0.user.id == userId }
                return .send(.delegate(.spaceChanged))

            case .removeMemberResponse(.failure(let error)):
                state.isWorking = false
                state.error = error
                return .none

            case .leaveTapped:
                state.showLeaveConfirm = true
                return .none

            case .deleteTapped:
                guard state.isOwner else { return .none }
                state.showDeleteConfirm = true
                return .none

            case .cancelConfirm:
                state.showLeaveConfirm = false
                state.showDeleteConfirm = false
                return .none

            case .confirmLeave:
                state.showLeaveConfirm = false
                guard !state.isWorking else { return .none }
                state.isWorking = true
                return .run { [spaceId = state.space.id] send in
                    @Dependency(\.groupUseCase) var groupUseCase
                    await send(.exitResponse(Result { try await groupUseCase.leave(spaceId: spaceId) }
                        .mapError { $0.asDomainError }))
                }

            case .confirmDelete:
                state.showDeleteConfirm = false
                guard state.isOwner, !state.isWorking else { return .none }
                state.isWorking = true
                return .run { [spaceId = state.space.id] send in
                    @Dependency(\.groupUseCase) var groupUseCase
                    await send(.exitResponse(Result { try await groupUseCase.delete(spaceId: spaceId) }
                        .mapError { $0.asDomainError }))
                }

            case .exitResponse(.success):
                state.isWorking = false
                return .send(.delegate(.exited))

            case .exitResponse(.failure(let error)):
                state.isWorking = false
                state.error = error
                return .none

            case .dismissError:
                state.error = nil
                return .none

            case .delegate:
                return .none
            }
        }
    }

    public init() {}
}

extension GroupSettingsFeature: Reducer {}
