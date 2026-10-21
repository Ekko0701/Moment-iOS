import Foundation
import ComposableArchitecture
import Domain
import Dependencies

/// 그룹 설정 — 초대 코드, 알림, 멤버, 이름, 나가기·종료.
/// 방장 전용 항목(이름 변경·코드 재발급·내보내기·종료)은 방장일 때만 노출하고 서버도 같은 규칙으로 막는다.
public struct GroupSettingsFeature {
    public struct State: Equatable {
        public var space: Space
        public var currentUserId: UUID?
        public var members: [SpaceMember] = []
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
        case reissueCodeTapped
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
            /// 이름·알림 설정이 바뀌어 상위 화면의 스페이스 정보를 다시 읽어야 한다
            case spaceChanged
            /// 내가 나갔거나 그룹을 종료해 더 이상 이 그룹에 속하지 않는다
            case exited
        }
    }

    public var body: some ReducerOf<Self> {
        Reduce<State, Action> { state, action in
            switch action {
            case .onAppear:
                return .merge(
                    .run { [spaceId = state.space.id] send in
                        @Dependency(\.groupUseCase) var groupUseCase
                        do {
                            await send(.codeLoaded(.success(try await groupUseCase.inviteCode(spaceId: spaceId))))
                        } catch {
                            await send(.codeLoaded(.failure(error.asDomainError)))
                        }
                    },
                    .run { [spaceId = state.space.id] send in
                        @Dependency(\.groupUseCase) var groupUseCase
                        do {
                            await send(.membersLoaded(.success(try await groupUseCase.members(spaceId: spaceId))))
                        } catch {
                            await send(.membersLoaded(.failure(error.asDomainError)))
                        }
                    }
                )

            case .codeLoaded(.success(let code)):
                state.isWorking = false
                state.inviteCode = code
                return .none

            case .codeLoaded(.failure):
                // 코드가 없거나 만료된 경우 — 방장은 재발급 버튼으로 해결하므로 오류를 띄우지 않는다
                state.isWorking = false
                state.inviteCode = nil
                return .none

            case .membersLoaded(.success(let members)):
                state.members = members
                return .none

            case .membersLoaded(.failure(let error)):
                state.error = error
                return .none

            case .reissueCodeTapped:
                guard state.isOwner, !state.isWorking else { return .none }
                state.isWorking = true
                return .run { [spaceId = state.space.id] send in
                    @Dependency(\.groupUseCase) var groupUseCase
                    do {
                        await send(.codeLoaded(.success(try await groupUseCase.reissueInviteCode(spaceId: spaceId))))
                    } catch {
                        await send(.exitResponse(.failure(error.asDomainError)))
                    }
                }

            case .notificationsToggled(let enabled):
                // 토글은 즉시 반영하고, 실패하면 서버에 저장된 값(space.notificationsEnabled)으로 되돌린다
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
                state.space = state.space.with(notificationsEnabled: enabled)
                return .send(.delegate(.spaceChanged))

            case .notificationsResponse(.failure(let error)):
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
                state.space = state.space.renamed(name)
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
                state.isWorking = true
                return .run { [spaceId = state.space.id] send in
                    @Dependency(\.groupUseCase) var groupUseCase
                    await send(.exitResponse(Result { try await groupUseCase.leave(spaceId: spaceId) }
                        .mapError { $0.asDomainError }))
                }

            case .confirmDelete:
                state.showDeleteConfirm = false
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

extension Space {
    func renamed(_ name: String) -> Space {
        Space(id: id, type: type, name: name, maxMembers: maxMembers, status: status, members: members,
              createdAt: createdAt, myRole: myRole, notificationsEnabled: notificationsEnabled,
              latestMoment: latestMoment)
    }

    func with(notificationsEnabled enabled: Bool) -> Space {
        Space(id: id, type: type, name: name, maxMembers: maxMembers, status: status, members: members,
              createdAt: createdAt, myRole: myRole, notificationsEnabled: enabled, latestMoment: latestMoment)
    }
}
