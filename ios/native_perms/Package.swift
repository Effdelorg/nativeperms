// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "native_perms",
    platforms: [
        .iOS("12.0")
    ],
    products: [
        .library(name: "native-perms", targets: ["native_perms"])
    ],
    dependencies: [],
    targets: [
        .target(
            name: "native_perms",
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
