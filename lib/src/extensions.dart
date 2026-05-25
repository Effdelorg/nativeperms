import 'nativeprems_platform_interface.dart';
import 'permission.dart';
import 'permission_status.dart';

/// Per-permission actions: `Permission.camera.status`, `.request()`, ...
extension PermissionActions on Permission {
  Future<PermissionStatus> get status =>
      NativePermsPlatform.instance.checkPermissionStatus(this);

  Future<PermissionStatus> request() async {
    final Map<Permission, PermissionStatus> result =
        await NativePermsPlatform.instance.requestPermissions(<Permission>[this]);
    return result[this] ?? PermissionStatus.denied;
  }

  /// Android only. iOS/Web/Windows always return false.
  Future<bool> get shouldShowRequestRationale =>
      NativePermsPlatform.instance.shouldShowRequestPermissionRationale(this);
}

/// Batch actions: `[Permission.camera, Permission.microphone].request()`.
extension PermissionListActions on List<Permission> {
  Future<Map<Permission, PermissionStatus>> request() =>
      NativePermsPlatform.instance.requestPermissions(this);
}

/// Open the application's settings page so the user can grant permissions
/// they previously denied. Returns `true` if the page was successfully opened.
Future<bool> openAppSettings() =>
    NativePermsPlatform.instance.openAppSettings();
