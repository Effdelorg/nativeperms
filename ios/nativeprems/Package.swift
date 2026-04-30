// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "nativeprems",
    platforms: [
        .iOS("12.0")
    ],
    products: [
        .library(name: "nativeprems", targets: ["nativeprems"])
    ],
    dependencies: [],
    targets: [
        .target(
            name: "nativeprems",
            dependencies: [],
            resources: [],
            linkerSettings: [
                .linkedFramework("AVFoundation"),
                .linkedFramework("Photos"),
                .linkedFramework("CoreLocation"),
                .linkedFramework("EventKit"),
                .linkedFramework("Contacts"),
                .linkedFramework("UserNotifications"),
                .linkedFramework("CoreBluetooth"),
                .linkedFramework("Speech"),
                .linkedFramework("MediaPlayer"),
                .linkedFramework("CoreMotion"),
                .linkedFramework("AppTrackingTransparency", .when(platforms: [.iOS])),
                .linkedFramework("Intents"),
            ]
        )
    ]
)
