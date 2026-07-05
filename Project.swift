import ProjectDescription

let project = Project(
    name: "Moment",
    packages: [
        .remote(url: "https://github.com/pointfreeco/swift-composable-architecture.git", requirement: .upToNextMajor(from: "1.16.0")),
        .remote(url: "https://github.com/pointfreeco/swift-dependencies.git", requirement: .upToNextMajor(from: "1.0.0")),
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
                .target(name: "FeedFeature"),
                .target(name: "ComposeFeature"),
                .target(name: "SettingsFeature"),
                .target(name: "CoreKit"),
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
                .package(product: "Dependencies"),
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
                .target(name: "Networking"),
                .target(name: "MomentUIKit"),
                .package(product: "ComposableArchitecture"),
                .package(product: "Dependencies"),
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
                .target(name: "Networking"),
                .target(name: "MomentUIKit"),
                .target(name: "CoreKit"),
                .package(product: "ComposableArchitecture"),
                .package(product: "Dependencies"),
            ]
        ),

        // MARK: - Features: FeedFeature
        .target(
            name: "FeedFeature",
            destinations: [.iPhone],
            product: .framework,
            bundleId: "com.moment.features.feed",
            deploymentTargets: .iOS("17.0"),
            sources: ["Targets/Features/FeedFeature/Sources/**"],
            dependencies: [
                .target(name: "Domain"),
                .target(name: "Networking"),
                .target(name: "MomentUIKit"),
                .target(name: "CoreKit"),
                .package(product: "ComposableArchitecture"),
                .package(product: "Dependencies"),
            ]
        ),

        // MARK: - Features: ComposeFeature
        .target(
            name: "ComposeFeature",
            destinations: [.iPhone],
            product: .framework,
            bundleId: "com.moment.features.compose",
            deploymentTargets: .iOS("17.0"),
            sources: ["Targets/Features/ComposeFeature/Sources/**"],
            dependencies: [
                .target(name: "Domain"),
                .target(name: "Networking"),
                .target(name: "MomentUIKit"),
                .target(name: "CoreKit"),
                .package(product: "ComposableArchitecture"),
                .package(product: "Dependencies"),
            ]
        ),

        // MARK: - Features: SettingsFeature
        .target(
            name: "SettingsFeature",
            destinations: [.iPhone],
            product: .framework,
            bundleId: "com.moment.features.settings",
            deploymentTargets: .iOS("17.0"),
            sources: ["Targets/Features/SettingsFeature/Sources/**"],
            dependencies: [
                .target(name: "Domain"),
                .target(name: "Networking"),
                .target(name: "MomentUIKit"),
                .target(name: "CoreKit"),
                .package(product: "ComposableArchitecture"),
                .package(product: "Dependencies"),
            ]
        ),
    ]
)
