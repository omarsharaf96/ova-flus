// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "OvaFlus",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "OvaFlus",
            targets: ["OvaFlus"]
        ),
    ],
    dependencies: [
        // AWS Amplify iOS SDK
        .package(url: "https://github.com/aws-amplify/amplify-swift.git", from: "2.0.0"),
    ],
    targets: [
        .target(
            name: "OvaFlus",
            dependencies: [
                .product(name: "Amplify", package: "amplify-swift"),
                .product(name: "AWSCognitoAuthPlugin", package: "amplify-swift"),
                .product(name: "AWSAPIPlugin", package: "amplify-swift"),
            ],
            path: "OvaFlus"
        ),
    ]
)
