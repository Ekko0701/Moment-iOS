import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.module(
    name: "Networking",
    bundleId: "com.moment.networking",
    packages: [MomentPackage.alamofire, MomentPackage.dependencies],
    dependencies: [
        ModuleDependency.domain,
        .package(product: "Alamofire"),
        .package(product: "Dependencies"),
    ]
)
