import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'native_perms_platform_interface.dart';
import 'permission.dart';
import 'permission_status.dart';
import 'service_status.dart';

/// Default platform implementation. Used on Android and iOS; Web and Windows
/// register their own subclasses.
class MethodChannelNativePerms extends NativePermsPlatform {
  @visibleForTesting
  final MethodChannel methodChannel = const MethodChannel(
    'dev.effdel.native_perms/methods',
  );

  @override
  Future<PermissionStatus> checkPermissionStatus(Permission permission) async {
    final int? index = await methodChannel.invokeMethod<int>(
      'checkPermissionStatus',
      permission.value,
    );
    return _statusByIndex(index);
  }

  @override
  Future<Map<Permission, PermissionStatus>> requestPermissions(
    List<Permission> permissions,
  ) async {
    final List<int> wire = permissions.map((p) => p.value).toList();
    final Map<Object?, Object?>? result =
        await methodChannel.invokeMethod<Map<Object?, Object?>>(
      'requestPermissions',
      wire,
    );
    if (result == null) {
      return <Permission, PermissionStatus>{};
    }
    return result.map<Permission, PermissionStatus>(
      (Object? key, Object? value) => MapEntry<Permission, PermissionStatus>(
        Permission.byValue(key! as int),
        _statusByIndex(value as int?),
      ),
    );
  }

  @override
  Future<bool> shouldShowRequestPermissionRationale(
    Permission permission,
  ) async {
    // Upstream: only Android implements this; everything else returns false.
    // Short-circuit before the channel call so iOS/Web/Windows never hit it.
    if (defaultTargetPlatform != TargetPlatform.android) {
      return false;
    }
    final bool? value = await methodChannel.invokeMethod<bool>(
      'shouldShowRequestPermissionRationale',
      permission.value,
    );
    return value ?? false;
  }

  @override
  Future<ServiceStatus> checkServiceStatus(Permission permission) async {
    final int? index = await methodChannel.invokeMethod<int>(
      'checkServiceStatus',
      permission.value,
    );
    return _serviceByIndex(index);
  }

  @override
  Future<bool> openAppSettings() async {
    final bool? value =
        await methodChannel.invokeMethod<bool>('openAppSettings');
    return value ?? false;
  }

  static PermissionStatus _statusByIndex(int? index) {
    if (index == null || index < 0 || index >= PermissionStatus.values.length) {
      return PermissionStatus.denied;
    }
    return PermissionStatus.values[index];
  }

  static ServiceStatus _serviceByIndex(int? index) {
    if (index == null || index < 0 || index >= ServiceStatus.values.length) {
      return ServiceStatus.notApplicable;
    }
    return ServiceStatus.values[index];
  }
}
