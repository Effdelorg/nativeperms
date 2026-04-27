import Foundation

/// Mirrors lib/src/permission.dart numbering. Wire format on the channel.
enum P {
    static let calendar = 0
    static let camera = 1
    static let contacts = 2
    static let location = 3
    static let locationAlways = 4
    static let locationWhenInUse = 5
    static let mediaLibrary = 6
    static let microphone = 7
    static let phone = 8
    static let photos = 9
    static let photosAddOnly = 10
    static let reminders = 11
    static let sensors = 12
    static let sms = 13
    static let speech = 14
    static let storage = 15
    static let ignoreBatteryOptimizations = 16
    static let notification = 17
    static let accessMediaLocation = 18
    static let activityRecognition = 19
    static let unknown = 20
    static let bluetooth = 21
    static let manageExternalStorage = 22
    static let systemAlertWindow = 23
    static let requestInstallPackages = 24
    static let appTrackingTransparency = 25
    static let accessNotificationPolicy = 26
    static let bluetoothScan = 27
    static let bluetoothAdvertise = 28
    static let bluetoothConnect = 29
    static let nearbyWifiDevices = 30
    static let videos = 31
    static let audio = 32
    static let scheduleExactAlarm = 33
    static let sensorsAlways = 34
    static let criticalAlerts = 35
    static let calendarWriteOnly = 36
    static let calendarFullAccess = 37
    static let assistant = 38
    static let backgroundRefresh = 39

    // PermissionStatus indices.
    static let denied = 0
    static let granted = 1
    static let restricted = 2
    static let limited = 3
    static let permanentlyDenied = 4
    static let provisional = 5

    // ServiceStatus indices.
    static let serviceDisabled = 0
    static let serviceEnabled = 1
    static let serviceNotApplicable = 2
}
