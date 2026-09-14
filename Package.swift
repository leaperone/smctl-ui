// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "SMCtlMenuBar",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "SMCtlMenuBar", targets: ["SMCtlMenuBarApp"])
    ],
    targets: [
        .target(
            name: "SMCtlProtocol",
            path: "Vendor/SMCtlProtocol"
        ),
        .target(
            name: "SMCtlClient",
            dependencies: ["SMCtlProtocol"],
            path: "Vendor/SMCtlClient"
        ),
        .target(
            name: "SMCtlMenuBar",
            dependencies: ["SMCtlClient", "SMCtlProtocol"],
            path: "Sources/SMCtlMenuBar"
        ),
        .executableTarget(
            name: "SMCtlMenuBarApp",
            dependencies: ["SMCtlMenuBar"],
            path: "Sources/SMCtlMenuBarApp"
        ),
        .testTarget(
            name: "SMCtlMenuBarTests",
            dependencies: ["SMCtlMenuBar", "SMCtlProtocol"]
        )
    ]
)
