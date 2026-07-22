// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "SocialLoginSDK",
    platforms: [.iOS(.v15)],
    products: [
        .library(name: "SocialLoginSDK", targets: ["SocialLoginSDK"])
    ],
    dependencies: [
        // 和之前Xcode SPM一致的三方依赖
        .package(url: "https://github.com/google/GoogleSignIn-iOS", from: "9.2.0"),
        .package(url: "https://github.com/facebook/facebook-ios-sdk", from: "18.1.0")
    ],
    targets: [
        .target(
            name: "SocialLoginSDK",
            dependencies: [
                .product(name: "GoogleSignIn", package: "GoogleSignIn-iOS"),
                .product(name: "FacebookLogin", package: "facebook-ios-sdk"),
                .product(name: "FacebookCore", package: "facebook-ios-sdk")
            ],
            path: "./SocialLoginSDK"
        )
    ]
)
