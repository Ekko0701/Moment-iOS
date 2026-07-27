import ProjectDescription

// MARK: - SPM 패키지 단일 선언
// 모든 모듈 프로젝트가 같은 버전을 쓰도록 여기서만 버전을 관리한다.

public enum MomentPackage {
    public static let composableArchitecture: Package = .remote(
        url: "https://github.com/pointfreeco/swift-composable-architecture.git",
        requirement: .upToNextMajor(from: "1.16.0"))
    public static let dependencies: Package = .remote(
        url: "https://github.com/pointfreeco/swift-dependencies.git",
        requirement: .upToNextMajor(from: "1.0.0"))
    public static let alamofire: Package = .remote(
        url: "https://github.com/Alamofire/Alamofire.git",
        requirement: .upToNextMajor(from: "5.8.0"))
}

// MARK: - 모듈 간 참조 단일 선언
// 경로 문자열이 여러 매니페스트에 흩어지지 않도록 여기서만 정의한다.

public enum ModuleDependency {
    public static let domain: TargetDependency = .project(
        target: "Domain", path: .relativeToRoot("Projects/Domain"))
    public static let coreKit: TargetDependency = .project(
        target: "CoreKit", path: .relativeToRoot("Projects/Core/CoreKit"))
    public static let designSystem: TargetDependency = .project(
        target: "MomentUIKit", path: .relativeToRoot("Projects/Core/DesignSystem"))
    public static let networking: TargetDependency = .project(
        target: "Networking", path: .relativeToRoot("Projects/Core/Networking"))

    public static func feature(_ name: String) -> TargetDependency {
        .project(target: name, path: .relativeToRoot("Projects/Features/\(name)"))
    }
}

// MARK: - 프로젝트 표준형

// MARK: - 빌드 컨피규레이션 단일 선언
// Debug(운영 서버) / Debug-Local(로컬 서버, LOCAL_SERVER 조건) / Release(운영 서버).
// 워크스페이스의 모든 프로젝트가 같은 컨피규레이션 셋을 가져야 스킴 빌드 시 불일치가 없다.

public enum MomentConfiguration {
    public static let all: [Configuration] = [
        .debug(name: "Debug"),
        .debug(
            name: "Debug-Local",
            settings: ["SWIFT_ACTIVE_COMPILATION_CONDITIONS": "$(inherited) LOCAL_SERVER"]),
        .release(name: "Release"),
    ]
}

public extension Project {
    private static let deploymentTarget: DeploymentTargets = .iOS("17.0")
    private static let baseSettings: Settings = .settings(
        base: ["SWIFT_ALLOW_MACRO_ATTESTATIONS": "YES"],
        configurations: MomentConfiguration.all)

    /// 프레임워크 모듈 표준형: Sources/** (+ 선택적으로 Tests/**)
    static func module(
        name: String,
        bundleId: String,
        packages: [Package] = [],
        dependencies: [TargetDependency] = [],
        hasTests: Bool = false,
        testDependencies: [TargetDependency] = []
    ) -> Project {
        var targets: [Target] = [
            .target(
                name: name,
                destinations: [.iPhone],
                product: .framework,
                bundleId: bundleId,
                deploymentTargets: deploymentTarget,
                sources: ["Sources/**"],
                dependencies: dependencies
            ),
        ]
        if hasTests {
            // 테스트 번들은 @testable import로 대상 모듈을 링크하지만,
            // TCA 매크로가 생성한 코드가 참조하는 패키지 심볼(ComposableArchitecture 등)은
            // 테스트 타깃에도 직접 링크되어 있어야 링크 단계에서 해소된다.
            targets.append(
                .target(
                    name: "\(name)Tests",
                    destinations: [.iPhone],
                    product: .unitTests,
                    bundleId: "\(bundleId).tests",
                    deploymentTargets: deploymentTarget,
                    sources: ["Tests/**"],
                    dependencies: [.target(name: name)] + testDependencies
                ))
        }
        return Project(
            name: name,
            packages: packages,
            settings: baseSettings,
            targets: targets
        )
    }

    /// Feature 모듈 표준형: TCA + Domain/DesignSystem/CoreKit 의존
    /// Networking은 Domain 모듈(UseCase 경로)을 통해만 접근하므로 직접 의존하지 않음
    static func feature(
        name: String,
        bundleIdSuffix: String,
        hasTests: Bool = true
    ) -> Project {
        module(
            name: name,
            bundleId: "com.moment.features.\(bundleIdSuffix)",
            packages: [MomentPackage.composableArchitecture, MomentPackage.dependencies],
            dependencies: [
                ModuleDependency.domain,
                ModuleDependency.designSystem,
                ModuleDependency.coreKit,
                .package(product: "ComposableArchitecture"),
                .package(product: "Dependencies"),
            ],
            hasTests: hasTests,
            testDependencies: [
                .package(product: "ComposableArchitecture"),
                .package(product: "Dependencies"),
            ]
        )
    }
}
