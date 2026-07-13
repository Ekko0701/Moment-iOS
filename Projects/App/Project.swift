import ProjectDescription
import ProjectDescriptionHelpers

let project = Project(
    name: "App",
    packages: [MomentPackage.composableArchitecture],
    settings: .settings(base: ["SWIFT_ALLOW_MACRO_ATTESTATIONS": "YES"]),
    targets: [
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
                .target(name: "MomentWidget"),
            ]
        ),
        .target(
            name: "MomentWidget",
            destinations: [.iPhone],
            product: .appExtension,
            bundleId: "com.moment.app.widget",
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
    ]
)
