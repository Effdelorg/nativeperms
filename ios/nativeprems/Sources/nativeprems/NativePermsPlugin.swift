import Flutter
import UIKit

public class NativePermsPlugin: NSObject, FlutterPlugin {

    private let manager = PermissionManager()

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "dev.effdel.nativeprems/methods",
            binaryMessenger: registrar.messenger()
        )
        let instance = NativePermsPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "checkPermissionStatus":
            guard let perm = call.arguments as? Int else {
                result(FlutterError.invalidArgs); return
            }
            manager.checkPermissionStatus(perm) { result($0) }

        case "requestPermissions":
            guard let perms = call.arguments as? [Int] else {
                result(FlutterError.invalidArgs); return
            }
            manager.requestPermissions(perms) { map in
                // Convert [Int: Int] to a dict the Flutter codec can carry.
                var out: [Int: Int] = [:]
                for (k, v) in map { out[k] = v }
                result(out)
            }

        case "shouldShowRequestPermissionRationale":
            // Android-only; Dart short-circuits but be defensive.
            result(false)

        case "checkServiceStatus":
            guard let perm = call.arguments as? Int else {
                result(FlutterError.invalidArgs); return
            }
            ServiceManager.checkServiceStatus(perm) { result($0) }

        case "openAppSettings":
            result(AppSettingsManager.openAppSettings())

        default:
            result(FlutterMethodNotImplemented)
        }
    }
}

private extension FlutterError {
    static var invalidArgs: FlutterError {
        FlutterError(code: "INVALID_ARGS", message: "Argument was not the expected type", details: nil)
    }
}
