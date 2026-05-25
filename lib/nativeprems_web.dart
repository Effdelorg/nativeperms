/// Web entry point. Registered via `pubspec.yaml` `flutter.plugin.platforms.web`.
library nativeprems_web;

import 'dart:async';
import 'dart:js_interop';

import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:web/web.dart' as web;

import 'nativeprems.dart';

class NativePermsWeb extends NativePermsPlatform {
  static void registerWith(Registrar registrar) {
    NativePermsPlatform.instance = NativePermsWeb();
  }

  // --- Browser Permissions API names per Permission enum -----------------

  static String? _permissionsApiName(Permission p) {
    if (p == Permission.camera) return 'camera';
    if (p == Permission.microphone) return 'microphone';
    if (p == Permission.location ||
        p == Permission.locationWhenInUse ||
        p == Permission.locationAlways) {
      return 'geolocation';
    }
    if (p == Permission.notification) return 'notifications';
    return null;
  }

  // --- check ------------------------------------------------------------

  @override
  Future<PermissionStatus> checkPermissionStatus(Permission permission) async {
    if (permission == Permission.notification) {
      return _readNotificationPermission();
    }

    final String? name = _permissionsApiName(permission);
    if (name == null) return PermissionStatus.denied;

    try {
      final web.PermissionStatus status = await web.window.navigator.permissions
          .query(_PermissionDescriptor(name: name).jsify()! as JSObject)
          .toDart;
      return _mapBrowserState(status.state);
    } catch (_) {
      return PermissionStatus.denied;
    }
  }

  // --- request ----------------------------------------------------------

  @override
  Future<Map<Permission, PermissionStatus>> requestPermissions(
    List<Permission> permissions,
  ) async {
    final Map<Permission, PermissionStatus> out =
        <Permission, PermissionStatus>{};
    for (final Permission p in permissions) {
      out[p] = await _requestSingle(p);
    }
    return out;
  }

  Future<PermissionStatus> _requestSingle(Permission p) async {
    if (p == Permission.notification) {
      try {
        final String result =
            (await web.Notification.requestPermission().toDart).toDart;
        switch (result) {
          case 'granted':
            return PermissionStatus.granted;
          case 'denied':
            return PermissionStatus.permanentlyDenied;
          case 'default':
          default:
            return PermissionStatus.denied;
        }
      } catch (_) {
        return PermissionStatus.denied;
      }
    }

    if (p == Permission.camera || p == Permission.microphone) {
      try {
        final web.MediaStreamConstraints c = web.MediaStreamConstraints(
          video: (p == Permission.camera ? true : false).toJS,
          audio: (p == Permission.microphone ? true : false).toJS,
        );
        final web.MediaStream stream =
            await web.window.navigator.mediaDevices.getUserMedia(c).toDart;
        for (final web.MediaStreamTrack t in stream.getTracks().toDart) {
          t.stop();
        }
        return PermissionStatus.granted;
      } catch (_) {
        return PermissionStatus.permanentlyDenied;
      }
    }

    if (p == Permission.location ||
        p == Permission.locationWhenInUse ||
        p == Permission.locationAlways) {
      final Completer<PermissionStatus> done = Completer<PermissionStatus>();
      web.window.navigator.geolocation.getCurrentPosition(
        ((web.GeolocationPosition _) {
          if (!done.isCompleted) done.complete(PermissionStatus.granted);
        }).toJS,
        ((web.GeolocationPositionError err) {
          if (done.isCompleted) return;
          // 1 == PERMISSION_DENIED, 2 == POSITION_UNAVAILABLE, 3 == TIMEOUT.
          if (err.code == 1) {
            done.complete(PermissionStatus.permanentlyDenied);
          } else {
            done.complete(PermissionStatus.denied);
          }
        }).toJS,
      );
      return done.future;
    }

    return PermissionStatus.denied;
  }

  // --- service / settings -----------------------------------------------

  @override
  Future<bool> shouldShowRequestPermissionRationale(Permission permission) async =>
      false;

  @override
  Future<ServiceStatus> checkServiceStatus(Permission permission) async =>
      ServiceStatus.notApplicable;

  @override
  Future<bool> openAppSettings() async => false;

  // --- helpers ----------------------------------------------------------

  static PermissionStatus _readNotificationPermission() {
    try {
      switch (web.Notification.permission) {
        case 'granted':
          return PermissionStatus.granted;
        case 'denied':
          return PermissionStatus.permanentlyDenied;
        case 'default':
        default:
          return PermissionStatus.denied;
      }
    } catch (_) {
      return PermissionStatus.denied;
    }
  }

  static PermissionStatus _mapBrowserState(String state) {
    switch (state) {
      case 'granted':
        return PermissionStatus.granted;
      case 'denied':
        return PermissionStatus.permanentlyDenied;
      case 'prompt':
      default:
        return PermissionStatus.denied;
    }
  }
}

extension type _PermissionDescriptor._(JSObject _) implements JSObject {
  external _PermissionDescriptor({required String name});
}
