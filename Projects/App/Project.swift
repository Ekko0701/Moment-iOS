import ProjectDescription
import ProjectDescriptionHelpers

let project = Project(
    name: "App",
    options: .options(
        defaultKnownRegions: ["ko", "Base"],
        developmentRegion: "ko"
    ),
    packages: [
        MomentPackage.composableArchitecture,
        MomentPackage.dependencies,
        MomentPackage.swiftNavigation,
    ],
    settings: .settings(
        base: MomentVersion.buildSettings
            .merging(["SWIFT_ALLOW_MACRO_ATTESTATIONS": "YES"]) { _, new in new },
        configurations: MomentConfiguration.all),
    targets: [
        .target(
            name: "MomentApp",
            destinations: [.iPhone],
            product: .app,
            bundleId: "com.ekko.moment",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .extendingDefault(
                with: MomentVersion.infoPlist.merging([
                    "CFBundleDisplayName": "Moment",
                    "UIAppFonts": [
                        "Pretendard-Regular.otf",
                        "Pretendard-Medium.otf",
                        "Pretendard-SemiBold.otf",
                        "Pretendard-Bold.otf",
                    ],
                    "UIMainStoryboardFile": "",
                    // 스토리보드 없이 시스템 배경색(라이트 흰색, 다크 검정)으로 시작 화면을 그린다
                    "UILaunchScreen": [:],
                    "NSLocalNetworkUsageDescription": "개발 서버와 통신하려면 로컬 네트워크 접근이 필요해요.",
                    "NSBonjourServices": ["_http._tcp"],
                    // 로컬 개발 서버(http://localhost:8080) 연결 허용.
                    // ATS를 전역으로 끄지 않고 루프백/로컬 네트워킹만 예외 처리한다.
                    // 위젯·알림이 여는 moment://login, moment://connect, moment://moment/{spaceId}/{momentId}
                    "CFBundleURLTypes": [
                        [
                            "CFBundleURLName": "com.ekko.moment",
                            "CFBundleURLSchemes": ["moment"],
                        ],
                    ],
                    "NSAppTransportSecurity": [
                        "NSAllowsLocalNetworking": true,
                    ],
                ]) { _, new in new }
            ),
            sources: ["Sources/**"],
            // 글꼴, 앱 아이콘(Assets.xcassets)
            resources: ["Resources/Fonts/**", "Resources/Assets.xcassets"],
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
                ModuleDependency.feature("GroupFeature"),
                .package(product: "ComposableArchitecture"),
                .package(product: "Dependencies"),
                .target(name: "MomentWidget"),
            ],
            settings: .settings(base: [
                // 강조 색은 코드(MomentColor)로 지정한다. 에셋 카탈로그에서 찾지 않게 비워 둔다
                "ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME": "",
            ])
        ),
        .target(
            name: "MomentWidget",
            destinations: [.iPhone],
            product: .appExtension,
            bundleId: "com.ekko.moment.widget",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .extendingDefault(
                with: MomentVersion.infoPlist.merging([
                    "NSExtension": [
                        "NSExtensionPointIdentifier": "com.apple.widgetkit-extension",
                    ],
                    "UIAppFonts": [
                        "Pretendard-Regular.otf",
                        "Pretendard-Medium.otf",
                        "Pretendard-SemiBold.otf",
                        "Pretendard-Bold.otf",
                    ],
                ]) { _, new in new }
            ),
            sources: ["Widget/Sources/**"],
            // 위젯 익스텐션은 앱 번들의 글꼴을 읽지 못하므로 같은 글꼴 파일을 따로 담는다
            resources: ["Resources/Fonts/**"],
            entitlements: .file(path: "Widget/MomentWidget.entitlements"),
            dependencies: [
                ModuleDependency.coreKit,
            ]
        ),
        // 앱 셸(AppFeature)의 상태 전이 테스트
        .target(
            name: "MomentAppTests",
            destinations: [.iPhone],
            product: .unitTests,
            bundleId: "com.ekko.moment.tests",
            deploymentTargets: .iOS("17.0"),
            sources: ["Tests/**"],
            dependencies: [
                .target(name: "MomentApp"),
                .package(product: "ComposableArchitecture"),
                .package(product: "Dependencies"),
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
