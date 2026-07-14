import Dependencies
import Foundation

// MARK: - Repository DI 키 (선언만 Domain에)
// 구현(Networking)은 App이 시작 시 prepareDependencies로 주입한다.
// Feature/UseCase는 이 키로만 접근하므로 구현 모듈을 컴파일 타임에 볼 수 없다.

public extension DependencyValues {
    var authRepository: AuthRepositoryProtocol {
        get { self[AuthRepositoryKey.self] }
        set { self[AuthRepositoryKey.self] = newValue }
    }
    var userRepository: UserRepositoryProtocol {
        get { self[UserRepositoryKey.self] }
        set { self[UserRepositoryKey.self] = newValue }
    }
    var spaceRepository: SpaceRepositoryProtocol {
        get { self[SpaceRepositoryKey.self] }
        set { self[SpaceRepositoryKey.self] = newValue }
    }
    var momentRepository: MomentRepositoryProtocol {
        get { self[MomentRepositoryKey.self] }
        set { self[MomentRepositoryKey.self] = newValue }
    }
}

// liveValue를 계산 프로퍼티로 두어, App이 주입을 빠뜨린 채 접근하면
// 어떤 키가 빠졌는지 즉시 알 수 있게 한다.
private enum AuthRepositoryKey: DependencyKey {
    static var liveValue: AuthRepositoryProtocol {
        fatalError("authRepository 미주입 — App에서 prepareDependencies로 주입하세요")
    }
}

private enum UserRepositoryKey: DependencyKey {
    static var liveValue: UserRepositoryProtocol {
        fatalError("userRepository 미주입 — App에서 prepareDependencies로 주입하세요")
    }
}

private enum SpaceRepositoryKey: DependencyKey {
    static var liveValue: SpaceRepositoryProtocol {
        fatalError("spaceRepository 미주입 — App에서 prepareDependencies로 주입하세요")
    }
}

private enum MomentRepositoryKey: DependencyKey {
    static var liveValue: MomentRepositoryProtocol {
        fatalError("momentRepository 미주입 — App에서 prepareDependencies로 주입하세요")
    }
}
