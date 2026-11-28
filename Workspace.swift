import ProjectDescription

private func tests(_ path: String, _ target: String) -> TargetReference {
    .project(path: .relativeToRoot(path), target: target)
}

private let allTestTargets: [TargetReference] = [
    tests("Projects/Domain", "DomainTests"),
    tests("Projects/Core/CoreKit", "CoreKitTests"),
    tests("Projects/Core/Networking", "NetworkingTests"),
    tests("Projects/Features/AuthFeature", "AuthFeatureTests"),
    tests("Projects/Features/HomeFeature", "HomeFeatureTests"),
    tests("Projects/Features/ConnectFeature", "ConnectFeatureTests"),
    tests("Projects/Features/FeedFeature", "FeedFeatureTests"),
    tests("Projects/Features/ComposeFeature", "ComposeFeatureTests"),
    tests("Projects/Features/SettingsFeature", "SettingsFeatureTests"),
    tests("Projects/Features/GroupFeature", "GroupFeatureTests"),
    tests("Projects/App", "MomentAppTests"),
]

let workspace = Workspace(
    name: "Moment",
    projects: [
        "Projects/App",
        "Projects/Domain",
        "Projects/Core/CoreKit",
        "Projects/Core/DesignSystem",
        "Projects/Core/Networking",
        "Projects/Features/AuthFeature",
        "Projects/Features/HomeFeature",
        "Projects/Features/ConnectFeature",
        "Projects/Features/FeedFeature",
        "Projects/Features/ComposeFeature",
        "Projects/Features/SettingsFeature",
        "Projects/Features/GroupFeature",
    ],
    schemes: [
        // 모든 모듈의 단위 테스트를 한 번에 돌린다. 로컬과 CI가 같은 스킴을 쓴다.
        // 테스트 타깃을 추가하면 여기에도 추가한다.
        .scheme(
            name: "Moment-AllTests",
            shared: true,
            buildAction: .buildAction(targets: allTestTargets),
            testAction: .targets(allTestTargets.map { .testableTarget(target: $0) })
        ),
    ]
)
