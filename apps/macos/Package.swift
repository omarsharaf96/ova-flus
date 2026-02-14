// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "OvaFlusDesktop",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(
            name: "OvaFlusDesktop",
            targets: ["OvaFlusDesktop"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/aws-amplify/amplify-swift.git", from: "2.0.0"),
    ],
    targets: [
        .executableTarget(
            name: "OvaFlusDesktop",
            dependencies: [
                .product(name: "Amplify", package: "amplify-swift"),
                .product(name: "AWSCognitoAuthPlugin", package: "amplify-swift"),
                .product(name: "AWSAPIPlugin", package: "amplify-swift"),
            ],
            path: "OvaFlusDesktop"
        )
    ]
)
