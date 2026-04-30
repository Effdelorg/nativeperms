import 'nativeprems_platform_interface.dart';
import 'service_status.dart';

/// Defines the permissions that the plugin supports.
///
/// Numeric [value] is the wire format used on every platform.
class Permission {
  const Permission._(this.value);

  /// Construct a Permission by integer value. Used for cross-channel
  /// rehydration; not intended for app code.
  factory Permission.byValue(int value) {
    if (value < 0 || value >= values.length) {
      throw ArgumentError('No Permission with value $value');
    }
    return values[value];
  }

  final int value;

  static const Permission calendar = Permission._(0);
  static const Permission camera = Permission._(1);
  static const Permission contacts = Permission._(2);
  static const PermissionWithService location = PermissionWithService._(3);
  static const PermissionWithService locationAlways =
      PermissionWithService._(4);
  static const PermissionWithService locationWhenInUse =
      PermissionWithService._(5);
  static const Permission mediaLibrary = Permission._(6);
  static const Permission microphone = Permission._(7);
  static const PermissionWithService phone = PermissionWithService._(8);
  static const Permission photos = Permission._(9);
  static const Permission photosAddOnly = Permission._(10);
  static const Permission reminders = Permission._(11);
  static const Permission sensors = Permission._(12);
  static const Permission sms = Permission._(13);
  static const Permission speech = Permission._(14);
  static const Permission storage = Permission._(15);
  static const Permission ignoreBatteryOptimizations = Permission._(16);
  static const Permission notification = Permission._(17);
  static const Permission accessMediaLocation = Permission._(18);
  static const Permission activityRecognition = Permission._(19);
  static const Permission unknown = Permission._(20);
  static const PermissionWithService bluetooth = PermissionWithService._(21);
  static const Permission manageExternalStorage = Permission._(22);
  static const Permission systemAlertWindow = Permission._(23);
  static const Permission requestInstallPackages = Permission._(24);
  static const Permission appTrackingTransparency = Permission._(25);
  static const Permission accessNotificationPolicy = Permission._(26);
  static const Permission bluetoothScan = Permission._(27);
  static const Permission bluetoothAdvertise = Permission._(28);
  static const Permission bluetoothConnect = Permission._(29);
  static const Permission nearbyWifiDevices = Permission._(30);
  static const Permission videos = Permission._(31);
  static const Permission audio = Permission._(32);
  static const Permission scheduleExactAlarm = Permission._(33);
  static const Permission sensorsAlways = Permission._(34);
  static const Permission criticalAlerts = Permission._(35);
  static const Permission calendarWriteOnly = Permission._(36);
  static const Permission calendarFullAccess = Permission._(37);
  static const Permission assistant = Permission._(38);
  static const Permission backgroundRefresh = Permission._(39);

  static const List<Permission> values = <Permission>[
    calendar,
    camera,
    contacts,
    location,
    locationAlways,
    locationWhenInUse,
    mediaLibrary,
    microphone,
    phone,
    photos,
    photosAddOnly,
    reminders,
    sensors,
    sms,
    speech,
    storage,
    ignoreBatteryOptimizations,
    notification,
    accessMediaLocation,
    activityRecognition,
    unknown,
    bluetooth,
    manageExternalStorage,
    systemAlertWindow,
    requestInstallPackages,
    appTrackingTransparency,
    accessNotificationPolicy,
    bluetoothScan,
    bluetoothAdvertise,
    bluetoothConnect,
    nearbyWifiDevices,
    videos,
    audio,
    scheduleExactAlarm,
    sensorsAlways,
    criticalAlerts,
    calendarWriteOnly,
    calendarFullAccess,
    assistant,
    backgroundRefresh,
  ];

  static const List<String> _names = <String>[
    'calendar',
    'camera',
    'contacts',
    'location',
    'locationAlways',
    'locationWhenInUse',
    'mediaLibrary',
    'microphone',
    'phone',
    'photos',
    'photosAddOnly',
    'reminders',
    'sensors',
    'sms',
    'speech',
    'storage',
    'ignoreBatteryOptimizations',
    'notification',
    'accessMediaLocation',
    'activityRecognition',
    'unknown',
    'bluetooth',
    'manageExternalStorage',
    'systemAlertWindow',
    'requestInstallPackages',
    'appTrackingTransparency',
    'accessNotificationPolicy',
    'bluetoothScan',
    'bluetoothAdvertise',
    'bluetoothConnect',
    'nearbyWifiDevices',
    'videos',
    'audio',
    'scheduleExactAlarm',
    'sensorsAlways',
    'criticalAlerts',
    'calendarWriteOnly',
    'calendarFullAccess',
    'assistant',
    'backgroundRefresh',
  ];

  @override
  String toString() => 'Permission.${_names[value]}';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Permission && other.value == value);

  @override
  int get hashCode => value.hashCode;
}

/// A [Permission] that also exposes a system-level service status, e.g.
/// "is location services on" for [Permission.location] or
/// "is Bluetooth radio on" for [Permission.bluetooth].
class PermissionWithService extends Permission {
  const PermissionWithService._(super.value) : super._();

  Future<ServiceStatus> get serviceStatus =>
      NativePermsPlatform.instance.checkServiceStatus(this);
}
