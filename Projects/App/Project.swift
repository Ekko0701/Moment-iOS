import ProjectDescription
import ProjectDescriptionHelpers

let project = Project(
    name: "App",
    packages: [MomentPackage.composableArchitecture, MomentPackage.dependencies],
    settings: .settings(
        base: ["SWIFT_ALLOW_MACRO_ATTESTATIONS": "YES"],
        configurations: MomentConfiguration.all),
    targets: [
        .target(
            name: "MomentApp",
            destinations: [.iPhone],
            product: .app,
            bundleId: "com.ekko.moment",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .extendingDefault(
                with: [
                    "UIMainStoryboardFile": "",
                    "UILaunchStoryboardName": "LaunchScreen",
                    "NSLocalNetworkUsageDescription": "To communicate with the Moment server",
                    "NSBonjourServices": ["_http._tcp"],
                    // 로컬 개발 서버(http://localhost:8080) 연결 허용.
                    // ATS를 전역으로 끄지 않고 루프백/로컬 네트워킹만 예외 처리한다.
                    "NSAppTransportSecurity": [
                        "NSAllowsLocalNetworking": true,
                    ],
                ]
            ),
            sources: ["Sources/**"],
            entitlements: .file(path: "MomentApp.entitlements"),
            dependencies: [
                ModuleDependency.designSystem,
                ModuleDependency.domain,
                ModuleDependency.networking,
                ModuleDependency.coreKit,
                ModuleDependency.feature("AuthFeature"),
                ModuleDependency.feature("ConnectFeature"),
                ModuleDependency.feature("HomeFeature"),
                ModuleDependency.feature("FeedFeature"),
                ModuleDependency.feature("ComposeFeature"),
                ModuleDependency.feature("SettingsFeature"),
                .package(product: "ComposableArchitecture"),
                .package(product: "Dependencies"),
                .target(name: "MomentWidget"),
            ]
        ),
        .target(
            name: "MomentWidget",
            destinations: [.iPhone],
            product: .appExtension,
            bundleId: "com.ekko.moment.widget",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .extendingDefault(
                with: [
                    "NSExtension": [
                        "NSExtensionPointIdentifier": "com.apple.widgetkit-extension",
                    ],
                ]
            ),
            sources: ["Widget/Sources/**"],
            entitlements: .file(path: "Widget/MomentWidget.entitlements"),
            dependencies: [
                ModuleDependency.coreKit,
            ]
        ),
    ],
    schemes: [
        // 기본 MomentApp 스킴(자동 생성)은 Debug = 운영 서버.
        // 이 스킴으로 실행하면 Debug-Local 컨피규레이션 → LOCAL_SERVER 조건 → 로컬 서버.
        .scheme(
            name: "MomentApp-Local",
            shared: true,
            buildAction: .buildAction(targets: ["MomentApp"]),
            runAction: .runAction(configuration: "Debug-Local"),
            archiveAction: .archiveAction(configuration: "Release"),
            profileAction: .profileAction(configuration: "Release"),
            analyzeAction: .analyzeAction(configuration: "Debug-Local")
        ),
    ]
)
