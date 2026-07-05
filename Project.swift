import ProjectDescription

let project = Project(
    name: "Moment",
    packages: [
        .remote(url: "https://github.com/pointfreeco/swift-composable-architecture.git", requirement: .upToNextMajor(from: "1.16.0")),
        .remote(url: "https://github.com/Alamofire/Alamofire.git", requirement: .upToNextMajor(from: "5.8.0")),
    ],
    settings: .settings(
        base: ["SWIFT_ALLOW_MACRO_ATTESTATIONS": "YES"]
    ),
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
                .target(name: "Networking"),
                .target(name: "AuthFeature"),
                .target(name: "ConnectFeature"),
                .package(product: "ComposableArchitecture"),
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
                .package(product: "Alamofire"),
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

        // MARK: - Features: AuthFeature
        .target(
            name: "AuthFeature",
            destinations: [.iPhone],
            product: .framework,
            bundleId: "com.moment.features.auth",
            deploymentTargets: .iOS("17.0"),
            sources: ["Targets/Features/AuthFeature/Sources/**"],
            dependencies: [
                .target(name: "Domain"),
                .target(name: "MomentUIKit"),
                .package(product: "ComposableArchitecture"),
            ]
        ),

        // MARK: - Features: ConnectFeature
        .target(
            name: "ConnectFeature",
            destinations: [.iPhone],
            product: .framework,
            bundleId: "com.moment.features.connect",
            deploymentTargets: .iOS("17.0"),
            sources: ["Targets/Features/ConnectFeature/Sources/**"],
            dependencies: [
                .target(name: "Domain"),
                .target(name: "MomentUIKit"),
                .package(product: "ComposableArchitecture"),
            ]
        ),
    ]
)
