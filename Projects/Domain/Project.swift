import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.module(
    name: "Domain",
    bundleId: "com.moment.domain",
    packages: [MomentPackage.dependencies],
    dependencies: [.package(product: "Dependencies")],
    hasTests: true
)
