// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "MomentPackages",
    dependencies: [
        .package(url: "https://github.com/Alamofire/Alamofire.git", .upToNextMajor(from: "5.8.0")),
    ]
)
