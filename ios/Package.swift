// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SensorWidgetsExtension",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "SensorWidgetsCore",
            targets: ["SensorWidgetsCore"]
        )
    ],
    targets: [
        .target(
            name: "SensorWidgetsCore",
            path: "SensorWidgetsExtension",
            exclude: [
                "SensorWidgetsBundle.swift"
            ]
        ),
        .testTarget(
            name: "SensorWidgetsTests",
            dependencies: ["SensorWidgetsCore"],
            path: "SensorWidgetsTests"
        )
    ]
)
