import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'permission.dart';
import 'permission_status.dart';
import 'service_status.dart';
import 'nativeprems_method_channel.dart';

/// Platform interface for `nativeprems`. Lives inside this package (not a
/// separate `*_platform_interface` package) — there is no plan to publish
/// out-of-tree platform implementations.
abstract class NativePermsPlatform extends PlatformInterface {
  NativePermsPlatform() : super(token: _token);

  static final Object _token = Object();
  static NativePermsPlatform _instance = MethodChannelNativePerms();

  static NativePermsPlatform get instance => _instance;

  static set instance(NativePermsPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<PermissionStatus> checkPermissionStatus(Permission permission);

  Future<Map<Permission, PermissionStatus>> requestPermissions(
    List<Permission> permissions,
  );

  Future<bool> shouldShowRequestPermissionRationale(Permission permission);

  Future<ServiceStatus> checkServiceStatus(Permission permission);

  Future<bool> openAppSettings();
}
