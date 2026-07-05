import ProjectDescription

let project = Project(
    name: "Moment",
    packages: [],
    targets: [
        // MARK: - App Target
        .target(
            name: "MomentApp",
            destinations: [.iPhone],
            product: .app,
            bundleId: "com.moment.app",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .extendingDefault(
                with: [
                    "UIMainStoryboardFile": "",
                    "UILaunchStoryboardName": "LaunchScreen",
                    "NSLocalNetworkUsageDescription": "To communicate with the Moment server",
                    "NSBonjourServices": ["_http._tcp"],
                ]
            ),
            sources: ["Targets/App/Sources/**"],
            dependencies: [
                .target(name: "MomentUIKit"),
                .target(name: "Domain"),
            ]
        ),

        // MARK: - Core: DesignSystem
        .target(
            name: "MomentUIKit",
            destinations: [.iPhone],
            product: .framework,
            bundleId: "com.moment.uikit",
            deploymentTargets: .iOS("17.0"),
            sources: ["Targets/Core/DesignSystem/Sources/**"],
            dependencies: [
                .target(name: "CoreKit"),
            ]
        ),

        // MARK: - Core: Utilities
        .target(
            name: "CoreKit",
            destinations: [.iPhone],
            product: .framework,
            bundleId: "com.moment.corekit",
            deploymentTargets: .iOS("17.0"),
            sources: ["Targets/Core/CoreKit/Sources/**"],
            dependencies: []
        ),

        // MARK: - Core: Networking
        .target(
            name: "Networking",
            destinations: [.iPhone],
            product: .framework,
            bundleId: "com.moment.networking",
            deploymentTargets: .iOS("17.0"),
            sources: ["Targets/Core/Networking/Sources/**"],
            dependencies: [
                .target(name: "Domain"),
                .external(name: "Alamofire"),
            ]
        ),

        // MARK: - Domain: Entities & Protocols
        .target(
            name: "Domain",
            destinations: [.iPhone],
            product: .framework,
            bundleId: "com.moment.domain",
            deploymentTargets: .iOS("17.0"),
            sources: ["Targets/Domain/Sources/**"],
            dependencies: []
        ),
    ]
)
